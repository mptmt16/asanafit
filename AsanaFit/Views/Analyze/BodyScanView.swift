import SwiftData
import SwiftUI
import UIKit

/// The guided body scan: nine short steps in front of the camera.
struct BodyScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.voiceCoach) private var voiceCoach = true
    @AppStorage(SettingsKey.haptics) private var haptics = true
    @AppStorage(SettingsKey.showSkeleton) private var showSkeleton = true

    @State private var tracker = BodyTracker()
    @State private var engine = BodyScanEngine()
    @State private var coach: Coach?
    @State private var savedScan: BodyScan?
    @State private var showingIntro = true

    var body: some View {
        ZStack {
            if let savedScan {
                NavigationStack {
                    ScanResultView(scan: savedScan, isNew: true) { dismiss() }
                }
            } else if showingIntro {
                intro
            } else {
                BodyCameraView(tracker: tracker, showSkeleton: showSkeleton,
                               ghost: engine.phase == .prepare ? SkeletonBuilder.make(engine.step.figure) : nil)
                    .ignoresSafeArea()
                scrims
                overlay
            }
        }
        .background(Color.black)
        .statusBarHidden(!showingIntro)
        .onDisappear(perform: tearDown)
    }

    // MARK: - Intro

    private var intro: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "figure.stand.line.dotted.figure.stand")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 40)
                Text("Body scan").font(.largeTitle.bold())
                Text("Nine short steps, about \(Int((ScanStep.totalSeconds / 60).rounded())) minutes. Prop your phone up so it can see all of you from head to feet, about two to three metres away.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(ScanStep.all) { step in
                        HStack(spacing: 12) {
                            Image(systemName: step.facing.symbol)
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(step.title).font(.subheadline.weight(.semibold))
                                Text(step.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Text("\(Int(step.seconds))s")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .card()

                Label("Nothing is recorded. Every frame is measured and thrown away.",
                      systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Start scan") { begin() }
                    .buttonStyle(PrimaryButtonStyle())
                Button("Not now") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .padding(.bottom, 30)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Scanning

    private var scrims: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 210)
            Spacer()
            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                .frame(height: 260)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var overlay: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
                VStack(spacing: 4) {
                    Text(engine.step.title).font(.headline)
                    Text("Step \(engine.stepIndex + 1) of \(engine.steps.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ProgressView(value: engine.overallProgress)
                        .tint(Theme.accent)
                        .frame(width: 140)
                }
                Spacer()
                Color.clear.frame(width: 38, height: 38)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            Spacer(minLength: 0)
            centre
            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Text(engine.step.instruction)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(engine.step.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 26)
        }
    }

    @ViewBuilder
    private var centre: some View {
        switch engine.phase {
        case .framing:
            VStack(spacing: 8) {
                Image(systemName: engine.facingHint == nil ? "person.fill.viewfinder" : engine.step.facing.symbol)
                    .font(.largeTitle)
                Text(engine.facingHint ?? engine.framing.message)
                    .font(.title3.bold())
                if tracker.permissionDenied {
                    Text("Camera access is off, so the scan is running on simulated data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        case .prepare:
            VStack(spacing: 4) {
                Text("\(engine.countdown)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("get into position").font(.caption).foregroundStyle(.secondary)
            }
        case .recording:
            ZStack {
                ProgressRing(progress: engine.stepProgress, lineWidth: 8, color: Theme.warm)
                VStack(spacing: 2) {
                    Image(systemName: "record.circle").font(.title2).foregroundStyle(Theme.warm)
                    Text("hold still").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 104, height: 104)
        case .finished:
            ProgressView().tint(.white)
        }
    }

    // MARK: - Flow

    private func begin() {
        showingIntro = false
        UIApplication.shared.isIdleTimerDisabled = true
        coach = Coach(voiceEnabled: voiceCoach, hapticsEnabled: haptics)
        engine.onEvent = { event in handle(event) }
        tracker.onSample = { sample in
            // Demo mode has to know the shape and the direction of the step it is standing in
            // before framing can pass, so it is refreshed every frame rather than on step change.
            tracker.simulatedTarget = engine.step.figure
            tracker.simulatedFacing = engine.step.facing
            engine.handle(sample)
        }
        tracker.start()
        coach?.say("Body scan. \(engine.step.instruction).")
    }

    private func handle(_ event: BodyScanEngine.Event) {
        guard let coach else { return }
        switch event {
        case .framing(let message):
            coach.say(message)
        case .step(let title, let instruction):
            coach.tap()
            coach.say("\(title). \(instruction).")
        case .recording:
            coach.tap()
            coach.say("Hold still.")
        case .stepDone:
            coach.success()
        case .finished:
            finish()
        }
    }

    private func finish() {
        tracker.stop()
        coach?.say("Scan complete.")
        guard let outcome = engine.outcome else {
            dismiss()
            return
        }
        let scan = BodyScan(outcome: outcome)
        modelContext.insert(scan)
        try? modelContext.save()
        savedScan = scan
    }

    private func tearDown() {
        UIApplication.shared.isIdleTimerDisabled = false
        tracker.onSample = nil
        engine.onEvent = nil
        tracker.stop()
        coach?.finish()
    }
}
