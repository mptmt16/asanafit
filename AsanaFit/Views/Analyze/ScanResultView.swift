import SwiftData
import SwiftUI

struct ScanResultView: View {
    let scan: BodyScan
    var isNew = false
    var onDone: (() -> Void)?

    @Query(sort: \BodyScan.date, order: .reverse) private var scans: [BodyScan]
    @Query private var sessions: [PracticeSession]
    @Query private var balances: [BalanceCheck]
    @Query private var breathSessions: [BreathSession]
    @AppStorage(SettingsKey.goals) private var goalsRaw = ""
    @State private var practising = false

    private var previous: BodyScan? {
        scans.first { $0.date < scan.date }
    }

    private var goals: Set<BodyArea> {
        Set(goalsRaw.settingsList.compactMap { BodyArea(rawValue: $0) })
    }

    private var playerLevel: Int {
        Progression.level(forXP: Progression.totalXP(sessions: sessions, scans: scans,
                                                     balances: balances, breaths: breathSessions))
    }

    private var plan: PracticePlan {
        PracticePlan.make(scan: scan, goals: goals, playerLevel: playerLevel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isNew {
                    Label("+\(Progression.xp(for: scan)) XP", systemImage: "bolt.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.warm)
                }
                BodyScoreCard(scan: scan, previous: previous)
                PlanCard(plan: plan) { practising = true }

                SectionHeader(title: "Your areas", subtitle: "Weakest first, which is where the plan starts.")
                ForEach(scan.areas.sorted { $0.score < $1.score }) { area in
                    AreaCard(area: area, isGoal: goals.contains(area.area), playerLevel: playerLevel)
                }

                SectionHeader(title: "Measurements", subtitle: "What the camera actually read.")
                ForEach(scan.measurements) { measurement in
                    MeasurementCard(measurement: measurement)
                }

                symmetryCard

                if let onDone {
                    Button("Done", action: onDone)
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 4)
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(scan.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $practising) {
            PracticeSessionView(items: plan.asanas.practiceItems, title: "Your practice")
        }
    }

    private var symmetryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Left and right").font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(scan.symmetryScore))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.color(forScore: scan.symmetryScore))
            }
            ProgressView(value: scan.symmetryScore / 100)
                .tint(Theme.color(forScore: scan.symmetryScore))
            Text(scan.symmetryScore >= 85
                 ? "Your two sides move and sit very alike. Keep practising both sides evenly."
                 : "Your two sides differ enough to notice. Practise the weaker side twice for every once on the other, and watch this number across scans rather than reading too much into one.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}
