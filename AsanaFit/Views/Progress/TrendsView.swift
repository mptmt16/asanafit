import Charts
import SwiftData
import SwiftUI

struct TrendsView: View {
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @Query(sort: \BodyScan.date) private var scans: [BodyScan]
    @Query private var balances: [BalanceCheck]
    @Query private var breathSessions: [BreathSession]

    private struct ScorePoint: Identifiable {
        let id = UUID()
        let date: Date
        let metric: String
        let value: Double
    }

    private struct DayMinutes: Identifiable {
        let day: Date
        let minutes: Double
        var id: Date { day }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalsRow
                    achievementsLink
                    scoreChart
                    minutesChart
                    categoryBreakdown
                    recentSessions
                }
                .padding()
                .padding(.bottom, 24)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Progress")
        }
    }

    // MARK: - Data

    private var scorePoints: [ScorePoint] {
        scans.flatMap { scan in
            [
                ScorePoint(date: scan.date, metric: "Overall", value: scan.overallScore),
                ScorePoint(date: scan.date, metric: "Posture", value: scan.postureScore),
                ScorePoint(date: scan.date, metric: "Flexibility", value: scan.flexibilityScore),
                ScorePoint(date: scan.date, metric: "Balance", value: scan.balanceScore),
                ScorePoint(date: scan.date, metric: "Mobility", value: scan.mobilityScore),
            ]
        }
    }

    private var last30Days: [DayMinutes] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var totals: [Date: Double] = [:]
        for session in sessions {
            totals[calendar.startOfDay(for: session.date), default: 0] += session.heldSeconds / 60
        }
        return (0..<30).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayMinutes(day: day, minutes: totals[day] ?? 0)
        }
    }

    // MARK: - Sections

    private var totalsRow: some View {
        HStack(spacing: 12) {
            StatTile(title: "Holds", value: "\(sessions.count)", symbol: "checkmark.circle")
            StatTile(title: "Minutes", value: "\(sessions.totalMinutes)",
                     symbol: "clock", color: Theme.secondary)
            StatTile(title: "Best streak", value: "\(sessions.bestStreak)",
                     symbol: "flame.fill", color: Theme.warm)
        }
    }

    private var achievementsLink: some View {
        let achievements = AchievementCatalog.evaluate(sessions: sessions, scans: scans,
                                                       balances: balances, breaths: breathSessions)
        let unlocked = achievements.filter(\.isUnlocked).count
        return NavigationLink {
            AchievementsView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.warm)
                    .frame(width: 40, height: 40)
                    .background(Theme.warm.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Badges").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text("\(unlocked) of \(achievements.count) unlocked")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var scoreChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Body score over time",
                          subtitle: scans.count < 2 ? "Take two scans to see a trend." : nil)
            if scans.count >= 2 {
                Chart(scorePoints) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Score", point.value))
                        .foregroundStyle(by: .value("Metric", point.metric))
                        .symbol(by: .value("Metric", point.metric))
                }
                .chartYScale(domain: 0...100)
                .chartLegend(position: .bottom, spacing: 8)
                .frame(height: 220)
            }
        }
        .card()
    }

    private var minutesChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Last 30 days", subtitle: "Minutes actually spent holding poses.")
            Chart(last30Days) { day in
                BarMark(x: .value("Day", day.day, unit: .day),
                        y: .value("Minutes", day.minutes))
                    .foregroundStyle(Theme.accent)
            }
            .frame(height: 150)
        }
        .card()
    }

    private var categoryBreakdown: some View {
        let totals = Dictionary(grouping: sessions, by: { $0.categoryRaw })
            .mapValues { group in group.reduce(0) { $0 + $1.breathsHeld } }
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Where your breaths go", subtitle: nil)
            ForEach(AsanaCategory.allCases) { category in
                let breaths = totals[category.rawValue] ?? 0
                let peak = max(1, totals.values.max() ?? 1)
                HStack(spacing: 10) {
                    Image(systemName: category.symbol)
                        .font(.caption)
                        .foregroundStyle(category.color)
                        .frame(width: 22)
                    Text(category.title).font(.caption).frame(width: 130, alignment: .leading)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule().fill(category.color)
                                .frame(width: proxy.size.width * Double(breaths) / Double(peak))
                        }
                    }
                    .frame(height: 8)
                    Text("\(breaths)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .trailing)
                }
            }
        }
        .card()
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent holds", subtitle: nil)
            if sessions.isEmpty {
                Text("Nothing yet. Hold your first pose and it will show up here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(sessions.prefix(15)) { session in
                HStack(spacing: 12) {
                    Image(systemName: session.category?.symbol ?? "figure.yoga")
                        .font(.caption)
                        .foregroundStyle(session.category?.color ?? Theme.accent)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.asanaName + (session.side == .none ? "" : " (\(session.side.shortLabel))"))
                            .font(.subheadline)
                        Text(session.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Text("\(session.breathsHeld)/\(session.breathsTarget)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text("\(Int(session.score))")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(Theme.color(forScore: session.score))
                        .frame(width: 34, alignment: .trailing)
                }
            }
        }
        .card()
    }
}
