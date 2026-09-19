import SwiftData
import SwiftUI

@main
struct AsanaFitApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(for: [PracticeSession.self, BodyScan.self, BalanceCheck.self, BreathSession.self])
    }
}

enum SettingsKey {
    static let voiceCoach = "voiceCoach"
    static let haptics = "haptics"
    static let showSkeleton = "showSkeleton"
    /// Draw the target shape faintly behind you during a pose.
    static let showGuide = "showGuide"
    /// Above 1 is a gentler practice, below 1 a stricter one.
    static let tolerance = "tolerance"
    /// Seconds per breath, which sets how long every hold lasts.
    static let breathSeconds = "breathSeconds"
    static let hasOnboarded = "hasOnboarded"
    static let reminderEnabled = "reminderEnabled"
    /// Reminder time as minutes after midnight.
    static let reminderMinutes = "reminderMinutes"
    /// Comma-separated BodyArea raw values.
    static let goals = "goals"
    /// Comma-separated asana ids.
    static let favouriteAsanas = "favouriteAsanas"
    static let profileName = "profileName"
    static let profileAge = "profileAge"
    static let sleepHours = "sleepHours"
    static let sittingHours = "sittingHours"
    static let waterGlasses = "waterGlasses"
}

extension String {
    /// Reads a comma-separated settings value as a list.
    var settingsList: [String] {
        split(separator: ",").map(String.init).filter { !$0.isEmpty }
    }
}
