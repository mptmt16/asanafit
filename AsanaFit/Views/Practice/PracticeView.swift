import SwiftData
import SwiftUI

/// The library: flows, every asana by group, and the breathing practices.
struct PracticeView: View {
    @Query private var sessions: [PracticeSession]
    @Query private var scans: [BodyScan]
    @Query private var balances: [BalanceCheck]
    @Query private var breathSessions: [BreathSession]
    @AppStorage(SettingsKey.favouriteAsanas) private var favouritesRaw = ""

    @State private var search = ""

    private var playerLevel: Int {
        Progression.level(forXP: Progression.totalXP(sessions: sessions, scans: scans,
                                                     balances: balances, breaths: breathSessions))
    }

    private var favourites: Set<String> { Set(favouritesRaw.settingsList) }

    private var matches: [Asana] {
        guard !search.isEmpty else { return AsanaLibrary.all }
        let needle = search.lowercased()
        return AsanaLibrary.all.filter {
            $0.name.lowercased().contains(needle)
                || $0.sanskrit.lowercased().contains(needle)
                || $0.summary.lowercased().contains(needle)
                || $0.category.title.lowercased().contains(needle)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty {
                    flowsSection
                    breathSection
                    if !favourites.isEmpty {
                        section(title: "Favourites",
                                asanas: AsanaLibrary.all.filter { favourites.contains($0.id) })
                    }
                }
                ForEach(AsanaCategory.allCases) { category in
                    let asanas = matches.filter { $0.category == category }
                    if !asanas.isEmpty {
                        section(title: category.title, asanas: asanas, symbol: category.symbol)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .searchable(text: $search, prompt: "Search poses and muscles")
            .navigationTitle("Practice")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        JourneyView()
                    } label: {
                        Image(systemName: "map")
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var flowsSection: some View {
        Section("Flows") {
            ForEach(FlowLibrary.all) { flow in
                let locked = playerLevel < Progression.unlockLevel(forFlow: flow.id)
                NavigationLink {
                    FlowDetailView(flow: flow)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: locked ? "lock.fill" : flow.symbol)
                            .font(.title3)
                            .foregroundStyle(locked ? Color.secondary : flow.color)
                            .frame(width: 44, height: 44)
                            .background((locked ? Color.white : flow.color).opacity(0.15),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(flow.name)
                                .font(.headline)
                                .foregroundStyle(locked ? Color.secondary : Color.primary)
                            if locked {
                                Text("Unlocks at level \(Progression.unlockLevel(forFlow: flow.id))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.warm)
                            } else {
                                Text("\(flow.asanas.count) poses  -  about \(flow.estimatedDuration.clockString)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .disabled(locked)
            }
        }
    }

    private var breathSection: some View {
        Section("Breathing") {
            NavigationLink {
                BreathView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "lungs.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 44, height: 44)
                        .background(Theme.secondary.opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Pranayama").font(.headline)
                        Text("\(BreathPattern.all.count) patterns, no camera needed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func section(title: String, asanas: [Asana], symbol: String? = nil) -> some View {
        Section {
            ForEach(asanas) { asana in
                let locked = !Progression.isUnlocked(asana, playerLevel: playerLevel)
                NavigationLink {
                    AsanaDetailView(asana: asana)
                } label: {
                    AsanaRow(asana: asana,
                             isFavourite: favourites.contains(asana.id),
                             mastery: Progression.mastery(breaths: Progression.breaths(for: asana.id, in: sessions)),
                             isLocked: locked)
                }
                .disabled(locked)
                .swipeActions(edge: .leading) {
                    Button {
                        toggleFavourite(asana.id)
                    } label: {
                        Label(favourites.contains(asana.id) ? "Unstar" : "Star", systemImage: "star")
                    }
                    .tint(Theme.warm)
                }
            }
        } header: {
            if let symbol {
                Label(title, systemImage: symbol)
            } else {
                Text(title)
            }
        }
    }

    private func toggleFavourite(_ id: String) {
        var current = favourites
        if current.contains(id) { current.remove(id) } else { current.insert(id) }
        favouritesRaw = current.sorted().joined(separator: ",")
    }
}
