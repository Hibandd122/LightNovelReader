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
    public let audioCacheManager: AudioCacheManager
    public let googleAuthManager: GoogleAuthManager
    public let googleDocsRepository: GoogleDocsRepositoryProtocol
    
    private init() {
        self.tokenManager = TokenManager(keychain: KeychainStorage())
        let interceptor = AuthInterceptor(tokenManager: tokenManager)
        self.networkService = URLSessionNetworkService(interceptor: interceptor)
        self.audioCacheManager = AudioCacheManager()
        self.ttsManager = TTSManager(provider: AppleAVSpeechProvider(), audioCache: self.audioCacheManager)
        self.googleAuthManager = GoogleAuthManager(tokenManager: self.tokenManager)
        self.googleDocsRepository = GoogleDocsRepository(
            docsService: GoogleDocsService(networkService: self.networkService),
            parser: DocumentParser(),
            serializer: DocumentSerializer()
        )
        self.syncManager = SyncManager(repository: self.googleDocsRepository)
    }
}
