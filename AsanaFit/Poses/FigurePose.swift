import CoreGraphics
import Foundation

/// A yoga shape described by where each limb points rather than by joint coordinates.
///
/// Every direction is absolute, in degrees clockwise from straight up, as the viewer sees it:
/// 0 points up, 90 to the right, 180 straight down, 270 to the left. Left limbs belong to the
/// figure's own left, which is the viewer's left too, because the camera preview is mirrored.
///
/// Describing poses this way keeps the library compact and means the demo figure is built from
/// the same numbers the alignment targets are written against.
struct FigurePose: Hashable {
    var spine: Double = 0
    var head: Double = 0
    var leftUpperArm: Double = 186
    var leftForearm: Double = 186
    var rightUpperArm: Double = 174
    var rightForearm: Double = 174
    var leftThigh: Double = 183
    var leftShin: Double = 181
    var rightThigh: Double = 177
    var rightShin: Double = 179

    /// Standing tall, arms by your side.
    static let mountain = FigurePose()

    /// The same pose performed on the other side of the body.
    var mirrored: FigurePose {
        FigurePose(
            spine: -spine, head: -head,
            leftUpperArm: -rightUpperArm, leftForearm: -rightForearm,
            rightUpperArm: -leftUpperArm, rightForearm: -leftForearm,
            leftThigh: -rightThigh, leftShin: -rightShin,
            rightThigh: -leftThigh, rightShin: -leftShin
        )
    }

    /// Blend between two shapes, for animating a demo in and out of the pose.
    func blended(to other: FigurePose, amount: Double) -> FigurePose {
        func mix(_ a: Double, _ b: Double) -> Double {
            // Go the short way round the circle so 350 -> 10 sweeps through 0, not backwards.
            var delta = (b - a).truncatingRemainder(dividingBy: 360)
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }
            return a + delta * amount
        }
        return FigurePose(
            spine: mix(spine, other.spine), head: mix(head, other.head),
            leftUpperArm: mix(leftUpperArm, other.leftUpperArm),
            leftForearm: mix(leftForearm, other.leftForearm),
            rightUpperArm: mix(rightUpperArm, other.rightUpperArm),
            rightForearm: mix(rightForearm, other.rightForearm),
            leftThigh: mix(leftThigh, other.leftThigh), leftShin: mix(leftShin, other.leftShin),
            rightThigh: mix(rightThigh, other.rightThigh), rightShin: mix(rightShin, other.rightShin)
        )
    }
}

/// A set of joint positions, normalised so the whole figure fits a unit square.
struct StickFigure {
    /// y points up, and the figure is centred on (0.5, 0.5) with its longest side spanning 1.
    var joints: [Joint: CGPoint]

    func point(_ joint: Joint) -> CGPoint? { joints[joint] }

    /// Places the figure inside a camera frame of the given aspect ratio (width / height),
    /// filling `fill` of the frame's height. Returns normalised frame coordinates, y up.
    func projected(aspect: Double, fill: Double = 0.82, centre: CGPoint = CGPoint(x: 0.5, y: 0.5)) -> [Joint: CGPoint] {
        joints.mapValues { point in
            CGPoint(
                x: centre.x + (point.x - 0.5) * CGFloat(fill / aspect),
                y: centre.y + (point.y - 0.5) * CGFloat(fill)
            )
        }
    }
}

/// Turns a `FigurePose` into joint positions with forward kinematics and average human proportions.
enum SkeletonBuilder {
    /// Segment lengths in torso units, where the torso (hips to neck) is 1.
    private enum Bone {
        static let spine = 1.0
        static let head = 0.42
        static let shoulderHalfWidth = 0.36
        static let hipHalfWidth = 0.21
        static let upperArm = 0.62
        static let forearm = 0.58
        static let thigh = 0.92
        static let shin = 0.88
    }

    private static func direction(_ degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(x: CGFloat(sin(radians)), y: CGFloat(cos(radians)))
    }

    private static func offset(_ from: CGPoint, _ degrees: Double, _ length: Double) -> CGPoint {
        let step = direction(degrees)
        return CGPoint(x: from.x + step.x * CGFloat(length), y: from.y + step.y * CGFloat(length))
    }

    /// `narrow` turns the figure side-on: seen from the side, shoulders and hips
    /// almost stack on top of each other rather than spreading across the frame.
    static func make(_ pose: FigurePose, narrow: Bool = false) -> StickFigure {
        let across = narrow ? 0.18 : 1.0
        let root = CGPoint.zero
        let neck = offset(root, pose.spine, Bone.spine)
        let nose = offset(neck, pose.head, Bone.head)

        // Shoulders and hips sit across the spine, so they swing with it.
        let sideways = direction(pose.spine + 90)
        func side(_ centre: CGPoint, _ halfWidth: Double, left: Bool) -> CGPoint {
            let reach = CGFloat(halfWidth * across) * (left ? -1 : 1)
            return CGPoint(x: centre.x + sideways.x * reach, y: centre.y + sideways.y * reach)
        }

        let leftShoulder = side(neck, Bone.shoulderHalfWidth, left: true)
        let rightShoulder = side(neck, Bone.shoulderHalfWidth, left: false)
        let leftHip = side(root, Bone.hipHalfWidth, left: true)
        let rightHip = side(root, Bone.hipHalfWidth, left: false)

        let leftElbow = offset(leftShoulder, pose.leftUpperArm, Bone.upperArm)
        let rightElbow = offset(rightShoulder, pose.rightUpperArm, Bone.upperArm)
        let leftKnee = offset(leftHip, pose.leftThigh, Bone.thigh)
        let rightKnee = offset(rightHip, pose.rightThigh, Bone.thigh)

        var joints: [Joint: CGPoint] = [
            .root: root, .neck: neck, .nose: nose,
            .leftShoulder: leftShoulder, .rightShoulder: rightShoulder,
            .leftHip: leftHip, .rightHip: rightHip,
            .leftElbow: leftElbow, .rightElbow: rightElbow,
            .leftKnee: leftKnee, .rightKnee: rightKnee,
            .leftWrist: offset(leftElbow, pose.leftForearm, Bone.forearm),
            .rightWrist: offset(rightElbow, pose.rightForearm, Bone.forearm),
            .leftAnkle: offset(leftKnee, pose.leftShin, Bone.shin),
            .rightAnkle: offset(rightKnee, pose.rightShin, Bone.shin),
        ]

        // Normalise into a unit square so every pose is drawn at a comparable size.
        let xs = joints.values.map(\.x)
        let ys = joints.values.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return StickFigure(joints: joints)
        }
        let span = max(maxX - minX, maxY - minY, 0.001)
        let centreX = (minX + maxX) / 2
        let centreY = (minY + maxY) / 2
        joints = joints.mapValues { point in
            CGPoint(x: 0.5 + (point.x - centreX) / span, y: 0.5 + (point.y - centreY) / span)
        }
        return StickFigure(joints: joints)
    }

    /// The pose as a sample, so the demo figure can be measured by exactly the same code
    /// that measures you. Also used for demo mode when there is no camera.
    static func sample(_ pose: FigurePose, aspect: Double = 9.0 / 16.0,
                       timestamp: TimeInterval = 0, jitter: Double = 0,
                       narrow: Bool = false) -> PoseSample {
        let projected = make(pose, narrow: narrow).projected(aspect: aspect)
        var joints: [Joint: JointPoint] = [:]
        for (joint, point) in projected {
            let seed = Double(joint.rawValue.count)
            let wobble = jitter == 0 ? CGPoint.zero : CGPoint(
                x: CGFloat(sin(timestamp * 2.3 + seed) * jitter),
                y: CGFloat(cos(timestamp * 1.9 + seed * 1.7) * jitter)
            )
            joints[joint] = JointPoint(
                position: CGPoint(x: point.x + wobble.x, y: point.y + wobble.y),
                confidence: 0.92
            )
        }
        return PoseSample(timestamp: timestamp, isTracked: true, joints: joints, aspect: aspect)
    }
}
