import AVFoundation
import UIKit

/// Voice cues and haptics.
///
/// In a yoga app this is not a nicety: in half of these poses your head is upside down,
/// turned away, or your eyes are closed, and the screen may as well not be there.
final class Coach {
    var voiceEnabled: Bool
    var hapticsEnabled: Bool

    private let synthesizer = AVSpeechSynthesizer()
    private let impact = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()

    init(voiceEnabled: Bool, hapticsEnabled: Bool) {
        self.voiceEnabled = voiceEnabled
        self.hapticsEnabled = hapticsEnabled
        if voiceEnabled {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        impact.prepare()
        notification.prepare()
    }

    func say(_ text: String, interrupt: Bool = true) {
        guard voiceEnabled else { return }
        if interrupt, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        // A little slower than default: this is a voice you are meant to move to.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }

    func tap() {
        guard hapticsEnabled else { return }
        impact.impactOccurred()
    }

    func success() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func warning() {
        guard hapticsEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    /// Stops speech and lets music or a podcast return to full volume.
    func finish() {
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
