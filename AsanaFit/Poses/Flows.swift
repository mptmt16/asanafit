import SwiftUI

/// A named sequence of asanas, practised one after another.
struct Flow: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let symbol: String
    let color: Color
    let asanaIDs: [String]
    var level: AsanaLevel = .beginner

    var asanas: [Asana] { AsanaLibrary.asanas(ids: asanaIDs) }

    var estimatedDuration: TimeInterval {
        asanas.reduce(0) { $0 + $1.estimatedDuration }
    }

    /// The poses of this flow that the practitioner has unlocked, in order.
    func unlockedAsanas(playerLevel: Int) -> [Asana] {
        asanas.filter { Progression.isUnlocked($0, playerLevel: playerLevel) }
    }
}

enum FlowLibrary {
    static let all: [Flow] = [
        Flow(id: "sun-salutation", name: "Sun Salutation",
             summary: "The classic round: fold, plank, cobra, dog and back up.",
             symbol: "sun.max", color: Color(red: 1.00, green: 0.72, blue: 0.38),
             asanaIDs: ["mountain", "forward-fold", "half-fold", "plank", "cobra",
                        "down-dog", "forward-fold", "mountain"],
             level: .intermediate),
        Flow(id: "morning", name: "Morning Wake-Up",
             summary: "Gentle openers to get the night out of your spine.",
             symbol: "sunrise", color: Color(red: 1.00, green: 0.62, blue: 0.45),
             asanaIDs: ["mountain", "half-fold", "forward-fold", "low-lunge", "down-dog", "cobra", "child"],
             level: .beginner),
        Flow(id: "strong-legs", name: "Strong Legs",
             summary: "Warriors and a long chair hold. Your thighs will know.",
             symbol: "figure.martial.arts", color: Color(red: 0.62, green: 0.56, blue: 1.00),
             asanaIDs: ["mountain", "chair", "warrior-one", "warrior-two", "triangle", "goddess", "forward-fold"],
             level: .intermediate),
        Flow(id: "core", name: "Core & Strength",
             summary: "Planks, boat and locust, with a rest at the end.",
             symbol: "figure.core.training", color: Color(red: 1.00, green: 0.55, blue: 0.48),
             asanaIDs: ["down-dog", "plank", "side-plank", "boat", "locust", "child"],
             level: .intermediate),
        Flow(id: "balance", name: "Balance Builder",
             summary: "One leg at a time, from tree up to dancer.",
             symbol: "figure.yoga", color: Color(red: 0.45, green: 0.78, blue: 1.00),
             asanaIDs: ["mountain", "tree", "warrior-three", "half-moon", "dancer", "mountain"],
             level: .advanced),
        Flow(id: "hips", name: "Hips & Hamstrings",
             summary: "Long, quiet holds for everything that tightens at a desk.",
             symbol: "figure.cooldown", color: Color(red: 0.35, green: 0.85, blue: 0.72),
             asanaIDs: ["half-fold", "forward-fold", "low-lunge", "down-dog", "seated-fold", "child"],
             level: .beginner),
        Flow(id: "backbends", name: "Open Your Chest",
             summary: "Backbends to undo a day spent leaning over a screen.",
             symbol: "figure.flexibility", color: Color(red: 1.00, green: 0.72, blue: 0.38),
             asanaIDs: ["cobra", "locust", "bridge", "camel", "child"],
             level: .intermediate),
        Flow(id: "wind-down", name: "Wind Down",
             summary: "Slow, floor-based and short. Made for the end of the day.",
             symbol: "moon.stars", color: Color(red: 0.60, green: 0.85, blue: 0.50),
             asanaIDs: ["seated-fold", "bridge", "child", "corpse"],
             level: .beginner),
    ]

    static func flow(id: String) -> Flow? {
        all.first { $0.id == id }
    }
}
