import SwiftData
import SwiftUI

/// The level map: what you have unlocked and what is coming next.
struct JourneyView: View {
    @Query private var sessions: [PracticeSession]
    @Query private var scans: [BodyScan]
    @Query private var balances: [BalanceCheck]
    @Query private var breathSessions: [BreathSession]

    private var totalXP: Int {
        Progression.totalXP(sessions: sessions, scans: scans, balances: balances, breaths: breathSessions)
    }

    private var progress: Progression.LevelProgress { Progression.progress(forXP: totalXP) }

    /// Every level that unlocks something, plus a few beyond where you are now.
    private var levels: [Int] {
        let highest = max(
            (Progression.unlockLevels.values.max() ?? 10),
            (Progression.flowUnlockLevels.values.max() ?? 10)
        )
        return Array(1...max(highest, progress.level + 2))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                ForEach(levels, id: \.self) { level in
                    row(level)
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Journey")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Level \(progress.level)").font(.largeTitle.bold())
            Text(Progression.rank(forLevel: progress.level))
                .foregroundStyle(Theme.accent)
            ProgressView(value: progress.fraction)
                .tint(Theme.accent)
            Text("\(progress.xp) XP  -  \(progress.remaining) to level \(progress.level + 1)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private func row(_ level: Int) -> some View {
        let asanas = Progression.unlocks(atLevel: level)
        let flows = Progression.flowUnlocks(atLevel: level)
        let reached = progress.level >= level
        let isCurrent = progress.level == level

        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(reached ? Theme.accent : Color.white.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text("\(level)")
                    .font(.subheadline.bold())
                    .foregroundStyle(reached ? .black : .secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(Progression.rank(forLevel: level))
                        .font(.subheadline.weight(.semibold))
                    if isCurrent {
                        Text("you are here")
                            .font(.caption2.bold())
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.25), in: Capsule())
                    }
                }
                Text("\(Progression.xpRequired(forLevel: level)) XP")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                if asanas.isEmpty, flows.isEmpty {
                    Text("Keep practising.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(asanas) { asana in
                        Label(asana.name, systemImage: reached ? "checkmark.circle.fill" : "lock")
                            .font(.caption)
                            .foregroundStyle(reached ? asana.category.color : .secondary)
                    }
                    ForEach(flows) { flow in
                        Label("\(flow.name) flow", systemImage: reached ? "checkmark.circle.fill" : "lock")
                            .font(.caption)
                            .foregroundStyle(reached ? flow.color : .secondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .card()
        .opacity(reached ? 1 : 0.72)
    }
}
