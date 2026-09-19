import SwiftUI

/// A live readout of everything the app can measure. Useful for checking that the camera
/// reads your body the way you expect before you trust a target.
struct PoseLabView: View {
    @State private var tracker = BodyTracker()
    @State private var showSkeleton = true

    private var sample: PoseSample { tracker.sample }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                BodyCameraView(tracker: tracker, showSkeleton: showSkeleton)
                VStack {
                    HStack(spacing: 8) {
                        badge(tracker.framing.message,
                              colour: tracker.framing.isGood ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.warm)
                        badge(sample.isSideOn ? "Side-on" : (sample.isFacingCamera ? "Front-on" : "Turning"),
                              colour: Theme.accent)
                        badge("\(sample.reliableJointCount)/15 joints", colour: Theme.secondary)
                    }
                    .padding(.top, 10)
                    Spacer()
                }
            }
            .frame(height: 300)
            .clipped()

            List {
                Section("Joint angles") {
                    ForEach(BodyAngle.allCases, id: \.self) { angle in
                        row(name: angle.name, value: sample.angle(angle),
                            unit: "deg", explanation: angle.explanation)
                    }
                }
                Section("Alignment") {
                    ForEach(BodyMetric.allCases, id: \.self) { metric in
                        row(name: metric.name, value: sample.metric(metric),
                            unit: metric.unit, explanation: metric.explanation)
                    }
                }
                Section("Left and right") {
                    ForEach([BodyAngle.leftKnee, .leftElbow, .leftHip, .leftShoulder], id: \.self) { angle in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(angle.name.replacingOccurrences(of: "Left ", with: ""))
                                    .font(.subheadline)
                                Spacer()
                                if let balance = sample.balance(angle) {
                                    Text("\(Int((balance * 100).rounded()))% even")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(balance > 0.85
                                                         ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.warm)
                                }
                            }
                            SideBar(left: fraction(sample.angle(angle)),
                                    right: fraction(sample.angle(angle.mirrored)))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Pose Lab")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSkeleton.toggle()
                } label: {
                    Image(systemName: showSkeleton ? "figure.walk.motion" : "figure.walk")
                }
            }
        }
        .onAppear { tracker.start() }
        .onDisappear { tracker.stop() }
    }

    private func badge(_ text: String, colour: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(colour)
    }

    private func row(name: String, value: Double?, unit: String, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(name).font(.subheadline)
                Spacer()
                Text(display(value, unit: unit))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(value == nil ? .secondary : Theme.accent)
            }
            Text(explanation).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func display(_ value: Double?, unit: String) -> String {
        guard let value else { return "not seen" }
        return unit == "deg" ? "\(Int(value.rounded()))\u{00B0}" : String(format: "%.2f", value)
    }

    /// Angles run 0 to 180, so halving gives a 0...1 bar.
    private func fraction(_ value: Double?) -> Double {
        guard let value else { return 0 }
        return min(1, max(0, value / 180))
    }
}
