import SwiftData
import SwiftUI

struct ProfileView: View {
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @Query(sort: \BodyScan.date, order: .reverse) private var scans: [BodyScan]
    @Query(sort: \BalanceCheck.date, order: .reverse) private var balances: [BalanceCheck]
    @Query private var breathSessions: [BreathSession]

    @AppStorage(SettingsKey.profileName) private var name = ""
    @AppStorage(SettingsKey.profileAge) private var age = 0
    @AppStorage(SettingsKey.sleepHours) private var sleepHours = 0.0
    @AppStorage(SettingsKey.sittingHours) private var sittingHours = 0.0
    @AppStorage(SettingsKey.waterGlasses) private var waterGlasses = 0

    private let store = SubscriptionStore.shared
    @State private var showingPaywall = false

    private var progress: Progression.LevelProgress {
        Progression.progress(forXP: Progression.totalXP(sessions: sessions, scans: scans,
                                                        balances: balances, breaths: breathSessions))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Theme.accent.opacity(0.18)).frame(width: 60, height: 60)
                            Text("\(progress.level)")
                                .font(.title2.bold())
                                .foregroundStyle(Theme.accent)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(name.isEmpty ? "Your practice" : name).font(.headline)
                            Text(Progression.rank(forLevel: progress.level))
                                .font(.caption).foregroundStyle(.secondary)
                            Text("\(progress.xp) XP")
                                .font(.caption.monospacedDigit()).foregroundStyle(Theme.warm)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: store.isPro ? "checkmark.seal.fill" : "sparkles")
                                .foregroundStyle(store.isPro ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.warm)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(store.isPro ? "AsanaFit Pro is on" : "Get AsanaFit Pro")
                                    .foregroundStyle(.primary)
                                Text(store.activePlan.map { "\($0.name) plan" }
                                     ?? "The whole library and your own practice plan")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("About you") {
                    TextField("Name", text: $name)
                    Stepper(value: $age, in: 0...120) {
                        HStack {
                            Text("Age")
                            Spacer()
                            Text(age == 0 ? "Not set" : "\(age)")
                                .foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                }

                Section {
                    slider(title: "Sleep last night", value: $sleepHours, range: 0...12, unit: "h")
                    slider(title: "Hours sitting today", value: $sittingHours, range: 0...16, unit: "h")
                    Stepper(value: $waterGlasses, in: 0...20) {
                        HStack {
                            Text("Glasses of water")
                            Spacer()
                            Text("\(waterGlasses)").foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                } header: {
                    Text("Today's habits")
                } footer: {
                    Text("Used only to pick the tip on the Today screen. It never leaves your phone.")
                }

                Section("Totals") {
                    total("Day streak", "\(sessions.streak)")
                    total("Best streak", "\(sessions.bestStreak)")
                    total("Poses held", "\(sessions.count)")
                    total("Breaths held", "\(sessions.totalBreaths)")
                    total("Minutes on the mat", "\(sessions.totalMinutes)")
                    total("Asanas tried", "\(sessions.distinctAsanas) of \(AsanaLibrary.all.count)")
                    total("Body scans", "\(scans.count)")
                    total("Breathing practices", "\(breathSessions.count)")
                }

                if !scans.isEmpty {
                    Section("Scans") {
                        ForEach(scans) { scan in
                            NavigationLink {
                                ScanResultView(scan: scan)
                            } label: {
                                HStack {
                                    Text(scan.date.formatted(date: .abbreviated, time: .shortened))
                                    Spacer()
                                    Text("\(Int(scan.overallScore))")
                                        .font(.subheadline.bold().monospacedDigit())
                                        .foregroundStyle(Theme.color(forScore: scan.overallScore))
                                }
                            }
                        }
                        if scans.count > 1 {
                            NavigationLink("Before & after") { CompareScansView() }
                        }
                    }
                }

                Section {
                    NavigationLink("Badges") { AchievementsView() }
                    NavigationLink("Journey") { JourneyView() }
                    NavigationLink("Settings") { SettingsView() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("You")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }

    private func slider(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue == 0 ? "Not set" : "\(value.wrappedValue.trimmedString)\(unit)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: 0.5).tint(Theme.accent)
        }
    }

    private func total(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).monospacedDigit()
        }
    }
}
