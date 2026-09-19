import Foundation
import SwiftData

/// One side of one asana, held and saved.
@Model
final class PracticeSession {
    var date: Date = Date()
    var asanaID: String = ""
    var asanaName: String = ""
    var categoryRaw: String = ""
    var sideRaw: String = "none"
    var breathsHeld: Int = 0
    var breathsTarget: Int = 0
    var heldSeconds: Double = 0
    /// Mean alignment while holding, 0...1.
    var alignment: Double = 0
    /// How still you were, 0...1.
    var steadiness: Double = 0
    /// Mean left-to-right balance, 0...1, when the pose had two sides to compare.
    var balance: Double?

    init(result: AsanaResult, date: Date = .now) {
        self.date = date
        asanaID = result.asana.id
        asanaName = result.asana.name
        categoryRaw = result.asana.category.rawValue
        sideRaw = result.side.rawValue
        breathsHeld = result.breaths
        breathsTarget = result.asana.holdBreaths
        heldSeconds = result.heldSeconds
        alignment = result.alignment
        steadiness = result.steadiness
        balance = result.balance
    }

    var category: AsanaCategory? { AsanaCategory(rawValue: categoryRaw) }
    var side: Side { Side(rawValue: sideRaw) ?? .none }

    /// The 0...100 score shown in history.
    var score: Double {
        let held = min(1, Double(breathsHeld) / Double(max(1, breathsTarget)))
        return ((alignment * 0.55 + steadiness * 0.2 + held * 0.25) * 100).rounded()
    }
}

/// One full body scan.
@Model
final class BodyScan {
    var date: Date = Date()
    var overallScore: Double = 0
    var postureScore: Double = 0
    var flexibilityScore: Double = 0
    var balanceScore: Double = 0
    var mobilityScore: Double = 0
    var symmetryScore: Double = 0
    @Attribute(.externalStorage) var measurementsData: Data?
    @Attribute(.externalStorage) var areasData: Data?

    init(outcome: ScanOutcome, date: Date = .now) {
        self.date = date
        overallScore = outcome.overallScore
        postureScore = outcome.postureScore
        flexibilityScore = outcome.flexibilityScore
        balanceScore = outcome.balanceScore
        mobilityScore = outcome.mobilityScore
        symmetryScore = outcome.symmetryScore
        let encoder = JSONEncoder()
        measurementsData = try? encoder.encode(outcome.measurements)
        areasData = try? encoder.encode(outcome.areas)
    }

    var measurements: [ScanMeasurement] {
        guard let measurementsData else { return [] }
        return (try? JSONDecoder().decode([ScanMeasurement].self, from: measurementsData)) ?? []
    }

    var areas: [AreaScore] {
        guard let areasData else { return [] }
        return (try? JSONDecoder().decode([AreaScore].self, from: areasData)) ?? []
    }

    func measurement(_ id: String) -> ScanMeasurement? {
        measurements.first { $0.id == id }
    }

    var breakdown: BodyScoreBreakdown {
        BodyScoreBreakdown(posture: postureScore, flexibility: flexibilityScore,
                           balance: balanceScore, mobility: mobilityScore)
    }

    var level: BodyLevel { BodyLevel(score: overallScore) }

    /// The areas with the most room to grow, weakest first.
    var weakestAreas: [BodyArea] {
        areas.sorted { $0.score < $1.score }.map(\.area)
    }
}

/// One two-sided balance test.
@Model
final class BalanceCheck {
    var date: Date = Date()
    var leftSeconds: Double = 0
    var rightSeconds: Double = 0
    var leftSteadiness: Double = 0
    var rightSteadiness: Double = 0
    var score: Double = 0

    init(result: BalanceTestResult, date: Date = .now) {
        self.date = date
        leftSeconds = result.leftSeconds
        rightSeconds = result.rightSeconds
        leftSteadiness = result.leftSteadiness
        rightSteadiness = result.rightSteadiness
        score = result.score
    }

    var result: BalanceTestResult {
        BalanceTestResult(leftSeconds: leftSeconds, rightSeconds: rightSeconds,
                          leftSteadiness: leftSteadiness, rightSteadiness: rightSteadiness)
    }

    var advice: [String] { BalanceScoring.advice(result) }
}

/// One finished breathing practice.
@Model
final class BreathSession {
    var date: Date = Date()
    var patternID: String = ""
    var patternName: String = ""
    var rounds: Int = 0
    var seconds: Double = 0

    init(pattern: BreathPattern, rounds: Int, seconds: Double, date: Date = .now) {
        self.date = date
        patternID = pattern.id
        patternName = pattern.name
        self.rounds = rounds
        self.seconds = seconds
    }
}

extension Array where Element == PracticeSession {
    /// Consecutive days (ending today or yesterday) with at least one pose held.
    var streak: Int {
        let calendar = Calendar.current
        let days = Set(map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: .now)
        if !days.contains(day), let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        var count = 0
        while days.contains(day), let previous = calendar.date(byAdding: .day, value: -1, to: day) {
            count += 1
            day = previous
        }
        return count
    }

    /// The longest run of consecutive practice days ever.
    var bestStreak: Int {
        let calendar = Calendar.current
        let days = Set(map { calendar.startOfDay(for: $0.date) }).sorted()
        var best = 0
        var current = 0
        var previous: Date?
        for day in days {
            if let previous, let expected = calendar.date(byAdding: .day, value: 1, to: previous), expected == day {
                current += 1
            } else {
                current = 1
            }
            best = Swift.max(best, current)
            previous = day
        }
        return best
    }

    var totalBreaths: Int {
        reduce(0) { $0 + $1.breathsHeld }
    }

    var totalMinutes: Int {
        Int((reduce(0) { $0 + $1.heldSeconds } / 60).rounded())
    }

    var distinctAsanas: Int {
        Set(map(\.asanaID)).count
    }
}
