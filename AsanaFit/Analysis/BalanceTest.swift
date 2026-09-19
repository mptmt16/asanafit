import Foundation
import Observation

/// What the one-leg balance test measured.
struct BalanceTestResult {
    let leftSeconds: Double
    let rightSeconds: Double
    /// 0...1 stillness while the foot was up.
    let leftSteadiness: Double
    let rightSteadiness: Double

    var bestSeconds: Double { max(leftSeconds, rightSeconds) }
    var weakerSide: Side { leftSeconds <= rightSeconds ? .left : .right }

    /// 0...1 agreement between the two sides.
    var balance: Double {
        let strongest = max(leftSeconds, rightSeconds)
        guard strongest > 0.5 else { return 1 }
        return 1 - min(1, abs(leftSeconds - rightSeconds) / strongest)
    }

    var score: Double {
        let time = min(1, ((leftSeconds + rightSeconds) / 2) / BalanceTestEngine.targetSeconds)
        let steady = (leftSteadiness + rightSteadiness) / 2
        return ((time * 0.55 + steady * 0.25 + balance * 0.2) * 100).rounded()
    }
}

enum BalanceScoring {
    static func advice(_ result: BalanceTestResult) -> [String] {
        var tips: [String] = []
        let average = (result.leftSeconds + result.rightSeconds) / 2
        if average < 12 {
            tips.append("Practise beside a wall and touch it only when you need to. Balance returns quickly with daily practice.")
        } else if average < 30 {
            tips.append("You are past the wobbly stage. Tree pose held for five slow breaths on each side is the next step.")
        } else {
            tips.append("Strong steady balance. Try warrior III and half moon, where the balance has to travel.")
        }
        if result.balance < 0.75 {
            tips.append("Your \(result.weakerSide == .left ? "left" : "right") leg gives out sooner. Practise that side twice for every once on the other.")
        }
        if min(result.leftSteadiness, result.rightSteadiness) < 0.6 {
            tips.append("You hold on, but with a lot of correction. Fix your eyes on one unmoving point to quieten the sway.")
        }
        tips.append("Balance is trainable at any age, and it is one of the strongest predictors of staying mobile later on.")
        return tips
    }
}

/// Runs the two-sided balance test: stand on one foot for as long as you can, then swap.
@Observable
final class BalanceTestEngine {
    enum Phase: Equatable {
        case framing, ready(Side), holding(Side), swapping, finished
    }

    /// The hold that counts as a full score.
    static let targetSeconds: Double = 45
    static let readySeconds: Double = 5
    /// How long the foot has to be down before the side is over.
    static let groundedGrace: Double = 1.2

    private(set) var phase: Phase = .framing
    private(set) var countdown = Int(BalanceTestEngine.readySeconds)
    private(set) var heldSeconds: Double = 0
    private(set) var isFootUp = false
    private(set) var framing = Framing(problem: .noBody, coverage: 0)
    private(set) var result: BalanceTestResult?

    @ObservationIgnored var onEvent: ((String) -> Void)?

    @ObservationIgnored private var phaseStart: TimeInterval?
    @ObservationIgnored private var previous: PoseSample?
    @ObservationIgnored private var groundedSince: TimeInterval?
    @ObservationIgnored private var sides: [Side: Double] = [:]
    @ObservationIgnored private var steadiness: [Side: [Double]] = [:]

    var currentSide: Side {
        switch phase {
        case .ready(let side), .holding(let side):
            return side
        default:
            return .none
        }
    }

    func handle(_ sample: PoseSample) {
        let now = sample.timestamp
        if phaseStart == nil { phaseStart = now }
        framing = Framing.check(sample)
        isFootUp = (sample.metric(.ankleLift) ?? 0) >= 0.25

        switch phase {
        case .framing:
            guard framing.isGood, sample.isFacingCamera else { return }
            enter(.ready(.left), at: now)
            onEvent?("Stand on your left foot when the countdown ends.")
        case .ready(let side):
            let remaining = Self.readySeconds - (now - (phaseStart ?? now))
            countdown = max(0, Int(remaining.rounded(.up)))
            guard remaining <= 0 else { return }
            heldSeconds = 0
            groundedSince = nil
            enter(.holding(side), at: now)
            onEvent?("Go. Hold as long as you can.")
        case .holding(let side):
            updateHolding(sample, side: side, now: now)
        case .swapping:
            let remaining = Self.readySeconds - (now - (phaseStart ?? now))
            countdown = max(0, Int(remaining.rounded(.up)))
            guard remaining <= 0 else { return }
            heldSeconds = 0
            groundedSince = nil
            enter(.holding(.right), at: now)
            onEvent?("Go. Hold as long as you can.")
        case .finished:
            break
        }
        previous = sample
    }

    private func updateHolding(_ sample: PoseSample, side: Side, now: TimeInterval) {
        if isFootUp, framing.isGood {
            groundedSince = nil
            heldSeconds += max(0, min(0.25, now - (previous?.timestamp ?? now)))
            if let previous {
                steadiness[side, default: []].append(PoseGeometry.steadiness(from: previous, to: sample))
            }
            if heldSeconds >= Self.targetSeconds {
                finishSide(side, at: now)
            }
            return
        }
        // A foot that touches down briefly is a wobble, not the end.
        if groundedSince == nil { groundedSince = now }
        if now - (groundedSince ?? now) >= Self.groundedGrace {
            finishSide(side, at: now)
        }
    }

    private func finishSide(_ side: Side, at now: TimeInterval) {
        sides[side] = heldSeconds
        if side == .left {
            enter(.swapping, at: now)
            countdown = Int(Self.readySeconds)
            onEvent?("Good. Now the other side: stand on your right foot.")
        } else {
            phase = .finished
            result = BalanceTestResult(
                leftSeconds: (sides[.left] ?? 0).rounded(),
                rightSeconds: (sides[.right] ?? 0).rounded(),
                leftSteadiness: average(steadiness[.left]),
                rightSteadiness: average(steadiness[.right])
            )
            onEvent?("Test complete.")
        }
    }

    private func average(_ values: [Double]?) -> Double {
        guard let values, !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func enter(_ newPhase: Phase, at now: TimeInterval) {
        phase = newPhase
        phaseStart = now
    }

    /// Stops the test where it is, keeping whatever both sides managed.
    func stop() {
        if case .holding(let side) = phase {
            sides[side] = heldSeconds
        }
        guard sides[.left] != nil || sides[.right] != nil else {
            phase = .finished
            return
        }
        result = BalanceTestResult(
            leftSeconds: (sides[.left] ?? 0).rounded(),
            rightSeconds: (sides[.right] ?? 0).rounded(),
            leftSteadiness: average(steadiness[.left]),
            rightSteadiness: average(steadiness[.right])
        )
        phase = .finished
    }
}
