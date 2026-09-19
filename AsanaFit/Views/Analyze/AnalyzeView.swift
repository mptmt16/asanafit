import SwiftData
import SwiftUI

/// The hub for everything that measures you rather than coaching you.
struct AnalyzeView: View {
    @Query(sort: \BodyScan.date, order: .reverse) private var scans: [BodyScan]
    @Query(sort: \BalanceCheck.date, order: .reverse) private var balances: [BalanceCheck]
    @AppStorage(SettingsKey.goals) private var goalsRaw = ""

    @State private var scanning = false
    @State private var balanceTesting = false

    private var goals: Set<BodyArea> {
        Set(goalsRaw.settingsList.compactMap { BodyArea(rawValue: $0) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    scanCard
                    balanceCard
                    goalsCard
                    tools
                    if scans.count > 1 {
                        history
                    }
                }
                .padding()
                .padding(.bottom, 24)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Analyse")
            .fullScreenCover(isPresented: $scanning) { BodyScanView() }
            .fullScreenCover(isPresented: $balanceTesting) { BalanceTestView() }
        }
    }

    // MARK: - Cards

    private var scanCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let latest = scans.first {
                NavigationLink {
                    ScanResultView(scan: latest)
                } label: {
                    HStack(spacing: 16) {
                        ScoreGauge(score: latest.overallScore, title: "", size: 76)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(latest.level.title).font(.headline)
                            Text("Scanned \(latest.date.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Focus next: \(latest.breakdown.focus)")
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No scan yet").font(.headline)
                    Text("Nine steps in front of the camera give you a body score, a measurement of each area, and a practice plan built from the result.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                scanning = true
            } label: {
                Label(scans.isEmpty ? "Take your first body scan" : "Take a new scan",
                      systemImage: "figure.stand.line.dotted.figure.stand")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .card()
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "figure.yoga")
                    .font(.title3)
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 38, height: 38)
                    .background(Theme.secondary.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance test").font(.subheadline.weight(.semibold))
                    Text("Stand on one foot for as long as you can, then swap.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if let latest = balances.first {
                    Text("\(Int(latest.score))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Theme.color(forScore: latest.score))
                }
            }
            if let latest = balances.first {
                SideBar(left: min(1, latest.leftSeconds / BalanceTestEngine.targetSeconds),
                        right: min(1, latest.rightSeconds / BalanceTestEngine.targetSeconds),
                        color: Theme.secondary)
                Text("Left \(Int(latest.leftSeconds))s, right \(Int(latest.rightSeconds))s")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Button {
                balanceTesting = true
            } label: {
                Label(balances.isEmpty ? "Run the balance test" : "Test again", systemImage: "timer")
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.secondary))
        }
        .card()
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What you want to work on",
                          subtitle: "Your goals get priority in the practice plan.")
            ForEach(BodyArea.allCases) { area in
                Button {
                    toggleGoal(area)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: goals.contains(area) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(goals.contains(area) ? area.color : Color.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(area.title).font(.subheadline).foregroundStyle(.primary)
                            Text(area.blurb).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .card()
    }

    private var tools: some View {
        VStack(spacing: 12) {
            NavigationLink {
                PoseLabView()
            } label: {
                toolRow(title: "Pose Lab",
                        detail: "Every joint angle the app can read, live.",
                        symbol: "waveform.path.ecg", color: Theme.accent)
            }
            .buttonStyle(.plain)
            if scans.count > 1 {
                NavigationLink {
                    CompareScansView()
                } label: {
                    toolRow(title: "Before & after",
                            detail: "Put two scans side by side.",
                            symbol: "rectangle.split.2x1", color: Theme.warm)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toolRow(title: String, detail: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }
        .card()
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Scan history", subtitle: nil)
            ForEach(scans) { scan in
                NavigationLink {
                    ScanResultView(scan: scan)
                } label: {
                    HStack(spacing: 12) {
                        Text("\(Int(scan.overallScore))")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Theme.color(forScore: scan.overallScore))
                            .frame(width: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(scan.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text(scan.level.title).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .card()
    }

    private func toggleGoal(_ area: BodyArea) {
        var current = goals
        if current.contains(area) { current.remove(area) } else { current.insert(area) }
        goalsRaw = current.map(\.rawValue).sorted().joined(separator: ",")
    }
}
