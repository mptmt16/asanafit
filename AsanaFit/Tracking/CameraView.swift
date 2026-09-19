import AVFoundation
import SwiftUI
import UIKit

/// Maps normalised pose coordinates onto the part of a view the camera frame actually fills.
///
/// The preview is shown whole rather than cropped, so you can see exactly what the app can see,
/// and the skeleton lines up with your body to the pixel.
struct PoseProjection {
    /// Where the camera image sits inside the view.
    var content: CGRect
    /// The preview is mirrored like a bathroom mirror, so drawing has to be mirrored too.
    var mirrored: Bool = true

    init(viewSize: CGSize, aspect: Double, mirrored: Bool = true) {
        let viewAspect = viewSize.height > 0 ? viewSize.width / viewSize.height : 1
        let size: CGSize = aspect < viewAspect
            ? CGSize(width: viewSize.height * aspect, height: viewSize.height)
            : CGSize(width: viewSize.width, height: viewSize.width / aspect)
        content = CGRect(
            x: (viewSize.width - size.width) / 2,
            y: (viewSize.height - size.height) / 2,
            width: size.width, height: size.height
        )
        self.mirrored = mirrored
    }

    /// Normalised frame coordinates (y up) to view coordinates (y down).
    func point(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: content.minX + (mirrored ? 1 - point.x : point.x) * content.width,
            y: content.minY + (1 - point.y) * content.height
        )
    }
}

/// The live camera with the tracked skeleton drawn on top, or an animated stand-in in demo mode.
struct BodyCameraView: View {
    let tracker: BodyTracker
    var showSkeleton = true
    /// A shape to draw faintly behind you as a target to match.
    var ghost: StickFigure?
    /// Joints the current cue is about, drawn in the warning colour.
    var attention: Set<Joint> = []

    var body: some View {
        ZStack {
            if tracker.isSimulated {
                LinearGradient(colors: [Color(white: 0.13), Color(white: 0.03)],
                               startPoint: .top, endPoint: .bottom)
            } else {
                CameraPreview(session: tracker.session)
            }
            if showSkeleton {
                SkeletonOverlay(sample: tracker.sample, ghost: ghost, attention: attention)
            }
            if tracker.isSimulated {
                Label("Demo mode - no camera, the body is simulated", systemImage: "wand.and.stars")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 108)
            }
        }
    }
}

/// Draws the skeleton, plus an optional target shape behind it.
struct SkeletonOverlay: View {
    let sample: PoseSample
    var ghost: StickFigure?
    var attention: Set<Joint> = []

    var body: some View {
        GeometryReader { proxy in
            let projection = PoseProjection(viewSize: proxy.size, aspect: sample.aspect)
            Canvas { context, _ in
                if let ghost {
                    draw(ghost.projected(aspect: sample.aspect, fill: 0.86),
                         in: &context, projection: projection,
                         colour: Color.white.opacity(0.22), width: 10, dots: false)
                }
                var points: [Joint: CGPoint] = [:]
                for joint in Joint.allCases {
                    if let point = sample.point(joint) { points[joint] = point }
                }
                draw(points, in: &context, projection: projection,
                     colour: Theme.accent, width: 5, dots: true, attention: attention)
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ points: [Joint: CGPoint], in context: inout GraphicsContext,
                      projection: PoseProjection, colour: Color, width: CGFloat,
                      dots: Bool, attention: Set<Joint> = []) {
        for (a, b) in Joint.bones {
            guard let start = points[a], let end = points[b] else { continue }
            var path = Path()
            path.move(to: projection.point(start))
            path.addLine(to: projection.point(end))
            let flagged = attention.contains(a) && attention.contains(b)
            context.stroke(path, with: .color(flagged ? Theme.warm : colour),
                           style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
        guard dots else { return }
        for (joint, point) in points {
            let centre = projection.point(point)
            let radius = width * (attention.contains(joint) ? 1.15 : 0.85)
            let box = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: box),
                         with: .color(attention.contains(joint) ? Theme.warm : .white))
        }
    }
}

/// A plain camera preview layer, shown whole so nothing is cropped out of view.
private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        guard let connection = view.previewLayer.connection else { return }
        if connection.isVideoOrientationSupported, connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
        }
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer {
            // Safe: layerClass above guarantees the type.
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
