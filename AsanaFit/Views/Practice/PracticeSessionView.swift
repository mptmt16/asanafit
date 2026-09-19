import SwiftData
import SwiftUI
import UIKit

/// One asana on one side: the unit a practice queue is made of.
struct PracticeItem: Identifiable, Hashable {
    let asana: Asana
    let side: Side

    var id: String { "\(asana.id)-\(side.rawValue)" }
    var staged: Asana { asana.forSide(side) }
}

extension Array where Element == Asana {
    /// Expands two-sided poses into a left side and a right side.
    var practiceItems: [PracticeItem] {
        flatMap { asana -> [PracticeItem] in
            asana.twoSided
                ? [PracticeItem(asana: asana, side: .left), PracticeItem(asana: asana, side: .right)]
                : [PracticeItem(asana: asana, side: .none)]
        }
    }
}

/// Runs a practice: camera, live alignment coaching, breath-paced holds, then a summary.
struct PracticeSessionView: View {
    let items: [PracticeItem]
    var title: String = "Practice"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.voiceCoach) private var voiceCoach = true
    @AppStorage(SettingsKey.haptics) private var haptics = true
    @AppStorage(SettingsKey.voiceLanguage) private var voiceLanguageRaw = VoiceLanguage.english.rawValue
    @AppStorage(SettingsKey.showSkeleton) private var showSkeleton = true
    @AppStorage(SettingsKey.showGuide) private var showGuide = true
    @AppStorage(SettingsKey.tolerance) private var tolerance = 1.0
    @AppStorage(SettingsKey.breathSeconds) private var breathSeconds = BreathPacer.defaultBreathSeconds

    @State private var tracker = BodyTracker()
    @State private var engine: AsanaEngine?
    @State private var coach: Coach?
    @State private var index = 0
    @State private var results: [AsanaResult] = []
    @State private var betweenPoses = false
    @State private var showingSummary = false
    /// Marks where this practice starts in history, so the summary can tell what is new.
    @State private var startedAt = Date()

    var body: some View {
        ZStack {
            if showingSummary {
                SessionSummaryView(results: results, title: title, startedAt: startedAt) { dismiss() }
            } else {
                BodyCameraView(tracker: tracker,
                               showSkeleton: showSkeleton,
                               ghost: showGuide ? current?.staged.stickFigure : nil,
                               attention: engine?.attention ?? [])
                    .ignoresSafeArea()
                scrims
                if let engine {
                    SessionHUD(engine: engine,
                               poseNumber: index + 1,
                               poseCount: items.count,
                               isSimulated: tracker.isSimulated,
                               permissionDenied: tracker.permissionDenied,
                               showSkeleton: $showSkeleton,
                               showGuide: $showGuide,
                               onSkip: skipCurrent,
                               onClose: endSession)
                }
                if betweenPoses, index + 1 < items.count {
                    nextUpCard(items[index + 1])
                }
            }
        }
        .background(Color.black)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear(perform: startSession)
        .onDisappear(perform: tearDown)
    }

    private var voice: VoiceLanguage { VoiceLanguage(rawValue: voiceLanguageRaw) ?? .english }

    private var current: PracticeItem? {
        index < items.count ? items[index] : nil
    }

    private var scrims: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.black.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 170)
            Spacer()
            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                .frame(height: 360)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func nextUpCard(_ next: PracticeItem) -> some View {
        VStack(spacing: 12) {
            PoseFigureView(figure: next.staged.figure, color: next.asana.category.color, lineWidth: 4)
                .frame(width: 110, height: 110)
            Text("Nice work").font(.title2.bold())
            Text("Next: \(next.staged.displayName)")
                .foregroundStyle(.secondary)
        }
        .padding(30)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Flow

    private func startSession() {
        guard engine == nil, !items.isEmpty else { return }
        UIApplication.shared.isIdleTimerDisabled = true
        coach = Coach(voiceEnabled: voiceCoach, hapticsEnabled: haptics, language: voice)
        tracker.start()
        startPose(at: 0)
    }

    private func startPose(at newIndex: Int) {
        let item = items[newIndex]
        let newEngine = AsanaEngine(asana: item.asana, side: item.side,
                                    tolerance: tolerance, breathSeconds: breathSeconds)
        newEngine.onEvent = { event in handle(event) }
        tracker.onSample = { [weak newEngine] sample in newEngine?.handle(sample) }
        tracker.simulatedTarget = item.staged.figure
        tracker.simulatedFacing = item.asana.facing
        withAnimation {
            index = newIndex
            betweenPoses = false
            engine = newEngine
        }
        coach?.say(Script.poseIntro(item.staged, side: item.side, in: voice))
    }

    private func handle(_ event: AsanaEngine.Event) {
        guard let coach else { return }
        switch event {
        case .framing(let message):
            coach.say(message)
        case .ready(let cue):
            coach.tap()
            coach.say(cue)
        case .correction(let message):
            coach.say(message, interrupt: false)
        case .holdStarted:
            coach.success()
            coach.say(Script.holdStarted(in: voice))
        case .holdPaused:
            coach.warning()
        case .breath(let count):
            coach.tap()
            let total = engine?.asana.holdBreaths ?? 0
            if count >= total { return }
            coach.say(Script.breath(count, isLast: count == total - 1, in: voice), interrupt: false)
        case .finished:
            finishCurrentPose()
        }
    }

    private func finishCurrentPose() {
        guard let engine else { return }
        record(engine.result)
        coach?.success()

        if index + 1 < items.count {
            let nextIndex = index + 1
            withAnimation { betweenPoses = true }
            coach?.say(Script.nextPose(Speech.name(of: items[nextIndex].staged, in: voice), in: voice))
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3.5))
                guard betweenPoses, !showingSummary else { return }
                startPose(at: nextIndex)
            }
        } else {
            coach?.say(Script.practiceComplete(in: voice))
            tracker.stop()
            showingSummary = true
        }
    }

    /// Moves on without finishing the hold, keeping whatever was already earned.
    private func skipCurrent() {
        guard let engine else { return }
        if engine.breathsHeld > 0 {
            engine.finishEarly()
            record(engine.result)
        }
        if index + 1 < items.count {
            startPose(at: index + 1)
        } else {
            tracker.stop()
            if results.isEmpty { dismiss() } else { showingSummary = true }
        }
    }

    private func endSession() {
        if let engine, engine.phase != .finished, engine.breathsHeld > 0 {
            engine.finishEarly()
            record(engine.result)
        }
        betweenPoses = false
        tracker.stop()
        if results.isEmpty {
            dismiss()
        } else {
            showingSummary = true
        }
    }

    private func record(_ result: AsanaResult) {
        guard result.breaths > 0 else { return }
        results.append(result)
        modelContext.insert(PracticeSession(result: result))
        try? modelContext.save()
    }

    private func tearDown() {
        UIApplication.shared.isIdleTimerDisabled = false
        tracker.onSample = nil
        engine?.onEvent = nil
        tracker.stop()
        coach?.finish()
    }
}
