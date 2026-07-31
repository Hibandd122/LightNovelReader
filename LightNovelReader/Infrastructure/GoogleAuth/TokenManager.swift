import Foundation

public actor TokenManager {
    private let keychain: KeychainStorageProtocol
    private let accessKey = "com.lightnovel.accessToken"
    private let refreshKey = "com.lightnovel.refreshToken"
    private let expiryKey = "com.lightnovel.accessTokenExpiry"
    
    private var accessToken: String?
    private var refreshToken: String?
    
    private var accessTokenExpiry: Date?
    private var refreshTask: Task<String, Error>?
    
    public init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
        if let accessData = try? keychain.load(key: accessKey),
           let access = String(data: accessData, encoding: .utf8) {
            self.accessToken = access
        }
        
        if let refreshData = try? keychain.load(key: refreshKey),
           let refresh = String(data: refreshData, encoding: .utf8) {
            self.refreshToken = refresh
        }

        if let expiryData = try? keychain.load(key: expiryKey),
           let expiry = String(data: expiryData, encoding: .utf8),
           let timestamp = Double(expiry) {
            self.accessTokenExpiry = Date(timeIntervalSince1970: timestamp)
        }
    }
    
    public func saveTokens(access: String, refresh: String, expiresIn: TimeInterval = 3600) throws {
        self.accessToken = access
        self.refreshToken = refresh
        self.accessTokenExpiry = Date().addingTimeInterval(max(60, expiresIn))
        
        guard let aData = access.data(using: .utf8), let rData = refresh.data(using: .utf8),
              let expiryData = String(accessTokenExpiry?.timeIntervalSince1970 ?? 0).data(using: .utf8) else {
            throw NetworkError.invalidToken
        }
        try keychain.save(key: accessKey, data: aData)
        try keychain.save(key: refreshKey, data: rData)
        try keychain.save(key: expiryKey, data: expiryData)
    }
    
    public func getValidAccessToken() -> String? {
        guard let accessToken, let expiry = accessTokenExpiry,
              expiry.timeIntervalSinceNow > 60 else { return nil }
        return accessToken
    }
    
    public func refreshAccessToken() async throws -> String {
        if let refreshTask { return try await refreshTask.value }
        guard let refresh = refreshToken else {
            throw NetworkError.unauthorized
        }

        let task = Task<String, Error> {
            guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
                  !clientID.isEmpty,
                  !clientID.contains("mock") else {
                throw NetworkError.invalidToken
            }
            var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token") ?? URL(fileURLWithPath: "/"))
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let body = [
                "client_id": clientID,
                "grant_type": "refresh_token",
                "refresh_token": refresh
            ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._~"))) ?? $0.value)" }.joined(separator: "&")
            request.httpBody = body.data(using: .utf8)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.unknown(statusCode: 0) }
            guard 200...299 ~= httpResponse.statusCode else { throw NetworkError.unauthorized }
            let payload = try JSONDecoder().decode(GoogleTokenRefreshResponse.self, from: data)
            try await self.saveTokens(access: payload.accessToken, refresh: refresh, expiresIn: TimeInterval(payload.expiresIn))
            return payload.accessToken
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
    
    public func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
        try? keychain.delete(key: accessKey)
        try? keychain.delete(key: refreshKey)
        try? keychain.delete(key: expiryKey)
    }
}

private struct GoogleTokenRefreshResponse: Decodable {
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}
