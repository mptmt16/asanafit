import SwiftData
import SwiftUI

struct FlowDetailView: View {
    let flow: Flow

    @Query private var sessions: [PracticeSession]
    @Query private var scans: [BodyScan]
    @Query private var balances: [BalanceCheck]
    @Query private var breathSessions: [BreathSession]
    @State private var practising = false

    private var playerLevel: Int {
        Progression.level(forXP: Progression.totalXP(sessions: sessions, scans: scans,
                                                     balances: balances, breaths: breathSessions))
    }

    private var asanas: [Asana] { flow.unlockedAsanas(playerLevel: playerLevel) }
    private var lockedCount: Int { flow.asanas.count - asanas.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if lockedCount > 0 {
                    Label("\(lockedCount) pose\(lockedCount == 1 ? "" : "s") in this flow are still locked and will be skipped.",
                          systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(Theme.warm)
                        .card()
                }
                poses
                Button {
                    practising = true
                } label: {
                    Label("Start flow", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: flow.color))
                .disabled(asanas.isEmpty)
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(flow.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $practising) {
            PracticeSessionView(items: asanas.practiceItems, title: flow.name)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: flow.symbol)
                    .font(.title)
                    .foregroundStyle(flow.color)
                    .frame(width: 54, height: 54)
                    .background(flow.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(flow.summary).font(.subheadline)
                    Text("\(asanas.practiceItems.count) holds  -  about \(flow.estimatedDuration.clockString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            LevelBadge(level: flow.level)
        }
        .card()
    }

    private var poses: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "In this flow", subtitle: nil)
            ForEach(flow.asanas.indices, id: \.self) { index in
                let asana = flow.asanas[index]
                let locked = !Progression.isUnlocked(asana, playerLevel: playerLevel)
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.1), in: Circle())
                    PoseFigureView(figure: asana.figure,
                                   color: locked ? .gray : asana.category.color, lineWidth: 2.4)
                        .frame(width: 38, height: 38)
                        .opacity(locked ? 0.4 : 1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(asana.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(locked ? Color.secondary : Color.primary)
                        Text(locked
                             ? "Unlocks at level \(Progression.unlockLevel(for: asana.id))"
                             : "\(asana.holdBreaths) breaths\(asana.twoSided ? ", both sides" : "")")
                            .font(.caption)
                            .foregroundStyle(locked ? Theme.warm : .secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: asana.facing.symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }
}
