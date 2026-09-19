import SwiftUI

/// The subscription screen.
///
/// While `DevFlags.fakePaywall` is on, this takes no payment and says so at the top of the
/// screen. The banner is deliberately not subtle: a purchase flow that looks real but is not
/// should never be mistakable for one that is, least of all by whoever is testing it.
struct PaywallView: View {
    /// Shown when the paywall appears by itself rather than from a locked feature.
    var reason: String?

    @Environment(\.dismiss) private var dismiss
    private let store = SubscriptionStore.shared
    @State private var selected = SubscriptionPlan.all.first { $0.isBestValue } ?? SubscriptionPlan.all[0]
    @State private var showingDone = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.14, green: 0.11, blue: 0.28), .black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if DevFlags.fakePaywall {
                        developmentBanner
                    }
                    header
                    features
                    plans
                    callToAction
                    smallPrint
                }
                .padding(20)
                .padding(.bottom, 30)
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                Spacer()
            }
            .padding(16)
        }
        .alert("Pro is on", isPresented: $showingDone) {
            Button("Done") { dismiss() }
        } message: {
            Text(store.lastMessage ?? "Everything is unlocked.")
        }
    }

    // MARK: - Sections

    private var developmentBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hammer.fill")
                .foregroundStyle(Theme.warm)
            VStack(alignment: .leading, spacing: 2) {
                Text("Development build").font(.caption.bold())
                Text("This paywall is a placeholder. No payment is taken and no card is charged. Tapping the button just switches Pro on locally.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.warm.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.warm.opacity(0.4), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(spacing: 12) {
            PoseFigureView(figure: AsanaLibrary.asana(id: "warrior-two")?.figure ?? .mountain,
                           color: Theme.accent, lineWidth: 5, animated: true, showJoints: true)
                .frame(height: 150)
            Text("AsanaFit Pro").font(.largeTitle.bold())
            Text(reason ?? "The whole library, your own practice plan, and every measurement kept.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if store.isPro {
                Label("Pro is active\(store.activePlan.map { " on the \($0.name.lowercased()) plan" } ?? "")",
                      systemImage: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.55))
            }
        }
        .padding(.top, 20)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(ProFeature.allCases) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.symbol)
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 26)
                    Text(feature.title).font(.subheadline)
                    Spacer(minLength: 0)
                }
            }
        }
        .card()
    }

    private var plans: some View {
        VStack(spacing: 10) {
            ForEach(SubscriptionPlan.all) { plan in
                Button {
                    selected = plan
                } label: {
                    planRow(plan)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func planRow(_ plan: SubscriptionPlan) -> some View {
        let isSelected = selected.id == plan.id
        return HStack(spacing: 14) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Theme.accent : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(plan.name).font(.headline)
                    if plan.isBestValue {
                        Text("best value")
                            .font(.caption2.bold())
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Theme.warm.opacity(0.25), in: Capsule())
                            .foregroundStyle(Theme.warm)
                    }
                }
                if let note = plan.note {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 1) {
                Text(plan.price).font(.headline.monospacedDigit())
                Text(plan.period).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Theme.accent.opacity(0.7) : .clear, lineWidth: 1.5)
        )
    }

    private var callToAction: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await store.purchase(selected)
                    showingDone = store.isPro
                }
            } label: {
                if store.isWorking {
                    ProgressView().tint(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text(store.isPro ? "Switch to \(selected.name)" : "Continue with \(selected.name)")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(store.isWorking)

            Button("Restore purchases") {
                Task { await store.restore() }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .disabled(store.isWorking)

            if let message = store.lastMessage, !showingDone {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.warm)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var smallPrint: some View {
        VStack(spacing: 6) {
            Text(DevFlags.fakePaywall
                 ? "Nothing here is connected to the App Store yet. Prices are placeholders."
                 : "Payment is charged to your Apple Account. Subscriptions renew automatically unless cancelled at least 24 hours before the period ends. Manage them in Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Text("Terms").font(.caption2).foregroundStyle(Theme.accent)
                Text("Privacy").font(.caption2).foregroundStyle(Theme.accent)
            }
        }
        .padding(.top, 4)
    }
}
