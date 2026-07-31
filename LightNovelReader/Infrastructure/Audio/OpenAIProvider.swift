import Foundation

@MainActor
public final class OpenAIProvider: TTSProvider {
    public var providerName: String = "OpenAI TTS"
    public var currentVoice: TTSVoice
    public var speakingRate: Float = 1.0
    
    private let apiKey: String
    private let networkService: NetworkService
    
    public init(apiKey: String, networkService: NetworkService = URLSessionNetworkService()) {
        self.apiKey = apiKey
        self.networkService = networkService
        self.currentVoice = TTSVoice(id: "alloy", name: "Alloy", language: "en-US")
    }
    
    public func synthesize(text: String) async throws -> URL {
        throw TTSProviderError.unavailable(providerName)
    }
    
    public func play(audioURL: URL) async throws {
        throw TTSProviderError.unavailable(providerName)
    }
    
    public func pause() {}
    public func resume() {}
    public func stop() {}
}