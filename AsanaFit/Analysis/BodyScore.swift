import Foundation

/// Turns the raw numbers a scan collected into scores, measurements and insights.
///
/// Every threshold here is a starting point chosen to be encouraging rather than clinical.
/// They are easy to move: each one is a `best` and a `worst` value in real units.
enum BodyScoring {
    enum Reduce {
        case median, low, high, mean
    }

    // MARK: - Small statistics

    static func percentile(_ values: [Double], _ fraction: Double) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let position = max(0, min(Double(sorted.count - 1), fraction * Double(sorted.count - 1)))
        let lower = Int(position)
        let upper = min(sorted.count - 1, lower + 1)
        let mix = position - Double(lower)
        return sorted[lower] * (1 - mix) + sorted[upper] * mix
    }

    static func reduce(_ readings: [String: [Double]], _ key: String, _ kind: Reduce) -> Double? {
        guard let values = readings[key], !values.isEmpty else { return nil }
        switch kind {
        case .median: return percentile(values, 0.5)
        case .low: return percentile(values, 0.1)
        case .high: return percentile(values, 0.9)
        case .mean: return values.reduce(0, +) / Double(values.count)
        }
    }

    static func fraction(_ readings: [String: [Double]], _ key: String, atLeast threshold: Double) -> Double? {
        guard let values = readings[key], !values.isEmpty else { return nil }
        return Double(values.filter { $0 >= threshold }.count) / Double(values.count)
    }

    /// 100 at or past `best`, 0 at or past `worst`, straight line in between.
    /// `best` may be the larger or the smaller number.
    static func score(_ value: Double, best: Double, worst: Double) -> Double {
        guard best != worst else { return 100 }
        let fraction = (value - worst) / (best - worst)
        return min(100, max(0, fraction * 100))
    }

    static func mean(_ values: [Double?]) -> Double? {
        let found = values.compactMap { $0 }
        guard !found.isEmpty else { return nil }
        return found.reduce(0, +) / Double(found.count)
    }

    /// 0...1 agreement between a left and a right measurement.
    static func balance(_ left: Double?, _ right: Double?) -> Double? {
        guard let left, let right else { return nil }
        let strongest = Swift.max(abs(left), abs(right))
        guard strongest > 0.001 else { return 1 }
        return 1 - Swift.min(1, abs(left - right) / strongest)
    }

    // MARK: - The scan result

    static func outcome(from readings: [String: [Double]]) -> ScanOutcome {
        // Standing alignment.
        let shoulderTilt = reduce(readings, "posture.shoulderTilt", .median)
        let hipTilt = reduce(readings, "posture.hipTilt", .median)
        let frontLean = reduce(readings, "posture.spineTilt", .median)
        let headTilt = reduce(readings, "posture.headTilt", .median)
        let sideLean = reduce(readings, "sidePosture.spineTilt", .median)
        let standingKnee = mean([reduce(readings, "posture.kneeLeft", .median),
                                 reduce(readings, "posture.kneeRight", .median)])

        // Range of movement.
        let foldHip = reduce(readings, "fold.hip", .low)
        let foldKnee = reduce(readings, "fold.knee", .median)
        let reachLeft = reduce(readings, "reach.left", .high)
        let reachRight = reduce(readings, "reach.right", .high)
        let reachMean = mean([reachLeft, reachRight])
        let squatDepth = reduce(readings, "squat.hipHeight", .low)
        let bendLeft = reduce(readings, "bendLeft.tilt", .high)
        let bendRight = reduce(readings, "bendRight.tilt", .high)
        let bendMean = mean([bendLeft, bendRight])

        // Balance, one side at a time.
        let leftBalance = balanceScore(readings, prefix: "balanceLeft")
        let rightBalance = balanceScore(readings, prefix: "balanceRight")

        // Pillars.
        let posture = mean([
            shoulderTilt.map { score($0, best: 0, worst: 12) },
            hipTilt.map { score($0, best: 0, worst: 12) },
            frontLean.map { score($0, best: 0, worst: 10) },
            headTilt.map { score($0, best: 0, worst: 14) },
            sideLean.map { score($0, best: 0, worst: 15) },
        ]) ?? 55

        let foldScore = foldHip.map { score($0, best: 40, worst: 110) } ?? 55
        let bendScore = bendMean.map { score($0, best: 30, worst: 6) } ?? 55
        let flexibility = foldScore * 0.65 + bendScore * 0.35

        let reachScore = reachMean.map { score($0, best: 170, worst: 105) } ?? 55
        let squatScore = squatDepth.map { score($0, best: 0.45, worst: 1.0) } ?? 55
        let mobility = reachScore * 0.5 + squatScore * 0.5

        let balanceScoreValue = mean([leftBalance.score, rightBalance.score]) ?? 55

        let symmetry = (mean([
            BodyScoring.balance(reachLeft, reachRight),
            BodyScoring.balance(leftBalance.score, rightBalance.score),
            BodyScoring.balance(bendLeft, bendRight),
            shoulderTilt.map { 1 - Swift.min(1, $0 / 12) },
            hipTilt.map { 1 - Swift.min(1, $0 / 12) },
        ]) ?? 0.7) * 100

        let breakdown = BodyScoreBreakdown(posture: posture, flexibility: flexibility,
                                           balance: balanceScoreValue, mobility: mobility)

        // Measurements worth showing on their own.
        var measurements: [ScanMeasurement] = []
        if let foldHip {
            measurements.append(ScanMeasurement(
                id: "fold", title: "Forward fold", value: foldHip, unit: "deg",
                score: foldScore, insight: foldInsight(foldHip, knee: foldKnee)))
        }
        if let reachMean {
            measurements.append(ScanMeasurement(
                id: "reach", title: "Overhead reach", value: reachMean, unit: "deg",
                score: reachScore, insight: reachInsight(reachMean),
                left: reachLeft, right: reachRight))
        }
        if let squatDepth {
            measurements.append(ScanMeasurement(
                id: "squat", title: "Squat depth", value: squatDepth, unit: "torso",
                score: squatScore, insight: squatInsight(squatDepth)))
        }
        if let bendMean {
            measurements.append(ScanMeasurement(
                id: "bend", title: "Side bend", value: bendMean, unit: "deg",
                score: bendScore, insight: bendInsight(bendMean, left: bendLeft, right: bendRight),
                left: bendLeft, right: bendRight))
        }
        measurements.append(ScanMeasurement(
            id: "balance", title: "One-leg hold", value: mean([leftBalance.seconds, rightBalance.seconds]) ?? 0,
            unit: "s", score: balanceScoreValue,
            insight: balanceInsight(left: leftBalance, right: rightBalance),
            left: leftBalance.seconds, right: rightBalance.seconds))
        if let shoulderTilt {
            measurements.append(ScanMeasurement(
                id: "shoulder-level", title: "Shoulder level", value: shoulderTilt, unit: "deg",
                score: score(shoulderTilt, best: 0, worst: 12),
                insight: levelInsight(shoulderTilt, part: "shoulders")))
        }
        if let hipTilt {
            measurements.append(ScanMeasurement(
                id: "hip-level", title: "Hip level", value: hipTilt, unit: "deg",
                score: score(hipTilt, best: 0, worst: 12),
                insight: levelInsight(hipTilt, part: "hips")))
        }
        if let sideLean {
            measurements.append(ScanMeasurement(
                id: "lean", title: "Standing lean", value: sideLean, unit: "deg",
                score: score(sideLean, best: 0, worst: 15),
                insight: leanInsight(sideLean)))
        }
        if let standingKnee {
            measurements.append(ScanMeasurement(
                id: "knees", title: "Standing knees", value: standingKnee, unit: "deg",
                score: score(standingKnee, best: 178, worst: 150),
                insight: standingKnee < 168
                    ? "Your knees stay a little bent when you stand. Soft knees are fine, but strong legs stack better."
                    : "Your legs stack straight underneath you when you stand."))
        }

        // Areas the practice plan can work on.
        let areas: [AreaScore] = [
            AreaScore(area: .hamstrings, score: foldScore, insight: foldInsight(foldHip ?? 90, knee: foldKnee)),
            AreaScore(area: .hips, score: squatScore, insight: squatInsight(squatDepth ?? 0.8)),
            AreaScore(area: .shoulders, score: reachScore, insight: reachInsight(reachMean ?? 140)),
            AreaScore(area: .spine, score: bendScore * 0.7 + (sideLean.map { score($0, best: 0, worst: 15) } ?? 55) * 0.3,
                      insight: bendInsight(bendMean ?? 18, left: bendLeft, right: bendRight)),
            AreaScore(area: .balance, score: balanceScoreValue,
                      insight: balanceInsight(left: leftBalance, right: rightBalance)),
            AreaScore(area: .alignment, score: posture,
                      insight: alignmentInsight(shoulder: shoulderTilt, hip: hipTilt, head: headTilt)),
        ]

        return ScanOutcome(
            overallScore: breakdown.overall.rounded(),
            postureScore: posture.rounded(),
            flexibilityScore: flexibility.rounded(),
            balanceScore: balanceScoreValue.rounded(),
            mobilityScore: mobility.rounded(),
            symmetryScore: symmetry.rounded(),
            measurements: measurements,
            areas: areas
        )
    }

    struct BalanceSide {
        var score: Double
        var seconds: Double
        var steadiness: Double
    }

    private static func balanceScore(_ readings: [String: [Double]], prefix: String) -> BalanceSide {
        let held = fraction(readings, "\(prefix).lift", atLeast: 0.25) ?? 0
        let steady = reduce(readings, "\(prefix).steadiness", .median) ?? 0.5
        let stepSeconds = ScanStep.all.first { $0.capture.rawValue == prefix }?.seconds ?? 8
        let value = (held * 0.55 + steady * 0.45) * 100
        return BalanceSide(score: value, seconds: (held * stepSeconds * 10).rounded() / 10, steadiness: steady)
    }

    // MARK: - Insights

    private static func foldInsight(_ hip: Double, knee: Double?) -> String {
        let bentKnees = (knee ?? 180) < 155
        switch hip {
        case ..<55:
            return bentKnees
                ? "A deep fold, though your knees bend to get there. Work toward the same depth with longer legs."
                : "A deep fold with straight legs. Your hamstrings and low back move freely."
        case 55..<80:
            return "A solid everyday fold. Hold it longer rather than pulling harder and it will keep opening."
        case 80..<100:
            return "Your fold stops around hip height. Tight hamstrings are the usual reason, and they answer to patience."
        default:
            return "Folding is where your body says no first. Start with bent knees and a flat back, and let it come."
        }
    }

    private static func reachInsight(_ angle: Double) -> String {
        switch angle {
        case 165...:
            return "Your arms travel all the way overhead. Shoulders are open."
        case 145..<165:
            return "Your arms get most of the way up. A little more and you will stack them over your ears."
        case 120..<145:
            return "Your arms stop short of overhead, which usually means a tight chest and lats."
        default:
            return "Overhead is a long way off right now. Downward dog and cobra will chip away at it."
        }
    }

    private static func squatInsight(_ depth: Double) -> String {
        switch depth {
        case ..<0.55:
            return "You sink into a deep squat. Hips and ankles are both doing their job."
        case 0.55..<0.75:
            return "A good working squat. The next bit of depth usually comes from the ankles."
        case 0.75..<0.9:
            return "Your squat stops around halfway. Tight ankles or hips are holding the brake."
        default:
            return "Squatting low is hard for you today. Goddess and low lunge open exactly what is stuck."
        }
    }

    private static func bendInsight(_ tilt: Double, left: Double?, right: Double?) -> String {
        if let left, let right, abs(left - right) > 8 {
            let easier = left > right ? "left" : "right"
            return "You bend noticeably further to the \(easier). A one-sided spine is worth evening out."
        }
        switch tilt {
        case 26...:
            return "Your spine bends generously to both sides."
        case 16..<26:
            return "A decent side bend. Triangle will keep opening it."
        default:
            return "Your spine has little sideways range right now. Go gently and often."
        }
    }

    private static func balanceInsight(left: BalanceSide, right: BalanceSide) -> String {
        if abs(left.score - right.score) > 18 {
            let weaker = left.score < right.score ? "left" : "right"
            return "You balance noticeably better on one side. Your \(weaker) leg needs the extra practice."
        }
        switch Swift.max(left.score, right.score) {
        case 80...:
            return "You hold one leg steadily on both sides. Tree and warrior III will feel welcoming."
        case 55..<80:
            return "Your balance is finding itself. A few seconds longer each week is the whole trick."
        default:
            return "One-leg balance is wobbly right now. Practise beside a wall until it settles."
        }
    }

    private static func levelInsight(_ tilt: Double, part: String) -> String {
        switch tilt {
        case ..<3:
            return "Your \(part) sit level."
        case 3..<7:
            return "Your \(part) are very slightly uneven, which is normal in most bodies."
        default:
            return "Your \(part) sit noticeably uneven at rest. Worth watching across a few scans before reading anything into it."
        }
    }

    private static func leanInsight(_ lean: Double) -> String {
        lean < 6
            ? "Seen from the side you stand nicely stacked."
            : "Seen from the side you lean forward a little. Plank and locust build the back that holds you up."
    }

    private static func alignmentInsight(shoulder: Double?, hip: Double?, head: Double?) -> String {
        let worst = [("shoulders", shoulder), ("hips", hip), ("head", head)]
            .compactMap { name, value in value.map { (name, $0) } }
            .max { $0.1 < $1.1 }
        guard let worst, worst.1 > 5 else {
            return "You stand square and level. That is the base every pose is built on."
        }
        return "Your \(worst.0) are the least level part of your standing posture, by about \(Int(worst.1.rounded())) degrees."
    }
}
