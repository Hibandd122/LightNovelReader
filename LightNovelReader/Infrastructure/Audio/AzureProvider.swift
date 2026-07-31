import Foundation

@MainActor
public final class AzureProvider: TTSProvider {
    public var providerName: String = "Azure Cognitive Speech"
    public var currentVoice: TTSVoice
    public var speakingRate: Float = 1.0
    
    private let apiKey: String
    private let region: String
    private let networkService: NetworkService
    
    public init(apiKey: String, region: String, networkService: NetworkService = URLSessionNetworkService()) {
        self.apiKey = apiKey
        self.region = region
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