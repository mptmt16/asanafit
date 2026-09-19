import SwiftData
import SwiftUI
import UIKit

/// Stand on one foot for as long as you can, then the other. One of the most useful
/// single measurements there is, and it answers quickly to practice.
struct BalanceTestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.voiceCoach) private var voiceCoach = true
    @AppStorage(SettingsKey.haptics) private var haptics = true

    @State private var tracker = BodyTracker()
    @State private var engine = BalanceTestEngine()
    @State private var coach: Coach?
    @State private var started = false
    @State private var saved: BalanceCheck?

    var body: some View {
        ZStack {
            if let saved {
                resultView(saved)
            } else if !started {
                intro
            } else {
                BodyCameraView(tracker: tracker, showSkeleton: true)
                    .ignoresSafeArea()
                LinearGradient(colors: [.black.opacity(0.7), .clear, .black.opacity(0.85)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                overlay
            }
        }
        .background(Color.black)
        .statusBarHidden(started && saved == nil)
        .onDisappear(perform: tearDown)
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(spacing: 18) {
            Image(systemName: "figure.yoga")
                .font(.system(size: 56))
                .foregroundStyle(Theme.secondary)
            Text("Balance test").font(.largeTitle.bold())
            Text("Stand on your left foot for as long as you can, up to \(Int(BalanceTestEngine.targetSeconds)) seconds, then do the same on your right. The test ends a side when your foot comes down and stays down.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Label("Stand near a wall. Touching it ends the side, so it is there for safety, not for help.",
                  systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundStyle(Theme.warm)
                .padding(.horizontal)
            Button("Start test") { begin() }
                .buttonStyle(PrimaryButtonStyle(color: Theme.secondary))
                .padding(.horizontal)
            Button("Not now") { dismiss() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Testing

    private var overlay: some View {
        VStack {
            HStack {
                Button { stopEarly() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            Spacer()
            centre
            Spacer()

            Text(instruction)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
        }
    }

    @ViewBuilder
    private var centre: some View {
        switch engine.phase {
        case .framing:
            Text(engine.framing.message)
                .font(.title3.bold())
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        case .ready, .swapping:
            VStack(spacing: 4) {
                Text("\(engine.countdown)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("get ready").font(.caption).foregroundStyle(.secondary)
            }
        case .holding:
            ZStack {
                ProgressRing(progress: engine.heldSeconds / BalanceTestEngine.targetSeconds,
                             lineWidth: 10, color: engine.isFootUp ? Theme.secondary : Theme.warm)
                VStack(spacing: 0) {
                    Text("\(Int(engine.heldSeconds))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("seconds").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)
        case .finished:
            ProgressView().tint(.white)
        }
    }

    private var instruction: String {
        switch engine.phase {
        case .framing: return "Step back so the camera can see all of you"
        case .ready(let side), .holding(let side):
            return side == .left ? "Stand on your left foot" : "Stand on your right foot"
        case .swapping: return "Swap to your right foot"
        case .finished: return "Done"
        }
    }

    // MARK: - Result

    private func resultView(_ check: BalanceCheck) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                ScoreGauge(score: check.score, title: "Balance score", size: 120, lineWidth: 12)
                    .padding(.top, 30)
                HStack(spacing: 12) {
                    StatTile(title: "Left foot", value: "\(Int(check.leftSeconds))s",
                             symbol: "arrow.left", color: Theme.secondary)
                    StatTile(title: "Right foot", value: "\(Int(check.rightSeconds))s",
                             symbol: "arrow.right", color: Theme.secondary)
                    StatTile(title: "Even", value: "\(Int((check.result.balance * 100).rounded()))%",
                             symbol: "equal", color: Theme.accent)
                }
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "What this means", subtitle: nil)
                    ForEach(check.advice.indices, id: \.self) { index in
                        Label(check.advice[index], systemImage: "leaf")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .card()
                Button("Done") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.secondary))
            }
            .padding()
            .padding(.bottom, 30)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Flow

    private func begin() {
        started = true
        UIApplication.shared.isIdleTimerDisabled = true
        coach = Coach(voiceEnabled: voiceCoach, hapticsEnabled: haptics)
        engine.onEvent = { message in
            coach?.tap()
            coach?.say(message)
        }
        tracker.onSample = { sample in
            engine.handle(sample)
            if engine.phase == .finished, saved == nil {
                save()
            }
        }
        tracker.simulatedTarget = AsanaLibrary.asana(id: "tree")?.figure ?? .mountain
        tracker.start()
        coach?.say("Balance test. Step back so the camera can see all of you.")
    }

    private func stopEarly() {
        engine.stop()
        if engine.result != nil {
            save()
        } else {
            dismiss()
        }
    }

    private func save() {
        guard let result = engine.result, saved == nil else { return }
        tracker.stop()
        let check = BalanceCheck(result: result)
        modelContext.insert(check)
        try? modelContext.save()
        saved = check
        coach?.success()
    }

    private func tearDown() {
        UIApplication.shared.isIdleTimerDisabled = false
        tracker.onSample = nil
        engine.onEvent = nil
        tracker.stop()
        coach?.finish()
    }
}
