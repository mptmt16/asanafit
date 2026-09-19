import SwiftData
import SwiftUI

struct TodayView: View {
    @Binding var selectedTab: AppTab

    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @Query(sort: \BodyScan.date, order: .reverse) private var scans: [BodyScan]
    @Query private var balances: [BalanceCheck]
    @Query private var breathSessions: [BreathSession]

    @AppStorage(SettingsKey.goals) private var goalsRaw = ""
    @AppStorage(SettingsKey.profileName) private var name = ""
    @AppStorage(SettingsKey.sleepHours) private var sleepHours = 0.0
    @AppStorage(SettingsKey.sittingHours) private var sittingHours = 0.0
    @AppStorage(SettingsKey.waterGlasses) private var waterGlasses = 0
    /// Read so the flow row redraws the moment the developer unlock switch changes.
    @AppStorage(SettingsKey.unlockEverything) private var unlockEverything = true

    @State private var practisingPlan = false
    @State private var scanning = false
    @State private var breathing = false

    private var playerLevel: Int { progress.level }

    private var progress: Progression.LevelProgress {
        Progression.progress(forXP: Progression.totalXP(sessions: sessions, scans: scans,
                                                        balances: balances, breaths: breathSessions))
    }

    private var xpToday: Int {
        Progression.xpEarned(on: .now, sessions: sessions, scans: scans,
                             balances: balances, breaths: breathSessions)
    }

    private var goals: Set<BodyArea> {
        Set(goalsRaw.settingsList.compactMap { BodyArea(rawValue: $0) })
    }

    private var plan: PracticePlan {
        PracticePlan.make(scan: scans.first, goals: goals, playerLevel: playerLevel)
    }

    private var quests: [Quest] {
        QuestBoard.today(DayRecord.make(day: .now, sessions: sessions, scans: scans,
                                        balances: balances, breaths: breathSessions))
    }

    private var practisedToday: Bool {
        sessions.contains { Calendar.current.isDateInToday($0.date) }
    }

    private var tip: DailyTip {
        TipEngine.tip(habits: Habits(sleepHours: sleepHours, sittingHours: sittingHours,
                                     waterGlasses: waterGlasses),
                      scan: scans.first, streak: sessions.streak, practisedToday: practisedToday)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    greeting
                    LevelCard(progress: progress, xpToday: xpToday)
                    PlanCard(plan: plan, compact: true) { practisingPlan = true }
                    QuestsCard(quests: quests)
                    quickActions
                    TipCard(tip: tip)
                    flows
                }
                .padding()
                .padding(.bottom, 24)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Today")
            .fullScreenCover(isPresented: $practisingPlan) {
                PracticeSessionView(items: plan.asanas.practiceItems, title: "Today's practice")
            }
            .fullScreenCover(isPresented: $scanning) {
                BodyScanView()
            }
            .sheet(isPresented: $breathing) {
                NavigationStack { BreathView() }
            }
        }
    }

    // MARK: - Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.title2.bold())
            HStack(spacing: 12) {
                Label("\(sessions.streak) day streak", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.warm)
                Label("\(sessions.totalMinutes) min on the mat", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return name.isEmpty ? part : "\(part), \(name)"
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button { scanning = true } label: {
                QuickActionTile(title: "Body scan",
                                detail: scans.isEmpty ? "Nine steps, two minutes" : "Last: \(Int(scans[0].overallScore))",
                                symbol: "figure.stand.line.dotted.figure.stand", color: Theme.accent)
            }
            .buttonStyle(.plain)
            Button { breathing = true } label: {
                QuickActionTile(title: "Breathe", detail: "Pranayama, no camera",
                                symbol: "lungs.fill", color: Theme.secondary)
            }
            .buttonStyle(.plain)
            Button { selectedTab = .practice } label: {
                QuickActionTile(title: "Pose library", detail: "\(AsanaLibrary.all.count) asanas",
                                symbol: "square.grid.2x2", color: Theme.warm)
            }
            .buttonStyle(.plain)
        }
    }

    private var flows: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Flows", subtitle: "Ready-made sequences.")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FlowLibrary.all.filter { Progression.isUnlocked(flowID: $0.id, playerLevel: playerLevel) }) { flow in
                        NavigationLink {
                            FlowDetailView(flow: flow)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: flow.symbol)
                                    .font(.title3)
                                    .foregroundStyle(flow.color)
                                Text(flow.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Text("\(flow.asanas.count) poses")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 130, height: 104, alignment: .topLeading)
                            .padding(14)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
