import Foundation
import Observation

/// Runs the guided body scan: nine short steps, each one measuring something the
/// practice plan can act on. Nothing is recorded but the numbers.
@Observable
final class BodyScanEngine {
    enum Phase: Equatable {
        case framing, prepare, recording, finished
    }

    enum Event {
        case framing(String)
        case step(title: String, instruction: String)
        case recording
        case stepDone
        case finished
    }

    /// How long you get to move into position before a step records.
    static let prepareSeconds: Double = 5

    let steps = ScanStep.all

    private(set) var phase: Phase = .framing
    private(set) var stepIndex = 0
    private(set) var countdown = Int(BodyScanEngine.prepareSeconds)
    /// 0...1 through the current recording step.
    private(set) var stepProgress: Double = 0
    private(set) var framing = Framing(problem: .noBody, coverage: 0)
    private(set) var facingHint: String?
    private(set) var outcome: ScanOutcome?

    @ObservationIgnored var onEvent: ((Event) -> Void)?

    @ObservationIgnored private var phaseStart: TimeInterval?
    @ObservationIgnored private var goodSince: TimeInterval?
    @ObservationIgnored private var previous: PoseSample?
    @ObservationIgnored private var readings: [String: [Double]] = [:]
    @ObservationIgnored private var spokenHint: String?

    var step: ScanStep { steps[min(stepIndex, steps.count - 1)] }

    var overallProgress: Double {
        let done = Double(stepIndex)
        let within = phase == .recording ? stepProgress : 0
        return min(1, (done + within) / Double(steps.count))
    }

    // MARK: - Frames

    func handle(_ sample: PoseSample) {
        let now = sample.timestamp
        framing = Framing.check(sample)

        switch phase {
        case .framing: updateFraming(sample, now: now)
        case .prepare: updatePrepare(now: now)
        case .recording: updateRecording(sample, now: now)
        case .finished: break
        }
        previous = sample
    }

    private func updateFraming(_ sample: PoseSample, now: TimeInterval) {
        let wantsSide = step.facing == .side
        let turnedRight = wantsSide ? sample.isSideOn : sample.isFacingCamera
        facingHint = turnedRight ? nil : step.facing.instruction

        guard framing.isGood, turnedRight else {
            goodSince = nil
            let message = framing.isGood ? step.facing.instruction : framing.message
            if message != spokenHint {
                spokenHint = message
                onEvent?(.framing(message))
            }
            return
        }
        spokenHint = nil
        if goodSince == nil { goodSince = now }
        guard now - (goodSince ?? now) >= 0.6 else { return }
        enter(.prepare, at: now)
        onEvent?(.step(title: step.title, instruction: step.instruction))
    }

    private func updatePrepare(now: TimeInterval) {
        let remaining = Self.prepareSeconds - (now - (phaseStart ?? now))
        countdown = max(0, Int(remaining.rounded(.up)))
        guard remaining <= 0 else { return }
        enter(.recording, at: now)
        onEvent?(.recording)
    }

    private func updateRecording(_ sample: PoseSample, now: TimeInterval) {
        let elapsed = now - (phaseStart ?? now)
        stepProgress = min(1, elapsed / step.seconds)
        record(sample)

        guard elapsed >= step.seconds else { return }
        onEvent?(.stepDone)
        if stepIndex + 1 < steps.count {
            stepIndex += 1
            stepProgress = 0
            goodSince = nil
            spokenHint = nil
            enter(.framing, at: now)
        } else {
            outcome = BodyScoring.outcome(from: readings)
            enter(.finished, at: now)
            onEvent?(.finished)
        }
    }

    private func enter(_ newPhase: Phase, at now: TimeInterval) {
        phase = newPhase
        phaseStart = now
        if newPhase == .prepare { countdown = Int(Self.prepareSeconds) }
    }

    /// Ends the scan where it is. Only produces a result if every step finished.
    func abandon() {
        phase = .finished
    }

    // MARK: - Recording

    private func add(_ key: String, _ value: Double?) {
        guard let value, value.isFinite else { return }
        readings[key, default: []].append(value)
    }

    private func record(_ sample: PoseSample) {
        let prefix = step.capture.rawValue
        switch step.capture {
        case .posture:
            add("\(prefix).shoulderTilt", sample.metric(.shoulderTilt))
            add("\(prefix).hipTilt", sample.metric(.hipTilt))
            add("\(prefix).spineTilt", sample.metric(.spineTilt))
            add("\(prefix).headTilt", sample.metric(.headTilt))
            add("\(prefix).kneeLeft", sample.angle(.leftKnee))
            add("\(prefix).kneeRight", sample.angle(.rightKnee))
        case .sidePosture:
            add("\(prefix).spineTilt", sample.metric(.spineTilt))
            add("\(prefix).headTilt", sample.metric(.headTilt))
            add("\(prefix).hip", meanAngle(sample, .leftHip, .rightHip))
        case .reach:
            add("\(prefix).left", sample.angle(.leftShoulder))
            add("\(prefix).right", sample.angle(.rightShoulder))
            add("\(prefix).handHeight", sample.metric(.handHeight))
        case .fold:
            add("\(prefix).hip", meanAngle(sample, .leftHip, .rightHip))
            add("\(prefix).knee", meanAngle(sample, .leftKnee, .rightKnee))
            add("\(prefix).handHeight", sample.metric(.handHeight))
        case .squat:
            add("\(prefix).hipHeight", sample.metric(.hipHeight))
            add("\(prefix).knee", meanAngle(sample, .leftKnee, .rightKnee))
        case .balanceLeft, .balanceRight:
            add("\(prefix).lift", sample.metric(.ankleLift))
            add("\(prefix).spineTilt", sample.metric(.spineTilt))
            if let previous {
                add("\(prefix).steadiness", PoseGeometry.steadiness(from: previous, to: sample))
            }
        case .bendLeft, .bendRight:
            add("\(prefix).tilt", sample.metric(.spineTilt))
        }
    }

    /// The mean of a left and right angle, or whichever one the camera could see.
    private func meanAngle(_ sample: PoseSample, _ a: BodyAngle, _ b: BodyAngle) -> Double? {
        let values = [sample.angle(a), sample.angle(b)].compactMap { $0 }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
