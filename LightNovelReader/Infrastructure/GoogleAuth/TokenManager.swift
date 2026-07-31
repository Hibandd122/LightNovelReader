import Foundation

public actor TokenManager {
    private let keychain: KeychainStorageProtocol
    private let accessKey = "com.lightnovel.accessToken"
    private let refreshKey = "com.lightnovel.refreshToken"
    
    private var accessToken: String?
    private var refreshToken: String?
    
    private var isRefreshing = false
    
    public init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
        loadTokensFromKeychain()
    }
    
    private func loadTokensFromKeychain() {
        if let accessData = try? keychain.load(key: accessKey),
           let access = String(data: accessData, encoding: .utf8) {
            self.accessToken = access
        }
        
        if let refreshData = try? keychain.load(key: refreshKey),
           let refresh = String(data: refreshData, encoding: .utf8) {
            self.refreshToken = refresh
        }
    }
    
    public func saveTokens(access: String, refresh: String) throws {
        self.accessToken = access
        self.refreshToken = refresh
        
        guard let aData = access.data(using: .utf8), let rData = refresh.data(using: .utf8) else { return }
        try keychain.save(key: accessKey, data: aData)
        try keychain.save(key: refreshKey, data: rData)
    }
    
    public func getValidAccessToken() -> String? {
        // In a real app, you'd check expiration here
        return accessToken
    }
    
    public func refreshAccessToken() async throws -> String {
        guard !isRefreshing else {
            // Wait logic could be implemented here using Continuations
            return accessToken ?? ""
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        guard let refresh = refreshToken else {
            throw NetworkError.unauthorized
        }
        
        // Pseudo logic for calling Google Auth endpoint
        // let newAccess = await api.refresh(token: refresh)
        let newAccess = "new_mock_token_from_google"
        
        try saveTokens(access: newAccess, refresh: refresh)
        return newAccess
    }
    
    public func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
        try? keychain.delete(key: accessKey)
        try? keychain.delete(key: refreshKey)
    }
}
