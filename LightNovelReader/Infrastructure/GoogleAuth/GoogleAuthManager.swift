import Foundation
import GoogleSignIn
import UIKit

@MainActor
public final class GoogleAuthManager: ObservableObject {
    private let tokenManager: TokenManager
    
    public init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
    }
    
    public func signIn() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        let user = result.user
        
        guard let accessToken = user.accessToken.tokenString as String? else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing tokens"])
        }
        
        let refreshToken = user.refreshToken.tokenString
        
        try await tokenManager.saveTokens(access: accessToken, refresh: refreshToken)
    }
    
    public func signOut() async {
        GIDSignIn.sharedInstance.signOut()
        await tokenManager.clearTokens()
    }
}
