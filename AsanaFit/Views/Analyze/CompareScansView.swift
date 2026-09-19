import SwiftData
import SwiftUI

/// Two scans side by side, with the change in every score.
struct CompareScansView: View {
    @Query(sort: \BodyScan.date, order: .reverse) private var scans: [BodyScan]
    @State private var earlierIndex = 1
    @State private var laterIndex = 0

    private var earlier: BodyScan? { scans.indices.contains(earlierIndex) ? scans[earlierIndex] : nil }
    private var later: BodyScan? { scans.indices.contains(laterIndex) ? scans[laterIndex] : nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                pickers
                if let earlier, let later {
                    overall(earlier: earlier, later: later)
                    pillars(earlier: earlier, later: later)
                    areas(earlier: earlier, later: later)
                    measurements(earlier: earlier, later: later)
                } else {
                    Text("Take two scans to compare them.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Before & after")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pickers: some View {
        VStack(spacing: 10) {
            picker(title: "Before", selection: $earlierIndex)
            picker(title: "After", selection: $laterIndex)
        }
        .card()
    }

    private func picker(title: String, selection: Binding<Int>) -> some View {
        HStack {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer()
            Picker(title, selection: selection) {
                ForEach(scans.indices, id: \.self) { index in
                    Text(scans[index].date.formatted(date: .abbreviated, time: .shortened)).tag(index)
                }
            }
            .labelsHidden()
            .tint(Theme.accent)
        }
    }

    private func overall(earlier: BodyScan, later: BodyScan) -> some View {
        HStack(spacing: 18) {
            ScoreGauge(score: earlier.overallScore, title: "Before", size: 86)
            Image(systemName: "arrow.right").foregroundStyle(.secondary)
            ScoreGauge(score: later.overallScore, title: "After", size: 86)
            Spacer(minLength: 0)
            delta(later.overallScore - earlier.overallScore, big: true)
        }
        .card()
    }

    private struct Change: Identifiable {
        let name: String
        let before: Double
        let after: Double
        var id: String { name }
    }

    private func pillars(earlier: BodyScan, later: BodyScan) -> some View {
        let before = earlier.breakdown.pillars
        let after = later.breakdown.pillars
        var changes = before.indices.map {
            Change(name: before[$0].name, before: before[$0].value, after: after[$0].value)
        }
        changes.append(Change(name: "Left and right",
                              before: earlier.symmetryScore, after: later.symmetryScore))
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Pillars", subtitle: nil)
            ForEach(changes) { change in
                row(name: change.name, before: change.before, after: change.after)
            }
        }
        .card()
    }

    private func areas(earlier: BodyScan, later: BodyScan) -> some View {
        let before = Dictionary(uniqueKeysWithValues: earlier.areas.map { ($0.area, $0.score) })
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Areas", subtitle: nil)
            ForEach(later.areas) { area in
                if let start = before[area.area] {
                    row(name: area.area.title, before: start, after: area.score)
                }
            }
        }
        .card()
    }

    private func measurements(earlier: BodyScan, later: BodyScan) -> some View {
        let before = Dictionary(uniqueKeysWithValues: earlier.measurements.map { ($0.id, $0) })
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Measurements", subtitle: "The raw numbers, not the scores.")
            ForEach(later.measurements) { measurement in
                if let start = before[measurement.id] {
                    HStack {
                        Text(measurement.title).font(.subheadline)
                        Spacer()
                        Text(format(start, unit: measurement.unit))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                        Text(format(measurement, unit: measurement.unit))
                            .font(.subheadline.monospacedDigit())
                    }
                }
            }
        }
        .card()
    }

    private func format(_ measurement: ScanMeasurement, unit: String) -> String {
        switch unit {
        case "deg": return "\(Int(measurement.value.rounded()))\u{00B0}"
        case "s": return "\(Int(measurement.value.rounded()))s"
        default: return String(format: "%.2f", measurement.value)
        }
    }

    private func row(name: String, before: Double, after: Double) -> some View {
        HStack {
            Text(name).font(.subheadline)
            Spacer()
            Text("\(Int(before.rounded()))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
            Text("\(Int(after.rounded()))")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.color(forScore: after))
            delta(after - before)
        }
    }

    private func delta(_ value: Double, big: Bool = false) -> some View {
        let rounded = Int(value.rounded())
        return Text("\(rounded >= 0 ? "+" : "")\(rounded)")
            .font(big ? .title3.bold().monospacedDigit() : .caption.bold().monospacedDigit())
            .foregroundStyle(rounded >= 0 ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.warm)
            .frame(width: big ? 54 : 38, alignment: .trailing)
    }
}
