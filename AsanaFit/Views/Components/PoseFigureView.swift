import SwiftUI

/// Draws a pose as a stick figure, built from the same numbers the alignment targets use.
/// There is no stock footage anywhere in the app: if the demo looks wrong, the targets are wrong.
struct PoseFigureView: View {
    let figure: FigurePose
    var color: Color = Theme.accent
    var lineWidth: CGFloat = 4
    /// Eases in and out of the shape from standing, so you can see how to get there.
    var animated = false
    var showJoints = false
    var margin: CGFloat = 0.06

    var body: some View {
        if animated {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                canvas(SkeletonBuilder.make(FigurePose.mountain.blended(to: figure, amount: ease(time))))
            }
        } else {
            canvas(SkeletonBuilder.make(figure))
        }
    }

    /// Three seconds settling into the shape, three holding it, one and a half coming out.
    private func ease(_ time: TimeInterval) -> Double {
        let cycle = time.truncatingRemainder(dividingBy: 9)
        switch cycle {
        case ..<3:
            let t = cycle / 3
            return t * t * (3 - 2 * t)
        case ..<7.5:
            return 1
        default:
            let t = (cycle - 7.5) / 1.5
            return 1 - t * t * (3 - 2 * t)
        }
    }

    private func canvas(_ skeleton: StickFigure) -> some View {
        Canvas { context, size in
            let side = min(size.width, size.height) * (1 - margin * 2)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            func place(_ point: CGPoint) -> CGPoint {
                CGPoint(x: origin.x + point.x * side, y: origin.y + (1 - point.y) * side)
            }

            for (a, b) in Joint.bones {
                guard let start = skeleton.point(a), let end = skeleton.point(b) else { continue }
                var path = Path()
                path.move(to: place(start))
                path.addLine(to: place(end))
                context.stroke(path, with: .color(color),
                               style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }

            // A head, because a stick figure without one reads as a spider.
            if let neck = skeleton.point(.neck), let nose = skeleton.point(.nose) {
                let centre = place(CGPoint(x: (neck.x + nose.x * 2) / 3, y: (neck.y + nose.y * 2) / 3))
                let radius = lineWidth * 1.7
                context.stroke(Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius,
                                                      width: radius * 2, height: radius * 2)),
                               with: .color(color), lineWidth: lineWidth * 0.8)
            }

            guard showJoints else { return }
            for joint in Joint.allCases where joint != .nose {
                guard let point = skeleton.point(joint) else { continue }
                let centre = place(point)
                let radius = lineWidth * 0.7
                context.fill(Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius,
                                                    width: radius * 2, height: radius * 2)),
                             with: .color(.white))
            }
        }
    }
}

/// The demo card shown on an asana's detail screen.
struct PoseDemoCard: View {
    let asana: Asana

    var body: some View {
        VStack(spacing: 10) {
            PoseFigureView(figure: asana.figure, color: asana.category.color,
                           lineWidth: 5, animated: true, showJoints: true)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .background(
                    RadialGradient(colors: [asana.category.color.opacity(0.16), .clear],
                                   center: .center, startRadius: 10, endRadius: 170)
                )
            Label(asana.facing.instruction, systemImage: asana.facing.symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}
