import CoreGraphics
import Foundation

/// An angle at one joint, in degrees. 180 degrees means the limb is straight.
enum BodyAngle: String, CaseIterable, Codable, Hashable {
    case leftKnee, rightKnee
    case leftElbow, rightElbow
    case leftHip, rightHip
    case leftShoulder, rightShoulder

    /// The three joints that make the angle, with the vertex in the middle.
    var joints: (Joint, Joint, Joint) {
        switch self {
        case .leftKnee: (.leftHip, .leftKnee, .leftAnkle)
        case .rightKnee: (.rightHip, .rightKnee, .rightAnkle)
        case .leftElbow: (.leftShoulder, .leftElbow, .leftWrist)
        case .rightElbow: (.rightShoulder, .rightElbow, .rightWrist)
        case .leftHip: (.leftShoulder, .leftHip, .leftKnee)
        case .rightHip: (.rightShoulder, .rightHip, .rightKnee)
        case .leftShoulder: (.leftHip, .leftShoulder, .leftElbow)
        case .rightShoulder: (.rightHip, .rightShoulder, .rightElbow)
        }
    }

    var mirrored: BodyAngle {
        switch self {
        case .leftKnee: .rightKnee
        case .rightKnee: .leftKnee
        case .leftElbow: .rightElbow
        case .rightElbow: .leftElbow
        case .leftHip: .rightHip
        case .rightHip: .leftHip
        case .leftShoulder: .rightShoulder
        case .rightShoulder: .leftShoulder
        }
    }

    var isLeft: Bool {
        switch self {
        case .leftKnee, .leftElbow, .leftHip, .leftShoulder: true
        default: false
        }
    }

    var name: String {
        switch self {
        case .leftKnee: "Left knee"
        case .rightKnee: "Right knee"
        case .leftElbow: "Left elbow"
        case .rightElbow: "Right elbow"
        case .leftHip: "Left hip"
        case .rightHip: "Right hip"
        case .leftShoulder: "Left arm lift"
        case .rightShoulder: "Right arm lift"
        }
    }

    /// What the number means, shown in Pose Lab.
    var explanation: String {
        switch self {
        case .leftKnee, .rightKnee: "180 is a straight leg, 90 a right-angled bend."
        case .leftElbow, .rightElbow: "180 is a straight arm."
        case .leftHip, .rightHip: "180 is standing tall, smaller means folded at the hip."
        case .leftShoulder, .rightShoulder: "0 is an arm by your side, 90 straight out, 180 overhead."
        }
    }

    /// How many degrees off target still counts as partly right, for the alignment percentage.
    var window: Double { 45 }
}

/// A whole-body alignment measurement. Angles are in degrees. Lengths are in torsos
/// (neck to hips), so they don't change when you move closer to the camera.
enum BodyMetric: String, CaseIterable, Codable, Hashable {
    case spineTilt, headTilt, shoulderTilt, hipTilt
    case leftThighTilt, rightThighTilt
    case leftShinTilt, rightShinTilt
    case leftArmTilt, rightArmTilt
    case stanceWidth, kneeSpread, armSpread
    case handHeight, hipHeight, ankleLift, reach

    var mirrored: BodyMetric {
        switch self {
        case .leftThighTilt: .rightThighTilt
        case .rightThighTilt: .leftThighTilt
        case .leftShinTilt: .rightShinTilt
        case .rightShinTilt: .leftShinTilt
        case .leftArmTilt: .rightArmTilt
        case .rightArmTilt: .leftArmTilt
        default: self
        }
    }

    var name: String {
        switch self {
        case .spineTilt: "Spine lean"
        case .headTilt: "Head lean"
        case .shoulderTilt: "Shoulder level"
        case .hipTilt: "Hip level"
        case .leftThighTilt: "Left thigh"
        case .rightThighTilt: "Right thigh"
        case .leftShinTilt: "Left shin"
        case .rightShinTilt: "Right shin"
        case .leftArmTilt: "Left arm level"
        case .rightArmTilt: "Right arm level"
        case .stanceWidth: "Stance width"
        case .kneeSpread: "Knee spread"
        case .armSpread: "Hand spread"
        case .handHeight: "Hand height"
        case .hipHeight: "Hip height"
        case .ankleLift: "Foot lift"
        case .reach: "Hand-to-foot reach"
        }
    }

    var isAngle: Bool {
        switch self {
        case .stanceWidth, .kneeSpread, .armSpread, .handHeight, .hipHeight, .ankleLift, .reach: false
        default: true
        }
    }

    var unit: String { isAngle ? "deg" : "torso" }

    var explanation: String {
        switch self {
        case .spineTilt: "How far your spine leans from straight up. 0 is upright, 90 is horizontal."
        case .headTilt: "How far your head leans from straight up."
        case .shoulderTilt: "How far your shoulder line is off level. 0 is level."
        case .hipTilt: "How far your hip line is off level."
        case .leftThighTilt, .rightThighTilt: "Thigh against the floor. 0 is parallel to the floor, 90 is standing."
        case .leftShinTilt, .rightShinTilt: "Shin against vertical. 0 is a shin stacked over the ankle."
        case .leftArmTilt, .rightArmTilt: "Arm against the horizon. 0 is an arm reaching straight out."
        case .stanceWidth: "Distance between your feet, in torso lengths."
        case .kneeSpread: "Distance between your knees, in torso lengths."
        case .armSpread: "Distance between your hands, in torso lengths."
        case .handHeight: "Hand height above your hips. 0 is hip height, 1 shoulder height, 2 overhead."
        case .hipHeight: "Hip height above your feet. About 1.1 standing tall, less as you sink."
        case .ankleLift: "How much higher one foot is than the other."
        case .reach: "Sideways distance from your hands to your feet."
        }
    }

    /// How far off target still counts as partly right.
    var window: Double { isAngle ? 40 : 0.6 }
}

enum PoseGeometry {
    static let toDegrees = 180 / Double.pi

    /// Straight-line distance between two measuring-space points.
    static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = Double(a.x - b.x)
        let dy = Double(a.y - b.y)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Interior angle at `vertex`, 0...180 degrees.
    static func angle(at vertex: CGPoint, from a: CGPoint, to b: CGPoint) -> Double? {
        let ux = Double(a.x - vertex.x)
        let uy = Double(a.y - vertex.y)
        let vx = Double(b.x - vertex.x)
        let vy = Double(b.y - vertex.y)
        let lengths = (ux * ux + uy * uy).squareRoot() * (vx * vx + vy * vy).squareRoot()
        guard lengths > 1e-6 else { return nil }
        let cosine = min(1, max(-1, (ux * vx + uy * vy) / lengths))
        return acos(cosine) * toDegrees
    }

    /// How far the segment a to b leans away from straight up, 0...180 degrees.
    static func fromVertical(_ a: CGPoint, _ b: CGPoint) -> Double? {
        let dx = Double(b.x - a.x)
        let dy = Double(b.y - a.y)
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 1e-6 else { return nil }
        return acos(min(1, max(-1, dy / length))) * toDegrees
    }

    /// How far the segment a to b leans away from the horizon, 0...90 degrees.
    static func fromHorizontal(_ a: CGPoint, _ b: CGPoint) -> Double? {
        let dx = Double(b.x - a.x)
        let dy = Double(b.y - a.y)
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 1e-6 else { return nil }
        return asin(min(1, max(-1, abs(dy) / length))) * toDegrees
    }

    /// Mean joint movement between two frames, in torso lengths per second.
    /// Small numbers mean a still body, which is what a held pose should be.
    static func drift(from previous: PoseSample, to sample: PoseSample) -> Double? {
        guard let torso = sample.torsoLength else { return nil }
        let gap = sample.timestamp - previous.timestamp
        guard gap > 0.001, gap < 0.5 else { return nil }
        var total = 0.0
        var counted = 0
        for joint in Joint.allCases {
            guard let now = sample.measured(joint), let before = previous.measured(joint) else { continue }
            total += distance(now, before) / torso
            counted += 1
        }
        guard counted > 0 else { return nil }
        return (total / Double(counted)) / gap
    }

    /// 0...1 stillness. A torso length of drift per second counts as a full wobble.
    static func steadiness(from previous: PoseSample, to sample: PoseSample) -> Double {
        guard let drift = drift(from: previous, to: sample) else { return 1 }
        return max(0, 1 - drift / 0.55)
    }
}

extension PoseSample {
    func angle(_ angle: BodyAngle) -> Double? {
        let (a, vertex, b) = angle.joints
        guard let first = measured(a), let centre = measured(vertex), let second = measured(b) else { return nil }
        return PoseGeometry.angle(at: centre, from: first, to: second)
    }

    func metric(_ metric: BodyMetric) -> Double? {
        switch metric {
        case .spineTilt:
            guard let root = measured(.root), let neck = measured(.neck) else { return nil }
            return PoseGeometry.fromVertical(root, neck)
        case .headTilt:
            guard let neck = measured(.neck), let nose = measured(.nose) else { return nil }
            return PoseGeometry.fromVertical(neck, nose)
        case .shoulderTilt:
            guard let left = measured(.leftShoulder), let right = measured(.rightShoulder) else { return nil }
            return PoseGeometry.fromHorizontal(left, right)
        case .hipTilt:
            guard let left = measured(.leftHip), let right = measured(.rightHip) else { return nil }
            return PoseGeometry.fromHorizontal(left, right)
        case .leftThighTilt: return tilt(from: .leftHip, to: .leftKnee, vertical: false)
        case .rightThighTilt: return tilt(from: .rightHip, to: .rightKnee, vertical: false)
        case .leftShinTilt: return tilt(from: .leftKnee, to: .leftAnkle, vertical: true)
        case .rightShinTilt: return tilt(from: .rightKnee, to: .rightAnkle, vertical: true)
        case .leftArmTilt: return tilt(from: .leftShoulder, to: .leftWrist, vertical: false)
        case .rightArmTilt: return tilt(from: .rightShoulder, to: .rightWrist, vertical: false)
        case .stanceWidth: return horizontalGap(.leftAnkle, .rightAnkle)
        case .kneeSpread: return horizontalGap(.leftKnee, .rightKnee)
        case .armSpread:
            guard let left = measured(.leftWrist), let right = measured(.rightWrist),
                  let torso = torsoLength else { return nil }
            return PoseGeometry.distance(left, right) / torso
        case .handHeight:
            guard let hands = midpoint(.leftWrist, .rightWrist), let root = measured(.root),
                  let torso = torsoLength else { return nil }
            return Double(hands.y - root.y) / torso
        case .hipHeight:
            guard let feet = midpoint(.leftAnkle, .rightAnkle), let root = measured(.root),
                  let torso = torsoLength else { return nil }
            return Double(root.y - feet.y) / torso
        case .ankleLift:
            guard let left = measured(.leftAnkle), let right = measured(.rightAnkle),
                  let torso = torsoLength else { return nil }
            return Double(abs(left.y - right.y)) / torso
        case .reach:
            guard let hands = midpoint(.leftWrist, .rightWrist), let feet = midpoint(.leftAnkle, .rightAnkle),
                  let torso = torsoLength else { return nil }
            return Double(abs(hands.x - feet.x)) / torso
        }
    }

    private func tilt(from a: Joint, to b: Joint, vertical: Bool) -> Double? {
        guard let first = measured(a), let second = measured(b) else { return nil }
        return vertical ? PoseGeometry.fromVertical(first, second) : PoseGeometry.fromHorizontal(first, second)
    }

    private func horizontalGap(_ a: Joint, _ b: Joint) -> Double? {
        guard let first = measured(a), let second = measured(b), let torso = torsoLength else { return nil }
        return Double(abs(first.x - second.x)) / torso
    }

    /// Shoulder width in torso lengths. Around 0.7 when you face the camera and well under 0.3
    /// when you turn side-on, which is how the app can tell which way you are standing.
    var shoulderSpan: Double? {
        guard let left = measured(.leftShoulder), let right = measured(.rightShoulder),
              let torso = torsoLength else { return nil }
        return Double(abs(left.x - right.x)) / torso
    }

    /// Whether you are standing side-on. Unknown shoulders count as side-on being false.
    var isSideOn: Bool { (shoulderSpan ?? 1) < 0.40 }

    var isFacingCamera: Bool { (shoulderSpan ?? 0) > 0.46 }

    /// 0...1 balance between the left and right version of an angle, or nil when either is missing.
    func balance(_ angle: BodyAngle) -> Double? {
        let leftAngle = angle.isLeft ? angle : angle.mirrored
        guard let left = self.angle(leftAngle), let right = self.angle(leftAngle.mirrored) else { return nil }
        return 1 - min(1, abs(left - right) / 60)
    }
}

/// Whether the camera can actually see enough of you to coach a pose.
struct Framing {
    enum Problem {
        case noBody, partial, tooClose, tooFar, offCentre

        var message: String {
            switch self {
            case .noBody: "Step into view"
            case .partial: "Get your whole body in frame"
            case .tooClose: "Step back from the camera"
            case .tooFar: "Step closer to the camera"
            case .offCentre: "Move to the middle of the frame"
            }
        }
    }

    var problem: Problem?
    /// How much of the frame your body fills, along its longest side.
    var coverage: Double

    var isGood: Bool { problem == nil }
    var message: String { problem?.message ?? "Nicely framed" }

    /// The joints every pose needs before coaching can start.
    static let required: [Joint] = [
        .neck, .root, .leftShoulder, .rightShoulder, .leftHip, .rightHip,
        .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
    ]

    static func check(_ sample: PoseSample) -> Framing {
        guard sample.isTracked, sample.reliableJointCount >= 6, let box = sample.boundingBox else {
            return Framing(problem: .noBody, coverage: 0)
        }
        let coverage = Double(max(box.height, box.width))
        if Framing.required.contains(where: { sample.point($0) == nil }) {
            return Framing(problem: .partial, coverage: coverage)
        }
        // Touching an edge means a limb is probably already cut off.
        if box.minY < 0.03 || box.maxY > 0.97
            || Double(box.minX) < 0.02 * sample.aspect || Double(box.maxX) > 0.98 * sample.aspect {
            return Framing(problem: .tooClose, coverage: coverage)
        }
        if coverage > 0.94 { return Framing(problem: .tooClose, coverage: coverage) }
        if coverage < 0.42 { return Framing(problem: .tooFar, coverage: coverage) }
        let centre = Double(box.midX) / sample.aspect
        if centre < 0.22 || centre > 0.78 { return Framing(problem: .offCentre, coverage: coverage) }
        return Framing(problem: nil, coverage: coverage)
    }
}
