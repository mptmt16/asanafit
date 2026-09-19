import SwiftUI

/// Level, XP and today's progress toward the daily goal.
struct LevelCard: View {
    let progress: Progression.LevelProgress
    let xpToday: Int

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: Double(xpToday) / Double(Progression.dailyGoalXP),
                                 lineWidth: 9, color: Theme.warm)
                    VStack(spacing: 0) {
                        Text("\(xpToday)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("XP today").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 84, height: 84)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Level \(progress.level)").font(.title3.bold())
                        Text(Progression.rank(forLevel: progress.level))
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                    }
                    ProgressView(value: progress.fraction).tint(Theme.accent)
                    Text("\(progress.remaining) XP to level \(progress.level + 1)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if xpToday >= Progression.dailyGoalXP {
                Label("Daily goal reached", systemImage: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.warm)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .card()
    }
}

/// The three daily quests.
struct QuestsCard: View {
    let quests: [Quest]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Today's quests", subtitle: nil)
                Spacer()
                Text("+\(quests.reduce(0) { $0 + $1.xp }) XP")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.warm)
            }
            ForEach(quests) { quest in
                HStack(spacing: 12) {
                    Image(systemName: quest.isComplete ? "checkmark.circle.fill" : quest.symbol)
                        .font(.headline)
                        .foregroundStyle(quest.isComplete ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.accent)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quest.title)
                            .font(.subheadline.weight(.semibold))
                            .strikethrough(quest.isComplete, color: .secondary)
                        ProgressView(value: quest.fraction)
                            .tint(quest.isComplete ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.accent)
                        Text("\(min(quest.progress, quest.target)) / \(quest.target)  -  \(quest.detail)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .card()
    }
}

/// A short prompt to do something other than asanas.
struct QuickActionTile: View {
    let title: String
    let detail: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// The tip of the day.
struct TipCard: View {
    let tip: DailyTip

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.symbol)
                .font(.title3)
                .foregroundStyle(Theme.secondary)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tip of the day")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(tip.text).font(.subheadline)
            }
        }
        .card()
    }
}
