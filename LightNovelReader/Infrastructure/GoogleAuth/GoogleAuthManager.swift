import Foundation
import Combine
@preconcurrency import GoogleSignIn
import UIKit

@MainActor
public final class GoogleAuthManager: ObservableObject {
    private let tokenManager: TokenManager
    
    public init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
    }

    public func restorePreviousSignIn() async -> Bool {
        let clientID = "727455900885-emb3k5dk3eukfs3h9qdtfqljrgn7r7pi.apps.googleusercontent.com"
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        guard let user = try? await GIDSignIn.sharedInstance.restorePreviousSignIn() else { return false }
        do {
            try await saveTokens(for: user)
            return true
        } catch {
            return false
        }
    }
    
    public func signIn() async throws {
        let clientID = "727455900885-emb3k5dk3eukfs3h9qdtfqljrgn7r7pi.apps.googleusercontent.com"
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        try await saveTokens(for: result.user)
    }
    
    public func signOut() async {
        GIDSignIn.sharedInstance.signOut()
        await tokenManager.clearTokens()
    }

    private func saveTokens(for user: GIDGoogleUser) async throws {
        guard let allowedAccountID = Bundle.main.object(forInfoDictionaryKey: "AllowedGoogleAccountID") as? String,
              let userID = user.userID,
              userID == allowedAccountID else {
            throw AuthError.accountNotAllowed
        }
        let accessToken = user.accessToken.tokenString
        let refreshToken = user.refreshToken.tokenString
        let expiresIn = max(60, (user.accessToken.expirationDate ?? Date()).timeIntervalSinceNow)
        try await tokenManager.saveTokens(access: accessToken, refresh: refreshToken, expiresIn: expiresIn)
    }
}

private enum AuthError: LocalizedError {
    case accountNotAllowed
    case configuration

    var errorDescription: String? {
        switch self {
        case .accountNotAllowed: return "Tài khoản Google này không được phép truy cập."
        case .configuration: return "Ứng dụng chưa được cấu hình Google OAuth hợp lệ."
        }
    }
}
