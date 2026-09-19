import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void

    @AppStorage(SettingsKey.goals) private var goalsRaw = ""
    @AppStorage(SettingsKey.breathSeconds) private var breathSeconds = BreathPacer.defaultBreathSeconds
    @AppStorage(SettingsKey.tolerance) private var tolerance = 1.0
    @AppStorage(SettingsKey.voiceLanguage) private var voiceLanguageRaw = VoiceLanguage.english.rawValue
    @State private var pageIndex = 0

    private var goals: Set<BodyArea> {
        Set(goalsRaw.settingsList.compactMap { BodyArea(rawValue: $0) })
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.12, green: 0.10, blue: 0.24), .black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $pageIndex) {
                    welcome.tag(0)
                    howItWorks.tag(1)
                    setUpTheSpace.tag(2)
                    goalPicker.tag(3)
                    pace.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(pageIndex < 4 ? "Next" : "Start practising") {
                    if pageIndex < 4 {
                        withAnimation { pageIndex += 1 }
                    } else {
                        onDone()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                Button("Skip") { onDone() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 16)
                    .opacity(pageIndex < 4 ? 1 : 0)
            }
        }
    }

    // MARK: - Pages

    private var welcome: some View {
        slide(symbol: nil, title: "AsanaFit", subtitle: "A yoga teacher that can actually see you.") {
            VStack(spacing: 18) {
                PoseFigureView(figure: AsanaLibrary.asana(id: "warrior-two")?.figure ?? .mountain,
                               color: Theme.accent, lineWidth: 5, animated: true, showJoints: true)
                    .frame(height: 200)
                Text("Your camera tracks fifteen joints in real time. AsanaFit measures the angles they make, tells you what to change, and counts your hold in breaths.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var howItWorks: some View {
        slide(symbol: "lock.shield", title: "It all stays here",
             subtitle: "No account, no upload, no recording.") {
            VStack(alignment: .leading, spacing: 16) {
                bullet("eye", "Every frame is measured on your iPhone and thrown away straight after.")
                bullet("waveform", "What gets saved is numbers: angles, seconds, breaths.")
                bullet("speaker.wave.2", "The voice coach matters here. In half of these poses you cannot see the screen.")
                bullet("iphone", "Any iPhone running iOS 17 works. No special camera needed.")
            }
        }
    }

    private var setUpTheSpace: some View {
        slide(symbol: "camera.viewfinder", title: "Set up your space",
             subtitle: "The camera needs to see all of you.") {
            VStack(alignment: .leading, spacing: 16) {
                bullet("ruler", "Prop the phone up two to three metres away, roughly at hip height.")
                bullet("person.fill.viewfinder", "Stand so your head and both feet are inside the frame. The app tells you when you are too close or too far.")
                bullet("person.fill.turn.right", "Some poses are checked from the front and some from the side. Each one tells you which before it starts.")
                bullet("lightbulb", "Even, front-on light helps. Avoid standing with a bright window behind you.")
            }
        }
    }

    private var goalPicker: some View {
        slide(symbol: "target", title: "What are you here for?",
             subtitle: "Pick as many as you like, or none.") {
            VStack(spacing: 10) {
                ForEach(BodyArea.allCases) { area in
                    Button {
                        toggle(area)
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
                        .padding(12)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var pace: some View {
        slide(symbol: "wind", title: "Set your pace",
             subtitle: "Both of these can change later in Settings.") {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What language should the coach speak?").font(.subheadline.weight(.semibold))
                    Picker("Voice language", selection: $voiceLanguageRaw) {
                        ForEach(VoiceLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("The screens stay in English. This is the voice you hear mid-pose.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("How strict should the coaching be?").font(.subheadline.weight(.semibold))
                    Picker("Practice", selection: $tolerance) {
                        Text("Gentle").tag(1.5)
                        Text("Standard").tag(1.0)
                        Text("Precise").tag(0.75)
                    }
                    .pickerStyle(.segmented)
                    Text("Gentle widens every alignment target. Start there if you are new.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Seconds per breath").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(breathSeconds.trimmedString)s")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.accent)
                    }
                    Slider(value: $breathSeconds, in: 3...10, step: 0.5).tint(Theme.accent)
                    Text("Holds are counted in breaths, so this sets how long every pose lasts. Five breaths at \(breathSeconds.trimmedString) seconds is \(Int(breathSeconds * 5)) seconds.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Building blocks

    private func slide<Content: View>(symbol: String?, title: String, subtitle: String,
                                     @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 46))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 40)
                }
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, symbol == nil ? 40 : 0)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                content()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func bullet(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
            Text(text).font(.subheadline)
            Spacer(minLength: 0)
        }
    }

    private func toggle(_ area: BodyArea) {
        var current = goals
        if current.contains(area) { current.remove(area) } else { current.insert(area) }
        goalsRaw = current.map(\.rawValue).sorted().joined(separator: ",")
    }
}
