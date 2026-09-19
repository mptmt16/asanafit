import SwiftData
import SwiftUI

struct AsanaDetailView: View {
    let asana: Asana

    @Query private var sessions: [PracticeSession]
    @AppStorage(SettingsKey.favouriteAsanas) private var favouritesRaw = ""
    @AppStorage(SettingsKey.breathSeconds) private var breathSeconds = BreathPacer.defaultBreathSeconds
    @State private var practising = false

    private var isFavourite: Bool { favouritesRaw.settingsList.contains(asana.id) }
    private var breaths: Int { Progression.breaths(for: asana.id, in: sessions) }
    private var mastery: Progression.Mastery { Progression.mastery(breaths: breaths) }
    private var best: PracticeSession? {
        sessions.filter { $0.asanaID == asana.id }.max { $0.score < $1.score }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PoseDemoCard(asana: asana)
                summary
                if let caution = asana.caution {
                    Label(caution, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(Theme.warm)
                        .card()
                }
                steps
                checks
                masteryCard
                Button {
                    practising = true
                } label: {
                    Label("Practise this pose", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: asana.category.color))
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(asana.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavourite()
                } label: {
                    Image(systemName: isFavourite ? "star.fill" : "star")
                        .foregroundStyle(isFavourite ? Theme.warm : Color.secondary)
                }
            }
        }
        .fullScreenCover(isPresented: $practising) {
            PracticeSessionView(items: [asana].practiceItems, title: asana.name)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(asana.sanskrit)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(asana.category.color)
            Text(asana.summary)
            Divider().overlay(Color.white.opacity(0.1))
            Label(asana.benefits, systemImage: "heart.text.square")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                LevelBadge(level: asana.level)
                Label("\(asana.holdBreaths) breaths", systemImage: "wind")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if asana.twoSided {
                    Label("Both sides", systemImage: "arrow.left.arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(asana.duration(breathSeconds: breathSeconds).clockString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How to get there", subtitle: nil)
            ForEach(asana.steps.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 22, height: 22)
                        .background(asana.category.color.opacity(0.2), in: Circle())
                    Text(asana.steps[index])
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .card()
    }

    private var checks: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What the camera checks",
                          subtitle: "Measured live while you hold the shape.")
            ForEach(asana.requirements.indices, id: \.self) { index in
                let requirement = asana.requirements[index]
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(asana.category.color)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(requirement.cue).font(.subheadline)
                        Text("\(requirement.signal.name), \(requirement.targetDescription)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .card()
    }

    private var masteryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Your history", subtitle: nil)
                Spacer()
                MasteryStars(mastery: mastery)
            }
            HStack(spacing: 12) {
                StatTile(title: "Breaths held", value: "\(breaths)", symbol: "wind")
                StatTile(title: "Best score", value: best.map { "\(Int($0.score))" } ?? "-",
                         symbol: "trophy", color: Theme.warm)
            }
            if let next = Progression.breathsToNextStar(breaths: breaths) {
                Text("\(next) more breaths for the next star.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Gold mastery. This shape is yours.")
                    .font(.caption)
                    .foregroundStyle(Theme.warm)
            }
        }
        .card()
    }

    private func toggleFavourite() {
        var current = Set(favouritesRaw.settingsList)
        if current.contains(asana.id) { current.remove(asana.id) } else { current.insert(asana.id) }
        favouritesRaw = current.sorted().joined(separator: ",")
    }
}
