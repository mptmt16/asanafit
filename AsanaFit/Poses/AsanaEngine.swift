import CoreGraphics
import Foundation
import Observation

/// What one side of one asana earned.
struct AsanaResult: Identifiable {
    let id = UUID()
    let asana: Asana
    let side: Side
    let heldSeconds: TimeInterval
    let breaths: Int
    /// Mean alignment while holding, 0...1.
    let alignment: Double
    /// How still you were while holding, 0...1.
    let steadiness: Double
    /// Mean left-to-right balance, 0...1. Nil when the pose has no paired measurement.
    let balance: Double?
    let completed: Bool

    /// The 0...100 score saved to history.
    var score: Double {
        let held = min(1, Double(breaths) / Double(max(1, asana.holdBreaths)))
        return ((alignment * 0.55 + steadiness * 0.2 + held * 0.25) * 100).rounded()
    }
}

/// One alignment target, live, for the bars on the session screen.
struct AlignmentCheck: Identifiable, Equatable {
    let id: String
    let name: String
    /// Nil when the camera cannot see the joints involved.
    let value: Double?
    let unit: String
    let target: String
    let progress: Double
    let cue: String

    var isMet: Bool { progress >= 1 }
}

/// Turns a stream of body samples into framing -> settle -> hold -> done.
///
/// A hold pauses rather than resets when you wobble: five breaths in a shape you keep
/// finding your way back into is still five breaths of practice.
@Observable
final class AsanaEngine {
    enum Phase: Equatable {
        case framing, settling, holding, finished
    }

    enum Event {
        case framing(String)
        case ready(cue: String)
        case correction(String)
        case holdStarted
        case holdPaused(String)
        case breath(Int)
        case finished
    }

    /// How long you get to move into the shape once the camera can see you.
    static let setupSeconds: TimeInterval = 7
    /// Once a hold has started, alignment may dip this far before it pauses.
    static let holdTolerance = 0.78
    /// After this long out of the shape, the hold gives up and you settle in again.
    static let breakSeconds: TimeInterval = 5
    /// How often the coach may repeat a correction.
    static let cueInterval: TimeInterval = 4

    let asana: Asana
    let side: Side
    /// Above 1 is a gentler practice, below 1 a stricter one.
    let tolerance: Double
    let pacer: BreathPacer

    private(set) var phase: Phase = .framing
    private(set) var framing = Framing(problem: .noBody, coverage: 0)
    /// Mean of every alignment target, 0...1.
    private(set) var alignment: Double = 0
    private(set) var checks: [AlignmentCheck] = []
    /// The single most useful thing to fix right now.
    private(set) var cue: String
    private(set) var attention: Set<Joint> = []
    private(set) var countdown = Int(AsanaEngine.setupSeconds)
    private(set) var heldSeconds: TimeInterval = 0
    private(set) var breath = BreathPacer.State(phase: .inhale, phaseProgress: 0, completed: 0, breathProgress: 0)
    private(set) var isPaused = false
    private(set) var elapsed: TimeInterval = 0

    @ObservationIgnored var onEvent: ((Event) -> Void)?

    @ObservationIgnored private var startTime: TimeInterval?
    @ObservationIgnored private var phaseStart: TimeInterval = 0
    @ObservationIgnored private var goodFramingSince: TimeInterval?
    @ObservationIgnored private var brokenSince: TimeInterval?
    @ObservationIgnored private var lastCueAt: TimeInterval = 0
    @ObservationIgnored private var lastSpokenCue = ""
    @ObservationIgnored private var lastBreathAnnounced = 0
    @ObservationIgnored private var alignmentSum = 0.0
    @ObservationIgnored private var alignmentCount = 0
    @ObservationIgnored private var balanceSum = 0.0
    @ObservationIgnored private var balanceCount = 0
    @ObservationIgnored private var steadinessSum = 0.0
    @ObservationIgnored private var steadinessCount = 0
    @ObservationIgnored private var previous: PoseSample?

    init(asana: Asana, side: Side, tolerance: Double, breathSeconds: Double) {
        let staged = asana.forSide(side)
        self.asana = staged
        self.side = side
        self.tolerance = tolerance
        self.pacer = BreathPacer(breathSeconds: breathSeconds)
        self.cue = staged.steps.first ?? staged.summary
    }

    var breathsHeld: Int { min(asana.holdBreaths, breath.completed) }

    var holdProgress: Double {
        let total = pacer.seconds(forBreaths: asana.holdBreaths)
        return total > 0 ? min(1, heldSeconds / total) : 0
    }

    var result: AsanaResult {
        AsanaResult(
            asana: asana,
            side: side,
            heldSeconds: heldSeconds,
            breaths: breathsHeld,
            alignment: alignmentCount > 0 ? alignmentSum / Double(alignmentCount) : 0,
            steadiness: steadinessCount > 0 ? steadinessSum / Double(steadinessCount) : 0,
            balance: balanceCount > 0 ? balanceSum / Double(balanceCount) : nil,
            completed: phase == .finished
        )
    }

    // MARK: - Frames

    func handle(_ sample: PoseSample) {
        let now = sample.timestamp
        if startTime == nil {
            startTime = now
            phaseStart = now
            lastCueAt = now
        }
        elapsed = now - (startTime ?? now)
        framing = Framing.check(sample)
        measure(sample)

        switch phase {
        case .framing: updateFraming(now: now)
        case .settling: updateSettling(now: now)
        case .holding: updateHolding(sample, now: now)
        case .finished: break
        }
        previous = sample
    }

    /// Recomputes every alignment target from the latest frame.
    private func measure(_ sample: PoseSample) {
        var live: [AlignmentCheck] = []
        var total = 0.0
        var counted = 0
        var worst: Requirement?
        var worstProgress = 1.0

        for (index, requirement) in asana.requirements.enumerated() {
            let progress = requirement.progress(in: sample, tolerance: tolerance)
            live.append(AlignmentCheck(
                id: "\(index)-\(requirement.signal.name)",
                name: requirement.signal.name,
                value: requirement.signal.value(in: sample),
                unit: requirement.signal.unit,
                target: requirement.targetDescription,
                progress: progress ?? 0,
                cue: requirement.cue
            ))
            guard let progress else { continue }
            total += progress
            counted += 1
            if progress < worstProgress {
                worstProgress = progress
                worst = requirement
            }
            if let balance = requirement.signal.balance(in: sample), phase == .holding {
                balanceSum += balance
                balanceCount += 1
            }
        }

        checks = live
        alignment = counted > 0 ? total / Double(counted) : 0
        if let worst, worstProgress < 0.97 {
            cue = worst.cue
            attention = Set(worst.signal.joints)
        } else {
            cue = phase == .holding ? "Hold and breathe" : "That's the shape - hold it"
            attention = []
        }
    }

    // MARK: - Phases

    private func updateFraming(now: TimeInterval) {
        if framing.isGood {
            if goodFramingSince == nil { goodFramingSince = now }
            if now - (goodFramingSince ?? now) >= 0.8 {
                enter(.settling, at: now)
                onEvent?(.ready(cue: asana.steps.first ?? asana.summary))
            }
        } else {
            goodFramingSince = nil
            speakOccasionally(framing.message, now: now) { message in
                self.onEvent?(.framing(message))
            }
        }
    }

    private func updateSettling(now: TimeInterval) {
        let remaining = Self.setupSeconds - (now - phaseStart)
        countdown = max(0, Int(remaining.rounded(.up)))
        // Settle early if the shape is already there.
        if alignment >= 1 {
            beginHold(at: now)
            return
        }
        if remaining <= 0 {
            // Start the hold anyway: the coach keeps correcting while you hold.
            beginHold(at: now)
            return
        }
        speakOccasionally(cue, now: now) { message in
            self.onEvent?(.correction(message))
        }
    }

    private func updateHolding(_ sample: PoseSample, now: TimeInterval) {
        let holding = alignment >= Self.holdTolerance && framing.isGood
        if holding {
            brokenSince = nil
            if isPaused { isPaused = false }
            heldSeconds += max(0, min(0.25, now - (previous?.timestamp ?? now)))
            alignmentSum += min(1, alignment)
            alignmentCount += 1
            steadinessSum += steadiness(sample)
            steadinessCount += 1
        } else {
            if brokenSince == nil {
                brokenSince = now
                isPaused = true
                onEvent?(.holdPaused(cue))
            }
            if now - (brokenSince ?? now) > Self.breakSeconds {
                enter(.settling, at: now)
                isPaused = false
                return
            }
            speakOccasionally(cue, now: now) { message in
                self.onEvent?(.correction(message))
            }
        }

        breath = pacer.state(at: heldSeconds)
        if breath.completed > lastBreathAnnounced {
            lastBreathAnnounced = breath.completed
            onEvent?(.breath(min(breath.completed, asana.holdBreaths)))
        }
        if breath.completed >= asana.holdBreaths {
            enter(.finished, at: now)
            onEvent?(.finished)
        }
    }

    private func beginHold(at now: TimeInterval) {
        enter(.holding, at: now)
        // Picking the hold back up after a wobble should not replay every breath already counted.
        lastBreathAnnounced = pacer.state(at: heldSeconds).completed
        onEvent?(.holdStarted)
    }

    private func enter(_ newPhase: Phase, at now: TimeInterval) {
        phase = newPhase
        phaseStart = now
        if newPhase == .settling {
            countdown = Int(Self.setupSeconds)
            goodFramingSince = now
        }
    }

    /// Ends the pose early but keeps what was earned, e.g. when the user skips ahead.
    func finishEarly() {
        phase = .finished
    }

    // MARK: - Helpers

    /// How still the body is, from how far the joints moved since the last frame.
    private func steadiness(_ sample: PoseSample) -> Double {
        guard let previous else { return 1 }
        return PoseGeometry.steadiness(from: previous, to: sample)
    }

    /// Says something at most every few seconds, and never the same thing twice in a row too soon.
    private func speakOccasionally(_ message: String, now: TimeInterval, action: (String) -> Void) {
        let repeated = message == lastSpokenCue
        guard now - lastCueAt >= (repeated ? Self.cueInterval * 1.8 : Self.cueInterval) else { return }
        lastCueAt = now
        lastSpokenCue = message
        action(message)
    }
}
