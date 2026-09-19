import CoreGraphics
import Foundation
import Vision

/// The 15 body joints AsanaFit works with, a subset of Vision's body pose points.
///
/// Left and right are the *person's* own left and right. Vision infers them from anatomy,
/// so they stay correct even though a front camera sees you facing it.
enum Joint: String, CaseIterable, Codable, Hashable {
    case nose, neck, root
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle

    var visionName: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .nose: .nose
        case .neck: .neck
        case .root: .root
        case .leftShoulder: .leftShoulder
        case .rightShoulder: .rightShoulder
        case .leftElbow: .leftElbow
        case .rightElbow: .rightElbow
        case .leftWrist: .leftWrist
        case .rightWrist: .rightWrist
        case .leftHip: .leftHip
        case .rightHip: .rightHip
        case .leftKnee: .leftKnee
        case .rightKnee: .rightKnee
        case .leftAnkle: .leftAnkle
        case .rightAnkle: .rightAnkle
        }
    }

    /// The same joint on the other side of the body.
    var mirrored: Joint {
        switch self {
        case .leftShoulder: .rightShoulder
        case .rightShoulder: .leftShoulder
        case .leftElbow: .rightElbow
        case .rightElbow: .leftElbow
        case .leftWrist: .rightWrist
        case .rightWrist: .leftWrist
        case .leftHip: .rightHip
        case .rightHip: .leftHip
        case .leftKnee: .rightKnee
        case .rightKnee: .leftKnee
        case .leftAnkle: .rightAnkle
        case .rightAnkle: .leftAnkle
        case .nose, .neck, .root: self
        }
    }

    var name: String {
        switch self {
        case .nose: "Head"
        case .neck: "Neck"
        case .root: "Hips"
        case .leftShoulder: "Shoulder L"
        case .rightShoulder: "Shoulder R"
        case .leftElbow: "Elbow L"
        case .rightElbow: "Elbow R"
        case .leftWrist: "Wrist L"
        case .rightWrist: "Wrist R"
        case .leftHip: "Hip L"
        case .rightHip: "Hip R"
        case .leftKnee: "Knee L"
        case .rightKnee: "Knee R"
        case .leftAnkle: "Ankle L"
        case .rightAnkle: "Ankle R"
        }
    }

    /// The bones drawn between joints, and used to sanity-check that a limb is visible.
    static let bones: [(Joint, Joint)] = [
        (.nose, .neck),
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.neck, .root),
        (.root, .leftHip), (.root, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]
}

/// One detected joint: where it is and how sure Vision is about it.
struct JointPoint: Codable, Hashable {
    /// Normalised position in the upright camera frame: x to the right, **y upwards**,
    /// origin at the bottom-left, which is Vision's own convention.
    var position: CGPoint
    var confidence: Double

    var isReliable: Bool { confidence >= PoseSample.confidenceThreshold }
}

/// One processed camera frame: where every joint is right now.
struct PoseSample {
    /// Below this, a joint is treated as not seen at all.
    static let confidenceThreshold = 0.3

    var timestamp: TimeInterval
    var isTracked: Bool
    var joints: [Joint: JointPoint]
    /// Frame width ÷ height. Needed because normalised coordinates are squashed by the
    /// frame's aspect ratio, which would skew every angle if it were ignored.
    var aspect: Double

    static let empty = PoseSample(timestamp: 0, isTracked: false, joints: [:], aspect: 9.0 / 16.0)

    /// Position for drawing, in normalised frame coordinates (y up). Nil when not seen.
    func point(_ joint: Joint) -> CGPoint? {
        guard let found = joints[joint], found.isReliable else { return nil }
        return found.position
    }

    /// Position for measuring, in units of frame height so both axes have the same scale.
    func measured(_ joint: Joint) -> CGPoint? {
        guard let point = point(joint) else { return nil }
        return CGPoint(x: point.x * CGFloat(aspect), y: point.y)
    }

    func confidence(_ joint: Joint) -> Double {
        joints[joint]?.confidence ?? 0
    }

    func has(_ joints: Joint...) -> Bool {
        joints.allSatisfy { point($0) != nil }
    }

    /// Mid-point between two joints, in measuring space.
    func midpoint(_ a: Joint, _ b: Joint) -> CGPoint? {
        guard let first = measured(a), let second = measured(b) else { return nil }
        return CGPoint(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
    }

    /// Neck-to-hips distance, the scale every length in the app is expressed in.
    /// Using the torso rather than pixels makes measurements independent of how far away you stand.
    var torsoLength: Double? {
        guard let neck = measured(.neck), let root = measured(.root) else { return nil }
        let length = PoseGeometry.distance(neck, root)
        return length > 0.02 ? length : nil
    }

    /// Box containing every reliable joint, in measuring space.
    var boundingBox: CGRect? {
        let points = Joint.allCases.compactMap { measured($0) }
        guard points.count >= 6 else { return nil }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    var reliableJointCount: Int {
        Joint.allCases.filter { point($0) != nil }.count
    }
}
