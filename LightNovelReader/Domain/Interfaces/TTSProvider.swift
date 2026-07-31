import Foundation

public struct TTSVoice: Equatable {
    public let id: String
    public let name: String
    public let language: String
}

public protocol TTSProvider {
    var providerName: String { get }
    var currentVoice: TTSVoice { get set }
    var speakingRate: Float { get set }
    
    // Synthesize text to audio file
    func synthesize(text: String) async throws -> URL
    
    // Playback controls
    func play(audioURL: URL) async throws
    func pause()
    func resume()
    func stop()
}

public enum TTSState: Equatable {
    case idle
    case loading(sentenceIndex: Int)
    case playing(sentenceIndex: Int)
    case paused(sentenceIndex: Int)
    case error(String)
}
