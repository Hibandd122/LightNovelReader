import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    if appState.isAuthenticated {
                        Button("Sign Out") {
                            Task {
                                await DIContainer.shared.googleAuthManager.signOut()
                                await MainActor.run {
                                    appState.isAuthenticated = false
                                }
                            }
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Sign in with Google") {
                            Task {
                                do {
                                    try await DIContainer.shared.googleAuthManager.signIn()
                                    await MainActor.run {
                                        appState.isAuthenticated = true
                                    }
                                } catch {
                                    print("Login failed: \(error)")
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("TTS Engine")) {
                    Text("Apple AVSpeech (Default)")
                    Text("OpenAI TTS (Requires API Key)")
                }
                
                Section(header: Text("Data")) {
                    Button("Clear Cache") {
                        // Call AudioCacheManager to clean
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
