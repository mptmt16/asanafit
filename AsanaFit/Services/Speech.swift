import AVFoundation
import Foundation

/// The language the coach speaks in.
///
/// This is deliberately separate from the language the app is *displayed* in. Someone may want an
/// English interface and Hindi coaching, and the spoken cues are the part you actually rely on
/// mid-pose, when your head is turned away and you cannot read the screen.
enum VoiceLanguage: String, CaseIterable, Identifiable {
    case english, hindi

    var id: String { rawValue }

    /// Shown in its own language, which is the only way a speaker of it can find it in a list.
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी (Hindi)"
        }
    }

    /// BCP-47 code handed to the speech synthesiser.
    var speechCode: String {
        switch self {
        case .english: return "en-US"
        case .hindi: return "hi-IN"
        }
    }

    private var codePrefix: String {
        switch self {
        case .english: return "en"
        case .hindi: return "hi"
        }
    }

    /// The best installed voice: the exact region if there is one, otherwise any voice
    /// for the language.
    var voice: AVSpeechSynthesisVoice? {
        if let exact = AVSpeechSynthesisVoice(language: speechCode) { return exact }
        return AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix(codePrefix) }
    }

    /// False when iOS has no voice installed for this language. Settings says so rather than
    /// letting the coach fall silent or read Devanagari with an English voice.
    var isAvailable: Bool { voice != nil }

    /// Hindi is clearer a little slower than the English default.
    var rateMultiplier: Float {
        switch self {
        case .english: return 0.95
        case .hindi: return 0.90
        }
    }
}

/// Looks up what the coach should say.
///
/// Every line is written in English in the pose library and the engines, then translated here at
/// the moment it is spoken. That keeps the library readable in one language, and means a missing
/// translation degrades to English rather than to silence. `untranslated()` lists the gaps.
enum Speech {
    static func line(_ english: String, in language: VoiceLanguage) -> String {
        switch language {
        case .english: return english
        case .hindi: return SpeechHindi.lines[english] ?? english
        }
    }

    /// The pose name to speak. Hindi gets the Sanskrit name in Devanagari, which is what the
    /// pose is actually called, rather than a transliteration the voice would mangle.
    static func name(of asana: Asana, in language: VoiceLanguage) -> String {
        switch language {
        case .english: return asana.name
        case .hindi: return SpeechHindi.asanaNames[asana.id] ?? asana.name
        }
    }

    /// Every line the app can speak that has no Hindi yet. Shown in Pose Lab during development,
    /// so a cue added to the library without a translation does not quietly stay English.
    static func untranslated() -> [String] {
        var english: Set<String> = []
        for asana in AsanaLibrary.all {
            english.formUnion(asana.requirements.map(\.cue))
            if let first = asana.steps.first { english.insert(first) }
        }
        english.formUnion(ScanStep.all.map(\.title))
        english.formUnion(ScanStep.all.map(\.instruction))
        english.formUnion(CameraFacing.allInstructions)
        english.formUnion(Framing.allMessages)
        english.formUnion(BreathPattern.all.map(\.name))
        english.formUnion(BreathPattern.all.map(\.summary))
        return english.filter { SpeechHindi.lines[$0] == nil }.sorted()
    }
}

/// Sentences the coach builds from parts.
///
/// These cannot live in the lookup table because they carry names and numbers, and because Hindi
/// does not order its words the way English does. Each is written out per language rather than
/// glued together from translated fragments.
enum Script {
    static func poseIntro(_ asana: Asana, side: Side, in language: VoiceLanguage) -> String {
        let name = Speech.name(of: asana, in: language)
        let facing = Speech.line(asana.facing.instruction, in: language)
        switch language {
        case .english:
            let sideText = side == .none ? "" : ", \(side == .left ? "left" : "right") side"
            return "\(name)\(sideText). \(facing)."
        case .hindi:
            let sideText = side == .none ? "" : (side == .left ? ", बाईं ओर" : ", दाईं ओर")
            return "\(name)\(sideText)। \(facing)।"
        }
    }

    static func holdStarted(in language: VoiceLanguage) -> String {
        switch language {
        case .english: return "Good. Hold and breathe."
        case .hindi: return "बढ़िया। रुकें और साँस लेते रहें।"
        }
    }

    /// Counts off a finished breath, or warns that one is left.
    static func breath(_ count: Int, isLast: Bool, in language: VoiceLanguage) -> String {
        switch language {
        case .english: return isLast ? "One more breath" : "\(count)"
        case .hindi: return isLast ? "एक और साँस" : "\(count)"
        }
    }

    static func nextPose(_ name: String, in language: VoiceLanguage) -> String {
        switch language {
        case .english: return "Release. Next: \(name)."
        case .hindi: return "छोड़ें। अगला: \(name)।"
        }
    }

    static func practiceComplete(in language: VoiceLanguage) -> String {
        switch language {
        case .english: return "Practice complete. Rest for a moment."
        case .hindi: return "अभ्यास पूरा हुआ। थोड़ी देर विश्राम करें।"
        }
    }

    static func scanIntro(_ instruction: String, in language: VoiceLanguage) -> String {
        let step = Speech.line(instruction, in: language)
        switch language {
        case .english: return "Body scan. \(step)."
        case .hindi: return "शरीर स्कैन। \(step)।"
        }
    }

    static func scanStep(title: String, instruction: String, in language: VoiceLanguage) -> String {
        let name = Speech.line(title, in: language)
        let step = Speech.line(instruction, in: language)
        switch language {
        case .english: return "\(name). \(step)."
        case .hindi: return "\(name)। \(step)।"
        }
    }

    static func holdStill(in language: VoiceLanguage) -> String {
        switch language {
        case .english: return "Hold still."
        case .hindi: return "स्थिर रहें।"
        }
    }

    static func scanComplete(in language: VoiceLanguage) -> String {
        switch language {
        case .english: return "Scan complete."
        case .hindi: return "स्कैन पूरा हुआ।"
        }
    }

    static func balanceIntro(in language: VoiceLanguage) -> String {
        switch language {
        case .english: return "Balance test. Step back so the camera can see all of you."
        case .hindi: return "संतुलन जाँच। पीछे हटें ताकि कैमरा पूरा शरीर देख सके।"
        }
    }

    static func breathIntro(_ pattern: BreathPattern, in language: VoiceLanguage) -> String {
        let name = Speech.line(pattern.name, in: language)
        let summary = Speech.line(pattern.summary, in: language)
        switch language {
        case .english: return "\(name). \(summary)"
        case .hindi: return "\(name)। \(summary)"
        }
    }
}

extension CameraFacing {
    static var allInstructions: [String] {
        [CameraFacing.front.instruction, CameraFacing.side.instruction]
    }
}

extension Framing {
    /// Every message the framing check can produce, for the translation audit.
    static var allMessages: [String] {
        [Problem.noBody, .partial, .tooClose, .tooFar, .offCentre].map(\.message) + ["Nicely framed"]
    }
}
