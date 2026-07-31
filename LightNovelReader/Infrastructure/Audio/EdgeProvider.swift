import Foundation

@MainActor
public final class EdgeProvider: TTSProvider {
    public var providerName: String = "Microsoft Edge TTS"
    public var currentVoice: TTSVoice
    public var speakingRate: Float = 1.0
    
    private let networkService: NetworkService
    
    public init(networkService: NetworkService = URLSessionNetworkService()) {
        self.networkService = networkService
        self.currentVoice = TTSVoice(id: "vi-VN-HoaiMyNeural", name: "Hoai My", language: "vi-VN")
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
