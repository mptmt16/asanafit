import Foundation

/// XP, levels, unlocks and mastery. Everything is derived from saved history,
/// so there is no separate score to keep in sync.
enum Progression {
    static let dailyGoalXP = 150

    // MARK: - Earning

    static func xp(breaths: Int, target: Int, alignment: Double) -> Int {
        var earned = breaths * 4
        if breaths >= target, target > 0 { earned += 20 }
        if alignment >= 0.9 { earned += 10 }
        return earned
    }

    static func xp(for session: PracticeSession) -> Int {
        xp(breaths: session.breathsHeld, target: session.breathsTarget, alignment: session.alignment)
    }

    static func xp(for scan: BodyScan) -> Int { 80 }

    static func xp(for check: BalanceCheck) -> Int { 40 }

    static func xp(for breath: BreathSession) -> Int { 20 }

    static func totalXP(sessions: [PracticeSession], scans: [BodyScan],
                        balances: [BalanceCheck], breaths: [BreathSession]) -> Int {
        var total = sessions.reduce(0) { $0 + xp(for: $1) }
        total += scans.reduce(0) { $0 + xp(for: $1) }
        total += balances.reduce(0) { $0 + xp(for: $1) }
        total += breaths.reduce(0) { $0 + xp(for: $1) }
        return total
    }

    static func xpEarned(on day: Date, sessions: [PracticeSession], scans: [BodyScan],
                         balances: [BalanceCheck], breaths: [BreathSession]) -> Int {
        let calendar = Calendar.current
        var total = sessions.filter { calendar.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + xp(for: $1) }
        total += scans.filter { calendar.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + xp(for: $1) }
        total += balances.filter { calendar.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + xp(for: $1) }
        total += breaths.filter { calendar.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + xp(for: $1) }
        return total
    }

    // MARK: - Levels

    /// Total XP needed to reach a level. Level 1 starts at zero.
    static func xpRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        let value = 150 * pow(Double(level - 1), 1.5)
        return Int((value / 10).rounded()) * 10
    }

    static func level(forXP xp: Int) -> Int {
        var level = 1
        while level < 60, xp >= xpRequired(forLevel: level + 1) {
            level += 1
        }
        return level
    }

    struct LevelProgress {
        var level: Int
        var xp: Int
        var levelStart: Int
        var levelEnd: Int

        var intoLevel: Int { xp - levelStart }
        var span: Int { Swift.max(1, levelEnd - levelStart) }
        var fraction: Double { Swift.min(1, Double(intoLevel) / Double(span)) }
        var remaining: Int { Swift.max(0, levelEnd - xp) }
    }

    static func progress(forXP xp: Int) -> LevelProgress {
        let level = level(forXP: xp)
        return LevelProgress(level: level, xp: xp,
                             levelStart: xpRequired(forLevel: level),
                             levelEnd: xpRequired(forLevel: level + 1))
    }

    /// A friendly name shown next to the level.
    static func rank(forLevel level: Int) -> String {
        switch level {
        case ..<3: return "New to the mat"
        case 3..<5: return "Beginner"
        case 5..<8: return "Regular"
        case 8..<12: return "Practitioner"
        case 12..<18: return "Devoted"
        default: return "Teacher"
        }
    }

    // MARK: - Unlocks

    /// Which level unlocks each asana. Everything starts locked except the five basics.
    static let unlockLevels: [String: Int] = [
        "mountain": 1, "forward-fold": 1, "half-fold": 1, "child": 1, "corpse": 1,
        "down-dog": 2, "cobra": 2,
        "low-lunge": 3, "bridge": 3,
        "warrior-two": 4, "chair": 4,
        "tree": 5, "seated-fold": 5,
        "plank": 6, "triangle": 6,
        "warrior-one": 7, "locust": 7,
        "goddess": 8, "boat": 8,
        "warrior-three": 9, "side-plank": 9,
        "camel": 10, "half-moon": 10, "dancer": 10,
    ]

    static func unlockLevel(for asanaID: String) -> Int {
        unlockLevels[asanaID] ?? 1
    }

    static func isUnlocked(_ asana: Asana, playerLevel: Int) -> Bool {
        playerLevel >= unlockLevel(for: asana.id)
    }

    static func unlocked(playerLevel: Int) -> [Asana] {
        AsanaLibrary.all.filter { isUnlocked($0, playerLevel: playerLevel) }
    }

    /// The asanas that become available on reaching a level.
    static func unlocks(atLevel level: Int) -> [Asana] {
        AsanaLibrary.all.filter { unlockLevel(for: $0.id) == level }
    }

    static let flowUnlockLevels: [String: Int] = [
        "morning": 1, "hips": 2, "wind-down": 2, "sun-salutation": 3,
        "strong-legs": 5, "core": 6, "backbends": 7, "balance": 9,
    ]

    static func unlockLevel(forFlow flowID: String) -> Int {
        flowUnlockLevels[flowID] ?? 1
    }

    static func flowUnlocks(atLevel level: Int) -> [Flow] {
        FlowLibrary.all.filter { unlockLevel(forFlow: $0.id) == level }
    }

    // MARK: - Mastery

    enum Mastery: Int {
        case none = 0, bronze = 1, silver = 2, gold = 3

        /// Total breaths held in one pose to earn this star.
        var breathsNeeded: Int {
            switch self {
            case .none: return 0
            case .bronze: return 30
            case .silver: return 100
            case .gold: return 250
            }
        }

        var title: String {
            switch self {
            case .none: return "Not started"
            case .bronze: return "Bronze"
            case .silver: return "Silver"
            case .gold: return "Gold"
            }
        }
    }

    static func breaths(for asanaID: String, in sessions: [PracticeSession]) -> Int {
        sessions.filter { $0.asanaID == asanaID }.reduce(0) { $0 + $1.breathsHeld }
    }

    static func mastery(breaths: Int) -> Mastery {
        if breaths >= Mastery.gold.breathsNeeded { return .gold }
        if breaths >= Mastery.silver.breathsNeeded { return .silver }
        if breaths >= Mastery.bronze.breathsNeeded { return .bronze }
        return .none
    }

    /// Breaths still needed for the next star, or nil at gold.
    static func breathsToNextStar(breaths: Int) -> Int? {
        for step in [Mastery.bronze, .silver, .gold] where breaths < step.breathsNeeded {
            return step.breathsNeeded - breaths
        }
        return nil
    }
}
