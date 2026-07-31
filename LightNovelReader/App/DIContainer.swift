import Foundation
import SwiftData

@MainActor
public final class DIContainer {
    public static let shared = DIContainer()
    
    // Dependencies
    public let networkService: NetworkService
    public let tokenManager: TokenManager
    public let syncManager: SyncManager
    public let ttsManager: TTSManager
    
    private init() {
        self.tokenManager = TokenManager(keychain: KeychainStorage())
        let interceptor = AuthInterceptor(tokenManager: tokenManager)
        self.networkService = URLSessionNetworkService(interceptor: interceptor)
        self.syncManager = SyncManager(networkService: networkService)
        self.ttsManager = TTSManager(provider: AppleAVSpeechProvider(), audioCache: AudioCacheManager())
    }
}
