import SwiftUI

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let color: Color
    let progress: Int
    let target: Int

    var isUnlocked: Bool { progress >= target }
    var fraction: Double { target > 0 ? Swift.min(1, Double(progress) / Double(target)) : 0 }
}

enum AchievementCatalog {
    static func evaluate(sessions: [PracticeSession], scans: [BodyScan],
                         balances: [BalanceCheck], breaths: [BreathSession]) -> [Achievement] {
        let calendar = Calendar.current
        let bestScan = scans.map(\.overallScore).max() ?? 0
        let bestBalance = balances.map { Swift.min($0.leftSeconds, $0.rightSeconds) }.max() ?? 0
        let goldPoses = AsanaLibrary.all.filter {
            Progression.mastery(breaths: Progression.breaths(for: $0.id, in: sessions)) == .gold
        }.count
        let earlyPractice = sessions.filter { calendar.component(.hour, from: $0.date) < 7 }.count

        return [
            Achievement(id: "first", title: "First Pose",
                        detail: "Hold your first asana.",
                        symbol: "figure.yoga", color: Theme.accent,
                        progress: Swift.min(1, sessions.count), target: 1),
            Achievement(id: "week", title: "A Week on the Mat",
                        detail: "Practise seven days in a row.",
                        symbol: "flame.fill", color: Theme.warm,
                        progress: Swift.max(sessions.streak, Swift.min(7, sessions.bestStreak)), target: 7),
            Achievement(id: "month", title: "A Month on the Mat",
                        detail: "Practise thirty days in a row.",
                        symbol: "flame.fill", color: Theme.warm,
                        progress: sessions.bestStreak, target: 30),
            Achievement(id: "breaths-500", title: "Five Hundred Breaths",
                        detail: "Hold 500 breaths in total.",
                        symbol: "wind", color: Theme.secondary,
                        progress: sessions.totalBreaths, target: 500),
            Achievement(id: "breaths-2000", title: "Two Thousand Breaths",
                        detail: "Hold 2,000 breaths in total.",
                        symbol: "wind", color: Theme.secondary,
                        progress: sessions.totalBreaths, target: 2000),
            Achievement(id: "hour", title: "An Hour in Poses",
                        detail: "Sixty minutes of held asanas.",
                        symbol: "clock.fill", color: Theme.accent,
                        progress: sessions.totalMinutes, target: 60),
            Achievement(id: "five-hours", title: "Five Hours in Poses",
                        detail: "Three hundred minutes of held asanas.",
                        symbol: "clock.fill", color: Theme.accent,
                        progress: sessions.totalMinutes, target: 300),
            Achievement(id: "library", title: "The Whole Library",
                        detail: "Practise every asana at least once.",
                        symbol: "books.vertical.fill", color: Theme.secondary,
                        progress: sessions.distinctAsanas, target: AsanaLibrary.all.count),
            Achievement(id: "steady", title: "Steady",
                        detail: "Reach a body score of 70.",
                        symbol: "chart.bar.fill", color: Color(red: 0.45, green: 0.85, blue: 0.55),
                        progress: Int(bestScan.rounded()), target: 70),
            Achievement(id: "strong", title: "Strong",
                        detail: "Reach a body score of 85.",
                        symbol: "star.fill", color: Color(red: 1.00, green: 0.78, blue: 0.35),
                        progress: Int(bestScan.rounded()), target: 85),
            Achievement(id: "rooted", title: "Rooted",
                        detail: "Balance 30 seconds on each foot.",
                        symbol: "tree.fill", color: Color(red: 0.45, green: 0.78, blue: 1.00),
                        progress: Int(bestBalance.rounded()), target: 30),
            Achievement(id: "scans", title: "Tracking It",
                        detail: "Take five body scans.",
                        symbol: "figure.stand.line.dotted.figure.stand", color: Theme.accent,
                        progress: scans.count, target: 5),
            Achievement(id: "gold", title: "Gold Star",
                        detail: "Reach gold mastery in any pose.",
                        symbol: "rosette", color: Color(red: 1.00, green: 0.78, blue: 0.35),
                        progress: goldPoses, target: 1),
            Achievement(id: "sunrise", title: "Sunrise Practice",
                        detail: "Hold a pose before 7am, five times.",
                        symbol: "sunrise.fill", color: Theme.warm,
                        progress: earlyPractice, target: 5),
        ]
    }

    /// Achievements unlocked by a practice that were not unlocked before it.
    static func newlyUnlocked(before: [Achievement], after: [Achievement]) -> [Achievement] {
        let already = Set(before.filter(\.isUnlocked).map(\.id))
        return after.filter { $0.isUnlocked && !already.contains($0.id) }
    }
}
