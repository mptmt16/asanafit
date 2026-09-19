import SwiftUI

/// The headline card: overall score, level, and the four pillars on a radar.
struct BodyScoreCard: View {
    let scan: BodyScan
    var previous: BodyScan?

    private var level: BodyLevel { scan.level }

    private var axes: [RadarAxis] {
        let now = scan.breakdown.pillars
        let before = previous?.breakdown.pillars
        return now.enumerated().map { index, pillar in
            RadarAxis(name: pillar.name, value: pillar.value,
                      previous: before.map { $0[index].value })
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                ScoreGauge(score: scan.overallScore, title: "", size: 104, lineWidth: 11)
                VStack(alignment: .leading, spacing: 6) {
                    Text(level.title)
                        .font(.title3.bold())
                        .foregroundStyle(Theme.color(forScore: scan.overallScore))
                    if let remaining = level.pointsToNext(from: scan.overallScore) {
                        Text("\(Int(remaining.rounded())) points to the next level")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Top level reached.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let previous {
                        let delta = scan.overallScore - previous.overallScore
                        Label("\(delta >= 0 ? "+" : "")\(Int(delta.rounded())) since last scan",
                              systemImage: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.bold())
                            .foregroundStyle(delta >= 0 ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.warm)
                    }
                    Text("Focus next: \(scan.breakdown.focus)")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
                Spacer(minLength: 0)
            }

            RadarChart(axes: axes)
                .frame(height: 230)

            Text("Posture 25%, flexibility 30%, balance 25%, mobility 20%.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}

/// One measured number with its meaning, and left and right when it has two sides.
struct MeasurementCard: View {
    let measurement: ScanMeasurement

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(measurement.title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(display)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.color(forScore: measurement.score))
            }
            ProgressView(value: measurement.score / 100)
                .tint(Theme.color(forScore: measurement.score))
            if let left = measurement.left, let right = measurement.right {
                SideBar(left: normalise(left), right: normalise(right))
                HStack {
                    Text("Left \(format(left))").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    if let balance = measurement.balance {
                        Text("\(Int((balance * 100).rounded()))% even")
                            .font(.caption2.bold())
                            .foregroundStyle(balance > 0.85 ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.warm)
                    }
                    Spacer()
                    Text("Right \(format(right))").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text(measurement.insight)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var display: String {
        format(measurement.value)
    }

    private func format(_ value: Double) -> String {
        switch measurement.unit {
        case "deg": return "\(Int(value.rounded()))\u{00B0}"
        case "s": return "\(Int(value.rounded()))s"
        default: return String(format: "%.2f", value)
        }
    }

    private func normalise(_ value: Double) -> Double {
        let peak = max(abs(measurement.left ?? 0), abs(measurement.right ?? 0), 0.001)
        return abs(value) / peak
    }
}

/// One body area with its score, insight and the poses that train it.
struct AreaCard: View {
    let area: AreaScore
    var isGoal = false
    var playerLevel: Int = 99

    private var asanas: [Asana] {
        area.area.asanaIDs
            .compactMap { AsanaLibrary.asana(id: $0) }
            .filter { Progression.isUnlocked($0, playerLevel: playerLevel) }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: area.area.symbol)
                    .font(.headline)
                    .foregroundStyle(area.area.color)
                    .frame(width: 36, height: 36)
                    .background(area.area.color.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(area.area.title).font(.subheadline.weight(.semibold))
                        if isGoal {
                            Text("goal")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(area.area.color.opacity(0.22), in: Capsule())
                        }
                    }
                    Text(area.area.blurb).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text("\(Int(area.score.rounded()))")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(Theme.color(forScore: area.score))
            }
            ProgressView(value: area.score / 100)
                .tint(Theme.color(forScore: area.score))
            Text(area.insight).font(.caption)
            if !asanas.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(asanas) { asana in
                            NavigationLink {
                                AsanaDetailView(asana: asana)
                            } label: {
                                HStack(spacing: 6) {
                                    PoseFigureView(figure: asana.figure, color: area.area.color, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    Text(asana.name).font(.caption)
                                }
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .background(Color.white.opacity(0.06), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .card()
    }
}
