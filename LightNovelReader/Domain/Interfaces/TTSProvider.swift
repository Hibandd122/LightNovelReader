import Foundation

public struct TTSVoice: Equatable {
    public let id: String
    public let name: String
    public let language: String
}

@MainActor
public protocol TTSProvider {
    var providerName: String { get }
    var currentVoice: TTSVoice { get set }
    var speakingRate: Float { get set }
    
    // Synthesize text to audio file
    func synthesize(text: String) async throws -> URL
    func speak(text: String) async throws
    
    // Playback controls
    func play(audioURL: URL) async throws
    func pause()
    func resume()
    func stop()
}

public enum TTSProviderError: LocalizedError {
    case unavailable(String)

    public var errorDescription: String? {
        switch self {
        case .unavailable(let provider): return "TTS provider \(provider) chưa được cấu hình."
        }
    }
}

public extension TTSProvider {
    func speak(text: String) async throws {
        let audioURL = try await synthesize(text: text)
        try await play(audioURL: audioURL)
    }
}

public enum TTSState: Equatable {
    case idle
    case loading(sentenceIndex: Int)
    case playing(sentenceIndex: Int)
    case paused(sentenceIndex: Int)
    case error(String)
}