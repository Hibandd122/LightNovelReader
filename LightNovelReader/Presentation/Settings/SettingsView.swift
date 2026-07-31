import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("appTheme") private var appTheme = AppThemeType.system.rawValue
    
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
                                    appState.isAuthenticated = true
                                } catch {
                                    appState.authenticationError = error.localizedDescription
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("TTS Engine")) {
                    Text("Apple AVSpeech — Tiếng Việt (vi-VN)")
                    Text("Giọng đọc phụ thuộc voice tiếng Việt đã cài trên iPhone/iPad.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Giao diện")) {
                    Picker("Chủ đề", selection: $appTheme) {
                        ForEach(AppThemeType.allCases) { theme in
                            Text(theme.rawValue).tag(theme.rawValue)
                        }
                    }
                }
                
                Section(header: Text("Data")) {
                    Button("Clear Cache") {
                        Task {
                            await DIContainer.shared.audioCacheManager.clearAll()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Đăng nhập thất bại", isPresented: Binding(
                get: { appState.authenticationError != nil },
                set: { if !$0 { appState.authenticationError = nil } }
            )) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(appState.authenticationError ?? "Không thể đăng nhập Google.")
            }
        }
    }
}
