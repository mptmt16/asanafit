import SwiftData
import SwiftUI

struct AchievementsView: View {
    @Query private var sessions: [PracticeSession]
    @Query private var scans: [BodyScan]
    @Query private var balances: [BalanceCheck]
    @Query private var breathSessions: [BreathSession]

    private var achievements: [Achievement] {
        AchievementCatalog.evaluate(sessions: sessions, scans: scans,
                                    balances: balances, breaths: breathSessions)
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("\(achievements.filter(\.isUnlocked).count) of \(achievements.count) unlocked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(achievements) { achievement in
                        tile(achievement)
                    }
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tile(_ achievement: Achievement) -> some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.symbol)
                .font(.title)
                .foregroundStyle(achievement.isUnlocked ? achievement.color : Color.white.opacity(0.25))
                .frame(width: 58, height: 58)
                .background((achievement.isUnlocked ? achievement.color : Color.white).opacity(0.12),
                            in: Circle())
            Text(achievement.title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(achievement.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !achievement.isUnlocked {
                ProgressView(value: achievement.fraction)
                    .tint(achievement.color)
                Text("\(min(achievement.progress, achievement.target)) / \(achievement.target)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Label("Unlocked", systemImage: "checkmark.seal.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(achievement.color)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .top)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(achievement.isUnlocked ? 1 : 0.72)
    }
}
