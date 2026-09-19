import Foundation

/// Paces the breath during a hold.
///
/// Yoga counts a hold in breaths rather than seconds, so the whole app does too. The exhale is
/// made longer than the inhale, which is the part that actually settles the nervous system.
struct BreathPacer {
    enum Phase: String {
        case inhale, exhale

        var cue: String {
            switch self {
            case .inhale: "Breathe in"
            case .exhale: "Breathe out"
            }
        }
    }

    struct State {
        var phase: Phase
        /// 0...1 through the current inhale or exhale.
        var phaseProgress: Double
        /// How many full breaths have finished.
        var completed: Int
        /// 0...1 through the current breath.
        var breathProgress: Double
    }

    static let defaultBreathSeconds: Double = 5
    static let inhaleFraction: Double = 0.42

    var breathSeconds: Double = BreathPacer.defaultBreathSeconds

    func state(at elapsed: TimeInterval) -> State {
        let breaths = max(0, elapsed) / breathSeconds
        let completed = Int(breaths)
        let within = breaths - Double(completed)
        if within < Self.inhaleFraction {
            return State(phase: .inhale, phaseProgress: within / Self.inhaleFraction,
                         completed: completed, breathProgress: within)
        }
        let out = (within - Self.inhaleFraction) / (1 - Self.inhaleFraction)
        return State(phase: .exhale, phaseProgress: out, completed: completed, breathProgress: within)
    }

    /// How long a given number of breaths takes.
    func seconds(forBreaths breaths: Int) -> TimeInterval {
        Double(breaths) * breathSeconds
    }
}

/// A breathing exercise for the Breathe tab, away from the camera.
struct BreathPattern: Identifiable, Hashable {
    let id: String
    let name: String
    let sanskrit: String
    let summary: String
    /// Seconds for breathe in, hold in, breathe out, hold out. A zero step is skipped.
    let inhale: Double
    let holdIn: Double
    let exhale: Double
    let holdOut: Double
    let defaultRounds: Int
    let benefit: String

    var roundSeconds: Double { inhale + holdIn + exhale + holdOut }

    func duration(rounds: Int) -> TimeInterval { roundSeconds * Double(rounds) }

    /// Which step you are in, and how far through it, at a point in a round.
    func step(at elapsed: TimeInterval) -> (label: String, progress: Double, isIn: Bool) {
        let within = elapsed.truncatingRemainder(dividingBy: max(roundSeconds, 0.1))
        var start = 0.0
        for (label, length, isIn) in [("Breathe in", inhale, true), ("Hold", holdIn, true),
                                      ("Breathe out", exhale, false), ("Hold", holdOut, false)] {
            guard length > 0 else { continue }
            if within < start + length {
                return (label, (within - start) / length, isIn)
            }
            start += length
        }
        return ("Breathe out", 1, false)
    }

    static let all: [BreathPattern] = [
        BreathPattern(id: "even", name: "Even Breath", sanskrit: "Sama Vritti",
                      summary: "Breathe in and out for the same count.",
                      inhale: 4, holdIn: 0, exhale: 4, holdOut: 0, defaultRounds: 12,
                      benefit: "Steadies a scattered mind. A good place to start."),
        BreathPattern(id: "long-exhale", name: "Long Exhale", sanskrit: "Visama Vritti",
                      summary: "Breathe out for twice as long as you breathe in.",
                      inhale: 4, holdIn: 0, exhale: 8, holdOut: 0, defaultRounds: 10,
                      benefit: "The longest exhale is the most calming. Good before sleep."),
        BreathPattern(id: "box", name: "Box Breath", sanskrit: "Sama Vritti with retention",
                      summary: "In, hold, out, hold, all for four.",
                      inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, defaultRounds: 8,
                      benefit: "Sharpens focus and slows a racing heart."),
        BreathPattern(id: "four-seven-eight", name: "4-7-8", sanskrit: "Relaxing breath",
                      summary: "In for four, hold for seven, out for eight.",
                      inhale: 4, holdIn: 7, exhale: 8, holdOut: 0, defaultRounds: 6,
                      benefit: "A strong wind-down. Sit or lie down for this one."),
        BreathPattern(id: "ocean", name: "Ocean Breath", sanskrit: "Ujjayi",
                      summary: "Slow breathing with a soft hiss at the back of the throat.",
                      inhale: 5, holdIn: 0, exhale: 6, holdOut: 0, defaultRounds: 12,
                      benefit: "The breath used through a flowing practice. Warms and steadies you."),
    ]
}
