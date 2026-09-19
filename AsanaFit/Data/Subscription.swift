import Foundation
import Observation

/// One of the plans shown on the paywall.
///
/// Prices are hard-coded display strings. In a shipping build every one of these comes from
/// StoreKit's `Product`, localised and priced per storefront, and must never be typed by hand.
struct SubscriptionPlan: Identifiable, Hashable {
    let id: String
    let name: String
    let price: String
    let period: String
    /// The small print under the price, e.g. what it works out to per month.
    let note: String?
    let isBestValue: Bool

    static let all: [SubscriptionPlan] = [
        SubscriptionPlan(id: "monthly", name: "Monthly", price: "$4.99", period: "per month",
                         note: "Cancel any time", isBestValue: false),
        SubscriptionPlan(id: "annual", name: "Yearly", price: "$29.99", period: "per year",
                         note: "Works out at $2.50 a month", isBestValue: true),
        SubscriptionPlan(id: "lifetime", name: "Lifetime", price: "$79.99", period: "once",
                         note: "One payment, yours for good", isBestValue: false),
    ]

    static func plan(id: String) -> SubscriptionPlan? {
        all.first { $0.id == id }
    }
}

/// What Pro would unlock. Written out here so the paywall copy and any future gating
/// read from one list rather than drifting apart.
enum ProFeature: String, CaseIterable, Identifiable {
    case allPoses, unlimitedScans, plan, history, flows, noLimits

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allPoses: return "Every asana and flow"
        case .unlimitedScans: return "Unlimited body scans"
        case .plan: return "A practice plan built from your scan"
        case .history: return "Full history and before & after"
        case .flows: return "All eight flows, including advanced"
        case .noLimits: return "No limits, no adverts, nothing recorded"
        }
    }

    var symbol: String {
        switch self {
        case .allPoses: return "figure.yoga"
        case .unlimitedScans: return "figure.stand.line.dotted.figure.stand"
        case .plan: return "sparkles"
        case .history: return "chart.line.uptrend.xyaxis"
        case .flows: return "list.bullet.rectangle"
        case .noLimits: return "lock.shield"
        }
    }
}

/// Holds whether Pro is active.
///
/// **This is a placeholder.** Nothing here talks to StoreKit, no money moves, and "purchasing"
/// only writes a flag to UserDefaults after a short delay so the loading and success states can
/// be designed. Replacing it means implementing `purchase` and `restore` against StoreKit 2 and
/// verifying the transaction, not editing the views.
@Observable
final class SubscriptionStore {
    static let shared = SubscriptionStore()

    private(set) var isPro: Bool
    private(set) var activePlanID: String?
    private(set) var isWorking = false
    private(set) var lastMessage: String?

    private init() {
        isPro = UserDefaults.standard.bool(forKey: SettingsKey.isPro)
        activePlanID = UserDefaults.standard.string(forKey: SettingsKey.activePlan)
    }

    var activePlan: SubscriptionPlan? {
        activePlanID.flatMap { SubscriptionPlan.plan(id: $0) }
    }

    /// Pretends to buy a plan. Returns once the fake transaction has "completed".
    @MainActor
    func purchase(_ plan: SubscriptionPlan) async {
        guard !isWorking else { return }
        isWorking = true
        lastMessage = nil
        // Long enough to see the spinner, short enough not to be annoying.
        try? await Task.sleep(for: .milliseconds(1200))
        setPro(true, planID: plan.id)
        isWorking = false
        lastMessage = "Pro is on. No payment was taken: this is a development build."
    }

    /// Pretends to restore a previous purchase.
    @MainActor
    func restore() async {
        guard !isWorking else { return }
        isWorking = true
        lastMessage = nil
        try? await Task.sleep(for: .milliseconds(900))
        isWorking = false
        lastMessage = isPro
            ? "Restored. Pro is already on."
            : "Nothing to restore. In a real build this would ask the App Store."
    }

    /// Flips Pro directly, for the Developer section in Settings.
    func setPro(_ on: Bool, planID: String? = nil) {
        isPro = on
        activePlanID = on ? (planID ?? activePlanID ?? "annual") : nil
        UserDefaults.standard.set(on, forKey: SettingsKey.isPro)
        UserDefaults.standard.set(activePlanID, forKey: SettingsKey.activePlan)
    }

    /// Whether a feature should be withheld right now.
    ///
    /// Nothing is gated during development, so this is the one place to start enforcing when
    /// the real paywall goes in: return `!isPro` and every call site follows.
    func isLocked(_ feature: ProFeature) -> Bool {
        false
    }
}
