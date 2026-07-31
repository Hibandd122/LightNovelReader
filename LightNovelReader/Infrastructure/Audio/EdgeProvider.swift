import Foundation

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
        // Reverse engineered Edge TTS websocket or HTTP endpoints
        let dummyURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("edge_dummy.mp3")
        return dummyURL
    }
    
    public func play(audioURL: URL) async throws {
        // AVPlayer implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    public func pause() {}
    public func resume() {}
    public func stop() {}
}
