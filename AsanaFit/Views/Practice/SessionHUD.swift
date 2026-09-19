import SwiftUI

/// Everything drawn over the camera during a pose.
struct SessionHUD: View {
    let engine: AsanaEngine
    let poseNumber: Int
    let poseCount: Int
    let isSimulated: Bool
    let permissionDenied: Bool
    @Binding var showSkeleton: Bool
    @Binding var showGuide: Bool
    var onSkip: () -> Void
    var onClose: () -> Void

    @State private var showingChecks = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 0)
            if !engine.framing.isGood, engine.phase != .finished {
                framingBanner
            }
            Spacer(minLength: 0)
            bottom
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    // MARK: - Top

    private var topBar: some View {
        HStack(alignment: .top) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text(engine.asana.displayName)
                    .font(.headline)
                Text("\(poseNumber) of \(poseCount)  -  \(engine.asana.facing == .front ? "front-on" : "side-on")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Toggle("Show skeleton", isOn: $showSkeleton)
                Toggle("Show pose guide", isOn: $showGuide)
                Toggle("Show measurements", isOn: $showingChecks)
                Button("Skip this pose", systemImage: "forward.end", action: onSkip)
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.top, 10)
    }

    private var framingBanner: some View {
        VStack(spacing: 6) {
            Image(systemName: permissionDenied ? "camera.badge.ellipsis" : "person.fill.viewfinder")
                .font(.largeTitle)
            Text(permissionDenied ? "Camera access is off" : engine.framing.message)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            if permissionDenied {
                Text("Turn it on in Settings, or keep exploring in demo mode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if isSimulated {
                Text("Demo mode moves for you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Bottom

    private var bottom: some View {
        VStack(spacing: 14) {
            if showingChecks {
                checks
            }
            cueText
            HStack(alignment: .center, spacing: 22) {
                alignmentDial
                breathColumn
            }
        }
    }

    private var cueText: some View {
        Text(engine.phase == .framing ? engine.framing.message : engine.cue)
            .font(.title3.weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54, alignment: .center)
            .padding(.horizontal, 10)
            .animation(.easeInOut(duration: 0.2), value: engine.cue)
    }

    private var alignmentDial: some View {
        ZStack {
            ProgressRing(progress: engine.holdProgress, lineWidth: 8,
                         color: Theme.secondary, trackOpacity: 0.12)
            ProgressRing(progress: engine.alignment, lineWidth: 12,
                         color: ringColour)
                .padding(15)
            VStack(spacing: 0) {
                if engine.phase == .settling, engine.countdown > 0 {
                    Text("\(engine.countdown)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("get set").font(.caption2).foregroundStyle(.secondary)
                } else {
                    Text("\(Int((engine.alignment * 100).rounded()))%")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("aligned").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 132, height: 132)
    }

    private var ringColour: Color {
        if engine.phase == .holding, engine.isPaused { return Theme.warm }
        return engine.alignment >= 1 ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.accent
    }

    private var breathColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.secondary.opacity(0.9))
                    .frame(width: breathDotSize, height: breathDotSize)
                    .animation(.easeInOut(duration: 0.3), value: breathDotSize)
                VStack(alignment: .leading, spacing: 1) {
                    Text(engine.phase == .holding ? engine.breath.phase.cue : "Breathe easy")
                        .font(.subheadline.weight(.semibold))
                    Text("\(engine.breathsHeld) of \(engine.asana.holdBreaths) breaths")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            HStack(spacing: 4) {
                ForEach(0..<engine.asana.holdBreaths, id: \.self) { index in
                    Capsule()
                        .fill(index < engine.breathsHeld ? Theme.secondary : Color.white.opacity(0.2))
                        .frame(width: 14, height: 5)
                }
            }
            if engine.isPaused {
                Label("Hold paused", systemImage: "pause.circle")
                    .font(.caption2)
                    .foregroundStyle(Theme.warm)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var breathDotSize: CGFloat {
        guard engine.phase == .holding else { return 18 }
        let swell = engine.breath.phase == .inhale ? engine.breath.phaseProgress : 1 - engine.breath.phaseProgress
        return 16 + 16 * swell
    }

    private var checks: some View {
        VStack(spacing: 6) {
            ForEach(engine.checks) { check in
                HStack(spacing: 8) {
                    Image(systemName: check.isMet ? "checkmark.circle.fill" : "circle.dashed")
                        .font(.caption)
                        .foregroundStyle(check.isMet ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.warm)
                    Text(check.name)
                        .font(.caption2)
                        .frame(width: 92, alignment: .leading)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.14))
                            Capsule()
                                .fill(check.isMet ? Color(red: 0.45, green: 0.85, blue: 0.55) : Theme.accent)
                                .frame(width: proxy.size.width * min(1, max(0, check.progress)))
                        }
                    }
                    .frame(height: 5)
                    Text(valueText(check))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 46, alignment: .trailing)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func valueText(_ check: AlignmentCheck) -> String {
        guard let value = check.value else { return "--" }
        return check.unit == "deg" ? "\(Int(value.rounded()))\u{00B0}" : String(format: "%.2f", value)
    }
}
