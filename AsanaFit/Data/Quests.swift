import Foundation

/// One of today's three bonus goals.
struct Quest: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let target: Int
    let progress: Int
    let xp: Int

    var isComplete: Bool { progress >= target }
    var fraction: Double { target > 0 ? Swift.min(1, Double(progress) / Double(target)) : 0 }
}

/// Everything that happened today, which is all a quest needs to measure itself.
struct DayRecord {
    var sessions: [PracticeSession]
    var scans: [BodyScan]
    var balances: [BalanceCheck]
    var breaths: [BreathSession]
    var xp: Int

    static func make(day: Date, sessions: [PracticeSession], scans: [BodyScan],
                     balances: [BalanceCheck], breaths: [BreathSession]) -> DayRecord {
        let calendar = Calendar.current
        let today = { (date: Date) in calendar.isDate(date, inSameDayAs: day) }
        let todaySessions = sessions.filter { today($0.date) }
        let todayScans = scans.filter { today($0.date) }
        let todayBalances = balances.filter { today($0.date) }
        let todayBreaths = breaths.filter { today($0.date) }
        return DayRecord(
            sessions: todaySessions, scans: todayScans, balances: todayBalances, breaths: todayBreaths,
            xp: Progression.xpEarned(on: day, sessions: sessions, scans: scans,
                                     balances: balances, breaths: breaths)
        )
    }
}

/// The three daily quests. The set is chosen from the date, so it is the same all day
/// and different tomorrow, and progress is read straight from your history.
enum QuestBoard {
    private struct Template {
        let id: String
        let title: String
        let detail: String
        let symbol: String
        let target: Int
        let xp: Int
        let measure: (DayRecord) -> Int
    }

    private static let templates: [Template] = [
        Template(id: "breaths", title: "Hold 40 breaths", detail: "Across any poses you like.",
                 symbol: "wind", target: 40, xp: 50) { $0.sessions.totalBreaths },
        Template(id: "variety", title: "Practise 5 poses", detail: "Five different shapes today.",
                 symbol: "square.grid.2x2", target: 5, xp: 60) { $0.sessions.distinctAsanas },
        Template(id: "xp", title: "Earn 120 XP", detail: "However you like to earn it.",
                 symbol: "bolt.fill", target: 120, xp: 40) { $0.xp },
        Template(id: "precise", title: "Three clean holds", detail: "Hold three poses at 85% alignment or better.",
                 symbol: "target", target: 3, xp: 70) { record in
                     record.sessions.filter { $0.alignment >= 0.85 }.count
                 },
        Template(id: "scan", title: "Take a body scan", detail: "Nine steps, about two minutes.",
                 symbol: "figure.stand.line.dotted.figure.stand", target: 1, xp: 60) { $0.scans.count },
        Template(id: "balance-test", title: "Run the balance test", detail: "One foot at a time, as long as you can.",
                 symbol: "figure.yoga", target: 1, xp: 50) { $0.balances.count },
        Template(id: "breathe", title: "Finish a breathing practice", detail: "Any pattern, any length.",
                 symbol: "lungs.fill", target: 1, xp: 40) { $0.breaths.count },
        Template(id: "minutes", title: "Six minutes on the mat", detail: "Time actually spent holding poses.",
                 symbol: "clock", target: 6, xp: 60) { $0.sessions.totalMinutes },
        Template(id: "balance-poses", title: "Two balance poses", detail: "Anything from the Balance group.",
                 symbol: "figure.yoga", target: 2, xp: 60) { record in
                     record.sessions.filter { $0.category == .balance }.count
                 },
        Template(id: "open-hips", title: "Three hip or fold poses", detail: "Anything from Hips & Forward Folds.",
                 symbol: "figure.cooldown", target: 3, xp: 60) { record in
                     record.sessions.filter { $0.category == .hips }.count
                 },
        Template(id: "complete", title: "Finish four poses in full", detail: "Every breath of the hold, four times.",
                 symbol: "checkmark.seal.fill", target: 4, xp: 70) { record in
                     record.sessions.filter { $0.breathsTarget > 0 && $0.breathsHeld >= $0.breathsTarget }.count
                 },
        Template(id: "both-sides", title: "Both sides of two poses", detail: "Left and right of the same shape.",
                 symbol: "arrow.left.arrow.right", target: 2, xp: 60) { record in
                     var sides: [String: Set<String>] = [:]
                     for session in record.sessions where session.side != .none {
                         sides[session.asanaID, default: []].insert(session.sideRaw)
                     }
                     return sides.values.filter { $0.count >= 2 }.count
                 },
    ]

    static func today(_ record: DayRecord, on day: Date = .now) -> [Quest] {
        let calendar = Calendar.current
        let seed = calendar.ordinality(of: .day, in: .era, for: day) ?? 0
        var chosen: [Template] = []
        var offset = 0
        // Three different templates, stepped through the list by a stride that never repeats a pick.
        while chosen.count < 3, offset < templates.count {
            let index = (seed &* 7 &+ offset &* 5) % templates.count
            let template = templates[index]
            if !chosen.contains(where: { $0.id == template.id }) {
                chosen.append(template)
            }
            offset += 1
        }
        return chosen.map { template in
            Quest(id: template.id, title: template.title, detail: template.detail,
                  symbol: template.symbol, target: template.target,
                  progress: template.measure(record), xp: template.xp)
        }
    }

    /// Bonus XP already earned from today's quests.
    static func earnedXP(_ quests: [Quest]) -> Int {
        quests.filter(\.isComplete).reduce(0) { $0 + $1.xp }
    }
}
