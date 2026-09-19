import Foundation

/// Switches that exist only while the app is being built.
///
/// They live in UserDefaults rather than in code so they can be flipped on a device without a
/// rebuild, and the logic reads them through here rather than scattering checks through the views.
///
/// **Before any build that goes to real users:** set `unlockEverything` and `fakePaywall` to
/// false, and delete the Developer section from Settings. `DevFlags.isDevelopmentBuild` is the
/// single switch that hides all of it.
enum DevFlags {
    /// The master switch. Everything else in this file only applies while it is true.
    static let isDevelopmentBuild = true

    /// Every asana and flow available from level 1, so screens can be reviewed
    /// without grinding XP first. Progress, XP and levels still accumulate normally.
    static var unlockEverything: Bool {
        get { flag(SettingsKey.unlockEverything, default: true) }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKey.unlockEverything) }
    }

    /// The paywall is a placeholder: it takes no payment and charges no card.
    /// It says so on screen, so it can never be mistaken for the real thing.
    static var fakePaywall: Bool { isDevelopmentBuild }

    /// Show the paywall once on launch, for testing the first-run flow.
    static var showPaywallOnLaunch: Bool {
        get { flag(SettingsKey.showPaywallOnLaunch, default: false) }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKey.showPaywallOnLaunch) }
    }

    /// Reads a flag that has never been written, without the usual `false` default of `bool(forKey:)`.
    private static func flag(_ key: String, default fallback: Bool) -> Bool {
        guard isDevelopmentBuild else { return false }
        return UserDefaults.standard.object(forKey: key) as? Bool ?? fallback
    }
}
