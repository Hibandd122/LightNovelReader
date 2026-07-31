import Foundation
import AVFoundation

@MainActor
public final class AppleAVSpeechProvider: NSObject, TTSProvider, AVSpeechSynthesizerDelegate {
    public let providerName = "Apple AVSpeech"
    public var currentVoice: TTSVoice
    public var speakingRate: Float = AVSpeechUtteranceDefaultSpeechRate

    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Error>?

    public override init() {
        let vietnameseVoice = AVSpeechSynthesisVoice.speechVoices()
            .first { $0.language.caseInsensitiveCompare("vi-VN") == .orderedSame }
        currentVoice = TTSVoice(
            id: vietnameseVoice?.identifier ?? "vi-VN",
            name: vietnameseVoice?.name ?? "Tiếng Việt",
            language: vietnameseVoice?.language ?? "vi-VN"
        )
        super.init()
        synthesizer.delegate = self
    }

    public func synthesize(text: String) async throws -> URL {
        throw TTSProviderError.unavailable(providerName)
    }

    public func play(audioURL: URL) async throws {
        throw TTSProviderError.unavailable(providerName)
    }

    public func speak(text: String) async throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        stop()
        let utterance = AVSpeechUtterance(string: trimmedText)
        guard let voice = AVSpeechSynthesisVoice(identifier: currentVoice.id)
                ?? AVSpeechSynthesisVoice(language: "vi-VN") else {
            throw TTSProviderError.unavailable("Tiếng Việt (vi-VN)")
        }
        guard voice.language.caseInsensitiveCompare("vi-VN") == .orderedSame else {
            throw TTSProviderError.unavailable("Tiếng Việt (vi-VN)")
        }
        utterance.voice = voice
        utterance.rate = min(max(speakingRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.05

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.continuation = continuation
            self.synthesizer.speak(utterance)
        }
    }

    public func pause() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .immediate)
    }

    public func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
    }

    public func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        finish(with: CancellationError())
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finish()
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finish(with: CancellationError())
    }

    private func finish(with error: Error? = nil) {
        guard let continuation else { return }
        self.continuation = nil
        if let error { continuation.resume(throwing: error) }
        else { continuation.resume(returning: ()) }
    }
}
