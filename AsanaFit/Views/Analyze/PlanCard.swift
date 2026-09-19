import SwiftUI

/// The practice the app has chosen for you, and the button that runs it.
struct PlanCard: View {
    let plan: PracticePlan
    var compact = false
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(compact ? "Your practice for today" : "Your practice plan")
                        .font(.headline)
                    Text(plan.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text(plan.estimatedDuration.clockString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ForEach(plan.items) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: item.area.symbol)
                            .font(.caption)
                            .foregroundStyle(item.area.color)
                        Text(item.area.title)
                            .font(.subheadline.weight(.semibold))
                        if item.isGoal {
                            Text("goal")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(item.area.color.opacity(0.22), in: Capsule())
                        }
                        Spacer(minLength: 0)
                        if let score = item.score {
                            Text("\(Int(score.rounded()))")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(Theme.color(forScore: score))
                        }
                    }
                    HStack(spacing: 10) {
                        ForEach(item.asanas) { asana in
                            HStack(spacing: 6) {
                                PoseFigureView(figure: asana.figure, color: item.area.color, lineWidth: 2)
                                    .frame(width: 26, height: 26)
                                Text(asana.name).font(.caption)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(Color.white.opacity(0.06), in: Capsule())
                        }
                        Spacer(minLength: 0)
                    }
                }
            }

            if let closing = plan.closing {
                Label("Finish with \(closing.name)", systemImage: "leaf")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onStart) {
                Label("Start practice", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .card()
    }
}
