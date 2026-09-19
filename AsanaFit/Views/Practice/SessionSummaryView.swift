import SwiftData
import SwiftUI

/// What you earned, shown the moment a practice ends.
struct SessionSummaryView: View {
    let results: [AsanaResult]
    var title = "Practice"
    var startedAt: Date = .now
    var onDone: () -> Void

    @Query private var sessions: [PracticeSession]
    @Query private var scans: [BodyScan]
    @Query private var balances: [BalanceCheck]
    @Query private var breathSessions: [BreathSession]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                totals
                if levelAfter > levelBefore {
                    levelUpCard
                }
                if !newAchievements.isEmpty {
                    achievementsCard
                }
                poseList
                Button("Done", action: onDone)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
            }
            .padding()
            .padding(.bottom, 30)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Numbers

    private var xpEarned: Int {
        results.reduce(0) { total, result in
            total + Progression.xp(breaths: result.breaths,
                                   target: result.asana.holdBreaths,
                                   alignment: result.alignment)
        }
    }

    private var totalXP: Int {
        Progression.totalXP(sessions: sessions, scans: scans, balances: balances, breaths: breathSessions)
    }

    private var levelAfter: Int { Progression.level(forXP: totalXP) }
    private var levelBefore: Int { Progression.level(forXP: max(0, totalXP - xpEarned)) }

    private var totalBreaths: Int { results.reduce(0) { $0 + $1.breaths } }
    private var totalSeconds: Double { results.reduce(0) { $0 + $1.heldSeconds } }
    private var meanAlignment: Double {
        guard !results.isEmpty else { return 0 }
        return results.reduce(0) { $0 + $1.alignment } / Double(results.count)
    }

    private var newAchievements: [Achievement] {
        let after = AchievementCatalog.evaluate(sessions: sessions, scans: scans,
                                                balances: balances, breaths: breathSessions)
        let earlier = sessions.filter { $0.date < startedAt }
        let before = AchievementCatalog.evaluate(sessions: earlier, scans: scans,
                                                 balances: balances, breaths: breathSessions)
        return AchievementCatalog.newlyUnlocked(before: before, after: after)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "hands.and.sparkles.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
            Text("Namaste").font(.largeTitle.bold())
            Text(title).font(.headline).foregroundStyle(Theme.accent)
            Text(results.isEmpty ? "Nothing held this time." : "\(results.count) poses held.")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 30)
    }

    private var totals: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(title: "Breaths", value: "\(totalBreaths)", symbol: "wind")
                StatTile(title: "On the mat", value: totalSeconds.clockString,
                         symbol: "clock", color: Theme.secondary)
                StatTile(title: "XP", value: "+\(xpEarned)", symbol: "bolt.fill", color: Theme.warm)
            }
            HStack {
                Text("Mean alignment")
                    .font(.subheadline)
                Spacer()
                Text("\(Int((meanAlignment * 100).rounded()))%")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Theme.color(forScore: meanAlignment * 100))
            }
            .card()
        }
    }

    private var levelUpCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(Theme.warm)
            Text("Level \(levelAfter)").font(.title2.bold())
            Text(Progression.rank(forLevel: levelAfter))
                .foregroundStyle(.secondary)
            let unlocked = ((levelBefore + 1)...levelAfter).flatMap { Progression.unlocks(atLevel: $0) }
            if !unlocked.isEmpty {
                Text("Unlocked: \(unlocked.map(\.name).joined(separator: ", "))")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.accent)
            }
            let flows = ((levelBefore + 1)...levelAfter).flatMap { Progression.flowUnlocks(atLevel: $0) }
            if !flows.isEmpty {
                Text("New flow: \(flows.map(\.name).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(Theme.secondary)
            }
        }
        .card()
    }

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "New badge", subtitle: nil)
            ForEach(newAchievements) { achievement in
                HStack(spacing: 12) {
                    Image(systemName: achievement.symbol)
                        .font(.title3)
                        .foregroundStyle(achievement.color)
                        .frame(width: 38, height: 38)
                        .background(achievement.color.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title).font(.subheadline.bold())
                        Text(achievement.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .card()
    }

    private var poseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "This practice", subtitle: nil)
            ForEach(results) { result in
                HStack(spacing: 12) {
                    PoseFigureView(figure: result.asana.figure,
                                   color: result.asana.category.color, lineWidth: 2.4)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.asana.displayName).font(.subheadline.weight(.semibold))
                        Text("\(result.breaths)/\(result.asana.holdBreaths) breaths  -  \(Int((result.alignment * 100).rounded()))% aligned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Text("\(Int(result.score))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Theme.color(forScore: result.score))
                }
            }
        }
        .card()
    }
}
