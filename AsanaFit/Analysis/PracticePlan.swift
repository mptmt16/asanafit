import Foundation

/// What to practise today: the areas with the most room to grow, and the poses that train them.
///
/// It works from your goals alone before your first scan, and gets sharper once a scan exists.
struct PracticePlan {
    struct Item: Identifiable {
        let area: BodyArea
        let score: Double?
        let asanas: [Asana]
        let isGoal: Bool

        var id: String { area.rawValue }
    }

    var items: [Item]
    var closing: Asana?
    var isFromScan: Bool

    var asanaIDs: [String] {
        var ids = items.flatMap { $0.asanas.map(\.id) }
        if let closing { ids.append(closing.id) }
        return ids
    }

    var asanas: [Asana] {
        AsanaLibrary.asanas(ids: asanaIDs)
    }

    var summary: String {
        let names = items.map { $0.area.title }
        guard !names.isEmpty else { return "A short, balanced practice." }
        let list = names.count > 1
            ? names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
            : names[0]
        return isFromScan ? "Working on \(list), from your last scan." : "Working on \(list), from your goals."
    }

    var estimatedDuration: TimeInterval {
        asanas.reduce(0) { $0 + $1.estimatedDuration }
    }

    /// Picks three areas: the weakest from your scan, with the goals you chose pushed up the list.
    static func make(scan: BodyScan?, goals: Set<BodyArea>, playerLevel: Int) -> PracticePlan {
        let scores: [BodyArea: Double] = scan.map { saved in
            Dictionary(uniqueKeysWithValues: saved.areas.map { ($0.area, $0.score) })
        } ?? [:]

        let ranked = BodyArea.allCases
            .map { area -> (area: BodyArea, priority: Double, score: Double?) in
                let score = scores[area]
                // Areas with no score sit in the middle, so goals still decide the order.
                let room = 100 - (score ?? 50)
                return (area, room + (goals.contains(area) ? 30 : 0), score)
            }
            .sorted { $0.priority > $1.priority }

        var used: Set<String> = []
        var items: [Item] = []
        for entry in ranked.prefix(3) {
            let asanas = entry.area.asanaIDs
                .compactMap { AsanaLibrary.asana(id: $0) }
                .filter { Progression.isUnlocked($0, playerLevel: playerLevel) && !used.contains($0.id) }
                .prefix(2)
            guard !asanas.isEmpty else { continue }
            used.formUnion(asanas.map(\.id))
            items.append(Item(area: entry.area, score: entry.score,
                              asanas: Array(asanas), isGoal: goals.contains(entry.area)))
        }

        let closing = AsanaLibrary.asana(id: "child").flatMap {
            used.contains($0.id) ? AsanaLibrary.asana(id: "corpse") : $0
        }
        return PracticePlan(items: items, closing: closing, isFromScan: scan != nil)
    }
}
