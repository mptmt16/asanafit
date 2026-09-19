import SwiftUI

struct RadarAxis: Identifiable, Hashable {
    let name: String
    /// 0...100.
    let value: Double
    /// The same axis from the previous scan, drawn faintly behind.
    var previous: Double?

    var id: String { name }
}

/// A four-spoke chart of the scan's pillars, with the last scan ghosted behind it.
struct RadarChart: View {
    let axes: [RadarAxis]
    var color: Color = Theme.accent

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = side / 2 - 26

            ZStack {
                Path { path in
                    for ring in [0.25, 0.5, 0.75, 1.0] {
                        addPolygon(to: &path, centre: centre, radius: radius * ring, count: axes.count)
                    }
                    for index in axes.indices {
                        path.move(to: centre)
                        path.addLine(to: point(index: index, fraction: 1, centre: centre, radius: radius))
                    }
                }
                .stroke(Color.white.opacity(0.12), lineWidth: 1)

                if axes.contains(where: { $0.previous != nil }) {
                    shape(using: { axes[$0].previous ?? axes[$0].value }, centre: centre, radius: radius)
                        .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }

                shape(using: { axes[$0].value }, centre: centre, radius: radius)
                    .fill(color.opacity(0.28))
                shape(using: { axes[$0].value }, centre: centre, radius: radius)
                    .stroke(color, lineWidth: 2)

                ForEach(axes.indices, id: \.self) { index in
                    VStack(spacing: 1) {
                        Text(axes[index].name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(axes[index].value.rounded()))")
                            .font(.caption.bold())
                            .monospacedDigit()
                    }
                    .position(point(index: index, fraction: 1.16, centre: centre, radius: radius))
                }
            }
        }
    }

    private func point(index: Int, fraction: Double, centre: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(max(1, axes.count))
        return CGPoint(x: centre.x + cos(angle) * radius * fraction,
                       y: centre.y + sin(angle) * radius * fraction)
    }

    private func addPolygon(to path: inout Path, centre: CGPoint, radius: CGFloat, count: Int) {
        guard count > 1 else { return }
        for index in 0..<count {
            let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(count)
            let corner = CGPoint(x: centre.x + cos(angle) * radius, y: centre.y + sin(angle) * radius)
            if index == 0 { path.move(to: corner) } else { path.addLine(to: corner) }
        }
        path.closeSubpath()
    }

    private func shape(using value: (Int) -> Double, centre: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for index in axes.indices {
            let fraction = min(1, max(0, value(index) / 100))
            let corner = point(index: index, fraction: fraction, centre: centre, radius: radius)
            if index == 0 { path.move(to: corner) } else { path.addLine(to: corner) }
        }
        path.closeSubpath()
        return path
    }
}
