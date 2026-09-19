import SwiftData
import SwiftUI
import UIKit

/// Pranayama: timed breathing with an expanding circle, a voice cue and a tap at each change.
/// No camera, so it works anywhere, including lying down with your eyes closed.
struct BreathView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.voiceCoach) private var voiceCoach = true
    @AppStorage(SettingsKey.haptics) private var haptics = true
    @AppStorage(SettingsKey.voiceLanguage) private var voiceLanguageRaw = VoiceLanguage.english.rawValue

    @State private var pattern = BreathPattern.all[0]
    @State private var rounds = BreathPattern.all[0].defaultRounds
    @State private var running = false

    private var voice: VoiceLanguage { VoiceLanguage(rawValue: voiceLanguageRaw) ?? .english }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(BreathPattern.all) { option in
                    Button {
                        pattern = option
                        rounds = option.defaultRounds
                    } label: {
                        patternRow(option)
                    }
                    .buttonStyle(.plain)
                }
                stepper
                Button {
                    running = true
                } label: {
                    Label("Start \(pattern.name)", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.secondary))
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Breathe")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $running) {
            BreathRunnerView(pattern: pattern, rounds: rounds, voiceEnabled: voiceCoach,
                             hapticsEnabled: haptics, language: voice) { seconds in
                let session = BreathSession(pattern: pattern, rounds: rounds, seconds: seconds)
                modelContext.insert(session)
                try? modelContext.save()
            }
        }
    }

    private func patternRow(_ option: BreathPattern) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: pattern.id == option.id ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(pattern.id == option.id ? Theme.secondary : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text(option.sanskrit).font(.caption2).foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 0)
                Text(option.duration(rounds: option.defaultRounds).clockString)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(option.summary).font(.caption).foregroundStyle(.secondary)
            Text(option.benefit).font(.caption2).foregroundStyle(.secondary)
        }
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(pattern.id == option.id ? Theme.secondary.opacity(0.6) : .clear, lineWidth: 1.5)
        )
    }

    private var stepper: some View {
        Stepper(value: $rounds, in: 3...40) {
            HStack {
                Text("Rounds").font(.subheadline)
                Spacer()
                Text("\(rounds)  -  \(pattern.duration(rounds: rounds).clockString)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

/// The breathing session itself.
struct BreathRunnerView: View {
    let pattern: BreathPattern
    let rounds: Int
    let voiceEnabled: Bool
    let hapticsEnabled: Bool
    let language: VoiceLanguage
    var onFinish: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startedAt: Date?
    @State private var coach: Coach?
    @State private var lastLabel = ""
    @State private var completedRounds = 0
    @State private var done = false

    private var total: Double { pattern.duration(rounds: rounds) }

    var body: some View {
        ZStack {
            RadialGradient(colors: [Theme.secondary.opacity(0.18), .black],
                           center: .center, startRadius: 40, endRadius: 420)
                .ignoresSafeArea()
            if done {
                finished
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                    let elapsed = startedAt.map { context.date.timeIntervalSince($0) } ?? 0
                    running(elapsed: elapsed)
                        .onChange(of: Int(elapsed * 10)) { _, _ in tick(elapsed) }
                }
            }
            VStack {
                HStack {
                    Button { finish() } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(18)
        }
        .statusBarHidden()
        .onAppear {
            coach = Coach(voiceEnabled: voiceEnabled, hapticsEnabled: hapticsEnabled, language: language)
            startedAt = Date()
            UIApplication.shared.isIdleTimerDisabled = true
            coach?.say(Script.breathIntro(pattern, in: language))
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            coach?.finish()
        }
    }

    private func running(elapsed: Double) -> some View {
        let step = pattern.step(at: elapsed)
        let round = min(rounds, Int(elapsed / max(pattern.roundSeconds, 0.1)) + 1)
        let scale = step.isIn ? 0.55 + 0.45 * step.progress : 1.0 - 0.45 * step.progress
        return VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(Theme.secondary.opacity(0.25), lineWidth: 2)
                    .frame(width: 260, height: 260)
                Circle()
                    .fill(Theme.secondary.opacity(0.35))
                    .frame(width: 260 * scale, height: 260 * scale)
                VStack(spacing: 4) {
                    Text(step.label).font(.title2.bold())
                    Text("\(Int((secondsLeft(step) ).rounded()))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
            Spacer()
            VStack(spacing: 8) {
                Text("Round \(round) of \(rounds)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: min(1, elapsed / total)).tint(Theme.secondary)
                    .padding(.horizontal, 50)
            }
            .padding(.bottom, 40)
        }
    }

    private func secondsLeft(_ step: (label: String, progress: Double, isIn: Bool)) -> Double {
        let length: Double
        switch step.label {
        case "Breathe in": length = pattern.inhale
        case "Breathe out": length = pattern.exhale
        default: length = step.isIn ? pattern.holdIn : pattern.holdOut
        }
        return max(0, length * (1 - step.progress))
    }

    private var finished: some View {
        VStack(spacing: 16) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.secondary)
            Text("\(completedRounds) rounds").font(.largeTitle.bold())
            Text(pattern.name).foregroundStyle(.secondary)
            Label("+20 XP", systemImage: "bolt.fill")
                .font(.caption.bold())
                .foregroundStyle(Theme.warm)
            Button("Done") { dismiss() }
                .buttonStyle(PrimaryButtonStyle(color: Theme.secondary))
                .padding(.horizontal, 40)
                .padding(.top, 10)
        }
    }

    private func tick(_ elapsed: Double) {
        guard !done else { return }
        let step = pattern.step(at: elapsed)
        if step.label != lastLabel {
            lastLabel = step.label
            coach?.tap()
            coach?.say(step.label)
        }
        completedRounds = min(rounds, Int(elapsed / max(pattern.roundSeconds, 0.1)))
        if elapsed >= total {
            finish()
        }
    }

    private func finish() {
        guard !done else { return }
        let elapsed = startedAt.map { Date().timeIntervalSince($0) } ?? 0
        completedRounds = min(rounds, Int(elapsed / max(pattern.roundSeconds, 0.1)))
        done = true
        coach?.success()
        if completedRounds >= 1 {
            onFinish(elapsed)
        } else {
            dismiss()
        }
    }
}
