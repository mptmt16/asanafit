import Foundation

/// The everyday habits that change what your body can do on the mat.
/// All of it stays on the device, in UserDefaults.
struct Habits {
    var sleepHours: Double
    var sittingHours: Double
    var waterGlasses: Int
}

struct DailyTip {
    let text: String
    let symbol: String
}

/// Picks one useful thing to say on the Today screen, based on your habits,
/// your last scan and how the streak is going.
enum TipEngine {
    static func tip(habits: Habits, scan: BodyScan?, streak: Int, practisedToday: Bool) -> DailyTip {
        if habits.sittingHours >= 8 {
            return DailyTip(
                text: "You sit for about \(Int(habits.sittingHours)) hours a day. Low lunge and cobra undo more of that than any stretch you do at your desk.",
                symbol: "chair")
        }
        if habits.sleepHours > 0, habits.sleepHours < 6.5 {
            return DailyTip(
                text: "On \(habits.sleepHours.trimmedString) hours of sleep, go gentle today. Forward folds and long exhales suit a tired body better than balance work.",
                symbol: "moon.zzz")
        }
        if let scan, let weakest = scan.areas.min(by: { $0.score < $1.score }) {
            return DailyTip(text: weakest.insight, symbol: weakest.area.symbol)
        }
        if habits.waterGlasses > 0, habits.waterGlasses < 5 {
            return DailyTip(
                text: "Only \(habits.waterGlasses) glasses of water so far. Muscles stretch more willingly when they are not short of it.",
                symbol: "drop.fill")
        }
        if streak >= 7 {
            return DailyTip(
                text: "\(streak) days in a row. Consistency is what actually changes a body, not the length of any one practice.",
                symbol: "flame.fill")
        }
        if practisedToday {
            return DailyTip(
                text: "Already practised today. If you come back later, make it something restful.",
                symbol: "checkmark.seal")
        }
        return DailyTip(
            text: "Take your first body scan and the app can build a practice around what your body actually needs.",
            symbol: "figure.stand.line.dotted.figure.stand")
    }
}
