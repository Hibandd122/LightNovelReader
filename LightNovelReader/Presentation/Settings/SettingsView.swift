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
                            // Call GoogleAuthManager.signOut
                            appState.isAuthenticated = false
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Sign in with Google") {
                            // Call GoogleAuthManager.signIn
                            appState.isAuthenticated = true
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
