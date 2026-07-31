import Foundation

@MainActor
public final class GoogleAuthManager: ObservableObject {
    private let tokenManager: TokenManager
    
    public init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
    }
    
    public func signIn() async throws {
        // This is where ASWebAuthenticationSession or GoogleSignIn SDK logic goes
        // Since we are pure Swift without 3rd party UI libraries, we would use ASWebAuthenticationSession
        
        // Mock successful login
        try await tokenManager.saveTokens(access: "mock_access_token", refresh: "mock_refresh_token")
    }
    
    public func signOut() async {
        await tokenManager.clearTokens()
    }
}
