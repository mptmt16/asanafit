import SwiftUI

/// What a scan step is looking for.
enum ScanCapture: String, Codable, CaseIterable {
    case posture, sidePosture, reach, fold, squat, balanceLeft, balanceRight, bendLeft, bendRight
}

/// One guided step of the body scan.
struct ScanStep: Identifiable {
    let capture: ScanCapture
    let title: String
    let instruction: String
    let detail: String
    let facing: CameraFacing
    let seconds: Double
    /// The shape to show as a demo while the step runs.
    let figure: FigurePose

    var id: String { capture.rawValue }

    static let all: [ScanStep] = [
        ScanStep(capture: .posture, title: "Stand tall",
                 instruction: "Face the camera and stand naturally",
                 detail: "Feet under your hips, arms by your sides. Don't correct yourself.",
                 facing: .front, seconds: 5,
                 figure: FigurePose()),
        ScanStep(capture: .sidePosture, title: "Turn side-on",
                 instruction: "Turn to your right and stand naturally",
                 detail: "Same easy standing, seen from the side.",
                 facing: .side, seconds: 5,
                 figure: FigurePose()),
        ScanStep(capture: .reach, title: "Reach up",
                 instruction: "Face the camera and reach both arms overhead",
                 detail: "Straight arms, as far back as your shoulders allow.",
                 facing: .front, seconds: 5,
                 figure: FigurePose(leftUpperArm: 4, leftForearm: 2, rightUpperArm: -4, rightForearm: -2)),
        ScanStep(capture: .fold, title: "Fold forward",
                 instruction: "Side-on, fold forward as far as is comfortable",
                 detail: "Legs straight if you can, and let your head hang.",
                 facing: .side, seconds: 6,
                 figure: AsanaLibrary.asana(id: "forward-fold")?.figure ?? FigurePose()),
        ScanStep(capture: .squat, title: "Squat down",
                 instruction: "Side-on, squat as low as you comfortably can",
                 detail: "Heels down if they will stay down. Hold the lowest point.",
                 facing: .side, seconds: 6,
                 figure: FigurePose(spine: 28, head: 20,
                                    leftUpperArm: 100, leftForearm: 98, rightUpperArm: 98, rightForearm: 96,
                                    leftThigh: 120, leftShin: 215, rightThigh: 118, rightShin: 213)),
        ScanStep(capture: .balanceLeft, title: "Balance, left foot",
                 instruction: "Stand on your left foot only",
                 detail: "Lift your right foot and stay as still as you can.",
                 facing: .front, seconds: 8,
                 figure: AsanaLibrary.asana(id: "tree")?.figure.mirrored ?? FigurePose()),
        ScanStep(capture: .balanceRight, title: "Balance, right foot",
                 instruction: "Stand on your right foot only",
                 detail: "Lift your left foot and stay as still as you can.",
                 facing: .front, seconds: 8,
                 figure: AsanaLibrary.asana(id: "tree")?.figure ?? FigurePose()),
        ScanStep(capture: .bendLeft, title: "Bend left",
                 instruction: "Face the camera and lean over to your left",
                 detail: "Keep both feet down and don't twist.",
                 facing: .front, seconds: 4,
                 figure: FigurePose(spine: 335, head: 330,
                                    leftUpperArm: 200, leftForearm: 200, rightUpperArm: 20, rightForearm: 15)),
        ScanStep(capture: .bendRight, title: "Bend right",
                 instruction: "Face the camera and lean over to your right",
                 detail: "Keep both feet down and don't twist.",
                 facing: .front, seconds: 4,
                 figure: FigurePose(spine: 25, head: 30,
                                    leftUpperArm: 340, leftForearm: 345, rightUpperArm: 160, rightForearm: 160)),
    ]

    static var totalSeconds: Double {
        all.reduce(0) { $0 + $1.seconds + BodyScanEngine.prepareSeconds }
    }
}

/// One number the scan produced, with what it means.
struct ScanMeasurement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let value: Double
    let unit: String
    /// 0...100 for this measurement on its own.
    let score: Double
    let insight: String
    /// Left and right values, when the measurement has two sides.
    var left: Double?
    var right: Double?

    var display: String {
        unit == "deg" ? "\(Int(value.rounded()))\u{00B0}" : String(format: "%.2f", value)
    }

    /// 0...1 balance between the sides, or nil when there is only one value.
    var balance: Double? {
        guard let left, let right else { return nil }
        let strongest = Swift.max(abs(left), abs(right))
        guard strongest > 0.001 else { return 1 }
        return 1 - Swift.min(1, abs(left - right) / strongest)
    }
}

/// The parts of the body the app scores and trains.
enum BodyArea: String, CaseIterable, Codable, Identifiable {
    case hamstrings, hips, shoulders, spine, balance, alignment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hamstrings: "Hamstrings & Back Line"
        case .hips: "Hips & Ankles"
        case .shoulders: "Shoulders"
        case .spine: "Spine"
        case .balance: "Balance"
        case .alignment: "Alignment"
        }
    }

    var symbol: String {
        switch self {
        case .hamstrings: "figure.cooldown"
        case .hips: "figure.flexibility"
        case .shoulders: "figure.arms.open"
        case .spine: "figure.stand"
        case .balance: "figure.yoga"
        case .alignment: "ruler"
        }
    }

    var color: Color {
        switch self {
        case .hamstrings: Color(red: 0.35, green: 0.85, blue: 0.72)
        case .hips: Color(red: 1.00, green: 0.72, blue: 0.38)
        case .shoulders: Color(red: 0.45, green: 0.78, blue: 1.00)
        case .spine: Color(red: 0.62, green: 0.56, blue: 1.00)
        case .balance: Color(red: 1.00, green: 0.55, blue: 0.48)
        case .alignment: Color(red: 0.60, green: 0.85, blue: 0.50)
        }
    }

    var blurb: String {
        switch self {
        case .hamstrings: "How far you fold, and how freely your back lets you."
        case .hips: "How deep you can sink, and how open the front of your hips is."
        case .shoulders: "How far overhead your arms travel with a straight spine."
        case .spine: "How far you bend to each side, and how tall you stand."
        case .balance: "How long and how steadily you hold one foot."
        case .alignment: "Whether your shoulders and hips sit level at rest."
        }
    }

    /// The poses that train this area, best first.
    var asanaIDs: [String] {
        switch self {
        case .hamstrings: ["forward-fold", "half-fold", "seated-fold", "down-dog"]
        case .hips: ["low-lunge", "goddess", "warrior-one", "child"]
        case .shoulders: ["down-dog", "chair", "cobra", "locust"]
        case .spine: ["triangle", "cobra", "bridge", "camel"]
        case .balance: ["tree", "warrior-three", "half-moon", "dancer"]
        case .alignment: ["mountain", "plank", "warrior-two", "bridge"]
        }
    }
}

/// One area's score and what is holding it back.
struct AreaScore: Identifiable, Codable, Hashable {
    let area: BodyArea
    let score: Double
    let insight: String

    var id: String { area.rawValue }
}

/// Everything one body scan produced.
struct ScanOutcome {
    var overallScore: Double
    var postureScore: Double
    var flexibilityScore: Double
    var balanceScore: Double
    var mobilityScore: Double
    var symmetryScore: Double
    var measurements: [ScanMeasurement]
    var areas: [AreaScore]

    /// The weakest areas first: what the practice plan should work on.
    var weakestAreas: [BodyArea] {
        areas.sorted { $0.score < $1.score }.map(\.area)
    }

    func measurement(_ id: String) -> ScanMeasurement? {
        measurements.first { $0.id == id }
    }
}

/// The four pillars, for the radar chart and the comparison view.
struct BodyScoreBreakdown {
    var posture: Double
    var flexibility: Double
    var balance: Double
    var mobility: Double

    static let weights = (posture: 0.25, flexibility: 0.30, balance: 0.25, mobility: 0.20)

    var overall: Double {
        posture * Self.weights.posture + flexibility * Self.weights.flexibility
            + balance * Self.weights.balance + mobility * Self.weights.mobility
    }

    var pillars: [(name: String, value: Double, weight: Double)] {
        [("Posture", posture, Self.weights.posture),
         ("Flexibility", flexibility, Self.weights.flexibility),
         ("Balance", balance, Self.weights.balance),
         ("Mobility", mobility, Self.weights.mobility)]
    }

    /// The pillar with the most room to grow, weighted by how much it counts.
    var focus: String {
        pillars.max { ($0.weight * (100 - $0.value)) < ($1.weight * (100 - $1.value)) }?.name ?? "Posture"
    }
}

/// Where a body score sits, and what it takes to move up.
struct BodyLevel {
    let title: String
    let minimum: Double
    let next: Double?

    static let levels: [(String, Double)] = [
        ("Getting started", 0), ("Building", 45), ("Steady", 60), ("Strong", 75), ("Advanced", 88),
    ]

    init(score: Double) {
        var index = 0
        for (offset, level) in Self.levels.enumerated() where score >= level.1 {
            index = offset
        }
        title = Self.levels[index].0
        minimum = Self.levels[index].1
        next = index + 1 < Self.levels.count ? Self.levels[index + 1].1 : nil
    }

    func pointsToNext(from score: Double) -> Double? {
        guard let next else { return nil }
        return max(0, next - score)
    }
}
