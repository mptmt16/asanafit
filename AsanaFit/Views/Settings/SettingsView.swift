import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.voiceCoach) private var voiceCoach = true
    @AppStorage(SettingsKey.haptics) private var haptics = true
    @AppStorage(SettingsKey.voiceLanguage) private var voiceLanguageRaw = VoiceLanguage.english.rawValue
    @AppStorage(SettingsKey.showSkeleton) private var showSkeleton = true
    @AppStorage(SettingsKey.showGuide) private var showGuide = true
    @AppStorage(SettingsKey.tolerance) private var tolerance = 1.0
    @AppStorage(SettingsKey.breathSeconds) private var breathSeconds = BreathPacer.defaultBreathSeconds
    @AppStorage(SettingsKey.reminderEnabled) private var reminderEnabled = false
    @AppStorage(SettingsKey.reminderMinutes) private var reminderMinutes = 8 * 60
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = true

    @AppStorage(SettingsKey.unlockEverything) private var unlockEverything = true
    @AppStorage(SettingsKey.showPaywallOnLaunch) private var showPaywallOnLaunch = false

    private let store = SubscriptionStore.shared
    @State private var notificationsDenied = false
    @State private var confirmingReset = false
    @State private var showingPaywall = false

    private var voice: VoiceLanguage { VoiceLanguage(rawValue: voiceLanguageRaw) ?? .english }

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: reminderMinutes / 60,
                                  minute: reminderMinutes % 60, second: 0, of: .now) ?? .now
        } set: { newValue in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderMinutes = (parts.hour ?? 8) * 60 + (parts.minute ?? 0)
            if reminderEnabled {
                ReminderScheduler.schedule(minutesAfterMidnight: reminderMinutes)
            }
        }
    }

    var body: some View {
        Form {
            Section {
                Toggle("Voice coach", isOn: $voiceCoach)
                if voiceCoach {
                    Picker("Voice language", selection: $voiceLanguageRaw) {
                        ForEach(VoiceLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                    if !voice.isAvailable {
                        Label("iOS has no " + voice.displayName + " voice installed. Add one under "
                              + "Settings, Accessibility, Spoken Content, Voices.",
                              systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(Theme.warm)
                    }
                }
                Toggle("Haptics", isOn: $haptics)
            } header: {
                Text("Coaching")
            } footer: {
                Text("The voice language is separate from the app's language: the screens stay in "
                     + "English and only the spoken cues change.")
            }

            Section {
                Toggle("Show skeleton", isOn: $showSkeleton)
                Toggle("Show pose guide", isOn: $showGuide)
            } header: {
                Text("On camera")
            } footer: {
                Text("The pose guide is the faint target shape drawn behind you. Turn it off if it gets in the way.")
            }

            Section {
                Picker("Practice", selection: $tolerance) {
                    Text("Gentle").tag(1.5)
                    Text("Standard").tag(1.0)
                    Text("Precise").tag(0.75)
                }
                .pickerStyle(.segmented)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Seconds per breath")
                        Spacer()
                        Text("\(breathSeconds.trimmedString)s")
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $breathSeconds, in: 3...10, step: 0.5).tint(Theme.accent)
                }
            } header: {
                Text("How hard, how slow")
            } footer: {
                Text("Gentle widens every alignment target. Longer breaths make every hold longer: five breaths at \(breathSeconds.trimmedString) seconds is \(Int(breathSeconds * 5)) seconds in the shape.")
            }

            Section {
                Toggle("Daily reminder", isOn: $reminderEnabled)
                if reminderEnabled {
                    DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                }
                if notificationsDenied {
                    Label("Notifications are turned off for AsanaFit in iOS Settings.",
                          systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(Theme.warm)
                }
            } header: {
                Text("Reminder")
            }

            Section {
                Button("Show the welcome screen again") { hasOnboarded = false }
                Button("Delete all history", role: .destructive) { confirmingReset = true }
            } header: {
                Text("Data")
            } footer: {
                Text("Everything AsanaFit records lives on this phone only. No account, no upload, no camera frames saved.")
            }

            if DevFlags.isDevelopmentBuild {
                developerSection
            }

            Section {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Poses", value: "\(AsanaLibrary.all.count)")
                LabeledContent("Flows", value: "\(FlowLibrary.all.count)")
            } footer: {
                Text("AsanaFit is a wellness tool, not a medical device. It does not diagnose or treat anything. If you are pregnant, recovering from injury, or have a condition affecting your joints, spine or blood pressure, check with a clinician before starting.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: reminderEnabled) { _, isOn in
            Task { await updateReminder(isOn) }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .alert("Delete all history?", isPresented: $confirmingReset) {
            Button("Delete", role: .destructive) { deleteEverything() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every pose, scan, balance test and breathing practice is removed. This cannot be undone.")
        }
    }

    /// Everything in here disappears with `DevFlags.isDevelopmentBuild`.
    private var developerSection: some View {
        Section {
            Toggle("Unlock every pose and flow", isOn: $unlockEverything)
            Toggle("Pro subscription active", isOn: Binding(
                get: { store.isPro },
                set: { store.setPro($0) }
            ))
            Toggle("Show paywall on launch", isOn: $showPaywallOnLaunch)
            Button("Preview the paywall") { showingPaywall = true }
            LabeledContent("Lines without Hindi", value: "\(Speech.untranslated().count)")
        } header: {
            Label("Developer", systemImage: "hammer.fill")
        } footer: {
            Text("Development build only. Unlocking does not touch your XP or level, it only "
                 + "ignores the gates. The paywall is a placeholder and takes no payment. "
                 + "Set DevFlags.isDevelopmentBuild to false to remove all of this.")
        }
    }

    private func updateReminder(_ isOn: Bool) async {
        guard isOn else {
            ReminderScheduler.disable()
            notificationsDenied = false
            return
        }
        let granted = await ReminderScheduler.enable(minutesAfterMidnight: reminderMinutes)
        if !granted {
            reminderEnabled = false
            notificationsDenied = true
        }
    }

    private func deleteEverything() {
        try? modelContext.delete(model: PracticeSession.self)
        try? modelContext.delete(model: BodyScan.self)
        try? modelContext.delete(model: BalanceCheck.self)
        try? modelContext.delete(model: BreathSession.self)
        try? modelContext.save()
    }
}
