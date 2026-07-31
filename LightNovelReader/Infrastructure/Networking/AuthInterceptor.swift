import Foundation

public actor AuthInterceptor {
    private let tokenManager: TokenManager
    
    public init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
    }
    
    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        var urlRequest = request
        if let token = await tokenManager.getValidAccessToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return urlRequest
    }
    
    public func retry(_ request: URLRequest) async throws -> URLRequest {
        // Force refresh
        let newToken = try await tokenManager.refreshAccessToken()
        var urlRequest = request
        urlRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
}
