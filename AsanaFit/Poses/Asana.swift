import SwiftUI

enum AsanaCategory: String, CaseIterable, Identifiable, Codable {
    case standing, balance, strength, backbend, hips, restore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standing: "Standing & Legs"
        case .balance: "Balance"
        case .strength: "Core & Strength"
        case .backbend: "Backbends"
        case .hips: "Hips & Forward Folds"
        case .restore: "Rest & Breath"
        }
    }

    var symbol: String {
        switch self {
        case .standing: "figure.stand"
        case .balance: "figure.yoga"
        case .strength: "figure.core.training"
        case .backbend: "figure.flexibility"
        case .hips: "figure.cooldown"
        case .restore: "leaf"
        }
    }

    var color: Color {
        switch self {
        case .standing: Color(red: 0.62, green: 0.56, blue: 1.00)
        case .balance: Color(red: 0.45, green: 0.78, blue: 1.00)
        case .strength: Color(red: 1.00, green: 0.55, blue: 0.48)
        case .backbend: Color(red: 1.00, green: 0.72, blue: 0.38)
        case .hips: Color(red: 0.35, green: 0.85, blue: 0.72)
        case .restore: Color(red: 0.60, green: 0.85, blue: 0.50)
        }
    }
}

/// Where the phone should stand for a pose to be readable.
///
/// A single camera cannot see depth, so a twist or a fold has to be judged from the side
/// while a wide stance has to be judged from the front. Each asana says which it needs.
enum CameraFacing: String, Codable {
    case front, side

    var instruction: String {
        switch self {
        case .front: "Face the camera"
        case .side: "Turn side-on to the camera"
        }
    }

    var symbol: String {
        switch self {
        case .front: "person.fill"
        case .side: "person.fill.turn.right"
        }
    }
}

enum AsanaLevel: String, CaseIterable, Hashable, Codable {
    case beginner, intermediate, advanced

    var title: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .beginner: Color(red: 0.45, green: 0.85, blue: 0.55)
        case .intermediate: Theme.secondary
        case .advanced: Color(red: 1.00, green: 0.50, blue: 0.45)
        }
    }

    var bars: Int {
        switch self {
        case .beginner: 1
        case .intermediate: 2
        case .advanced: 3
        }
    }
}

/// Which side of the body a pose is being practised on.
enum Side: String, Hashable, Codable {
    case none, left, right

    var label: String {
        switch self {
        case .none: ""
        case .left: "Left side"
        case .right: "Right side"
        }
    }

    var shortLabel: String {
        switch self {
        case .none: ""
        case .left: "L"
        case .right: "R"
        }
    }
}

/// A measurable quantity read from a body sample.
enum BodySignal: Hashable {
    case angle(BodyAngle)
    /// Both sides of an angle at once: the value is their mean, and balance is measurable.
    case pair(BodyAngle)
    case metric(BodyMetric)

    var name: String {
        switch self {
        case .angle(let angle): angle.name
        case .pair(let angle): angle.name.replacingOccurrences(of: "Left ", with: "Both ")
        case .metric(let metric): metric.name
        }
    }

    var unit: String {
        switch self {
        case .angle, .pair: "deg"
        case .metric(let metric): metric.unit
        }
    }

    /// How far off target still earns partial credit.
    var window: Double {
        switch self {
        case .angle(let angle): angle.window
        case .pair(let angle): angle.window
        case .metric(let metric): metric.window
        }
    }

    var mirrored: BodySignal {
        switch self {
        case .angle(let angle): .angle(angle.mirrored)
        case .pair(let angle): .pair(angle)
        case .metric(let metric): .metric(metric.mirrored)
        }
    }

    /// The joints to highlight when this signal is the one that is off.
    var joints: [Joint] {
        switch self {
        case .angle(let angle):
            let (a, vertex, b) = angle.joints
            return [a, vertex, b]
        case .pair(let angle):
            let (a, vertex, b) = angle.joints
            let (c, vertex2, d) = angle.mirrored.joints
            return [a, vertex, b, c, vertex2, d]
        case .metric(let metric):
            return metric.joints
        }
    }

    func value(in sample: PoseSample) -> Double? {
        switch self {
        case .angle(let angle):
            return sample.angle(angle)
        case .pair(let angle):
            guard let left = sample.angle(angle.isLeft ? angle : angle.mirrored),
                  let right = sample.angle(angle.isLeft ? angle.mirrored : angle) else { return nil }
            return (left + right) / 2
        case .metric(let metric):
            return sample.metric(metric)
        }
    }

    /// 0...1 left-to-right balance, or nil when this signal has no two sides.
    func balance(in sample: PoseSample) -> Double? {
        guard case .pair(let angle) = self else { return nil }
        return sample.balance(angle)
    }
}

extension BodyMetric {
    /// Joints to highlight when this measurement is out.
    var joints: [Joint] {
        switch self {
        case .spineTilt: [.root, .neck]
        case .headTilt: [.neck, .nose]
        case .shoulderTilt: [.leftShoulder, .rightShoulder]
        case .hipTilt: [.leftHip, .rightHip]
        case .leftThighTilt: [.leftHip, .leftKnee]
        case .rightThighTilt: [.rightHip, .rightKnee]
        case .leftShinTilt: [.leftKnee, .leftAnkle]
        case .rightShinTilt: [.rightKnee, .rightAnkle]
        case .leftArmTilt: [.leftShoulder, .leftElbow, .leftWrist]
        case .rightArmTilt: [.rightShoulder, .rightElbow, .rightWrist]
        case .stanceWidth: [.leftAnkle, .rightAnkle]
        case .kneeSpread: [.leftKnee, .rightKnee]
        case .armSpread: [.leftWrist, .rightWrist]
        case .handHeight: [.leftWrist, .rightWrist]
        case .hipHeight: [.root, .leftAnkle, .rightAnkle]
        case .ankleLift: [.leftAnkle, .rightAnkle]
        case .reach: [.leftWrist, .rightWrist, .leftAnkle, .rightAnkle]
        }
    }
}

/// One thing that has to be true for a pose to count, with the cue to give when it isn't.
struct Requirement: Hashable {
    enum Goal: Hashable {
        case atLeast(Double)
        case atMost(Double)
        case near(Double, Double)
    }

    var signal: BodySignal
    var goal: Goal
    /// What the coach says when this is the thing most out of place.
    var cue: String

    static func atLeast(_ signal: BodySignal, _ value: Double, _ cue: String) -> Requirement {
        Requirement(signal: signal, goal: .atLeast(value), cue: cue)
    }

    static func atMost(_ signal: BodySignal, _ value: Double, _ cue: String) -> Requirement {
        Requirement(signal: signal, goal: .atMost(value), cue: cue)
    }

    static func near(_ signal: BodySignal, _ value: Double, _ tolerance: Double, _ cue: String) -> Requirement {
        Requirement(signal: signal, goal: .near(value, tolerance), cue: cue)
    }

    var mirrored: Requirement {
        Requirement(signal: signal.mirrored, goal: goal, cue: cue.sidesSwapped)
    }

    /// A short description of the target, e.g. "at least 160 deg".
    var targetDescription: String {
        let unit = signal.unit == "deg" ? " deg" : ""
        switch goal {
        case .atLeast(let value): return "at least \(value.trimmedString)\(unit)"
        case .atMost(let value): return "at most \(value.trimmedString)\(unit)"
        case .near(let value, let tolerance):
            return "\(value.trimmedString)\(unit) give or take \(tolerance.trimmedString)"
        }
    }

    /// How close you are, where 1 means the requirement is met.
    /// `tolerance` above 1 is a gentler practice, below 1 a stricter one.
    /// Returns nil when the camera cannot see the joints involved.
    func progress(in sample: PoseSample, tolerance: Double) -> Double? {
        guard let value = signal.value(in: sample) else { return nil }
        let window = signal.window
        let slack = window * 0.3 * (tolerance - 1)
        let miss: Double
        switch goal {
        case .atLeast(let target): miss = max(0, (target - slack) - value)
        case .atMost(let target): miss = max(0, value - (target + slack))
        case .near(let target, let band): miss = max(0, abs(value - target) - (band + slack))
        }
        return max(0, 1 - miss / window)
    }
}

/// A yoga posture the app can see and coach.
struct Asana: Identifiable, Hashable {
    let id: String
    let name: String
    let sanskrit: String
    let category: AsanaCategory
    let symbol: String
    let summary: String
    let benefits: String
    let steps: [String]
    let facing: CameraFacing
    var requirements: [Requirement]
    /// The shape, used for the demo figure, the on-camera guide and demo mode.
    var figure: FigurePose
    var holdBreaths: Int
    /// Two-sided poses are practised once on each side.
    var twoSided: Bool = false
    var level: AsanaLevel = .beginner
    /// Shown on the detail screen when a posture needs care.
    var caution: String?
    /// Which side this copy is set up for. The library always holds the left-side version.
    var side: Side = .none

    /// The same asana set up for the other side of the body.
    var mirrored: Asana {
        var copy = self
        copy.requirements = requirements.map(\.mirrored)
        copy.figure = figure.mirrored
        copy.side = side == .left ? .right : .left
        return copy
    }

    /// The copy to practise for a given side.
    func forSide(_ side: Side) -> Asana {
        guard twoSided else { return self }
        var copy = self
        copy.side = .left
        return side == .right ? copy.mirrored : copy
    }

    var displayName: String {
        side == .none ? name : "\(name) (\(side.shortLabel))"
    }

    /// How long one side of the pose takes, including settling in.
    func duration(breathSeconds: Double) -> TimeInterval {
        AsanaEngine.setupSeconds + Double(holdBreaths) * breathSeconds + 3
    }

    var estimatedDuration: TimeInterval {
        let one = duration(breathSeconds: BreathPacer.defaultBreathSeconds)
        return twoSided ? one * 2 : one
    }

    var stickFigure: StickFigure { SkeletonBuilder.make(figure) }
}

extension String {
    /// Swaps the words "left" and "right", so a pose written for one side reads correctly on the other.
    var sidesSwapped: String {
        var text = replacingOccurrences(of: "\\bleft\\b", with: "\u{1}", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\bLeft\\b", with: "\u{2}", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\bright\\b", with: "left", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\bRight\\b", with: "Left", options: .regularExpression)
        text = text.replacingOccurrences(of: "\u{1}", with: "right")
        return text.replacingOccurrences(of: "\u{2}", with: "Right")
    }
}

extension Double {
    /// "90" rather than "90.0", but still "0.5" when the decimal matters.
    var trimmedString: String {
        self == rounded() ? String(Int(self)) : String(format: "%.1f", self)
    }
}

extension TimeInterval {
    /// "1:05" style.
    var clockString: String {
        let total = Int(self.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
