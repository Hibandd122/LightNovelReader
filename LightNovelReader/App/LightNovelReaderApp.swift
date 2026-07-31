import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct LightNovelReaderApp: App {
    // Khởi tạo Dependency Injection Container
    @StateObject private var appState = AppState()
    @AppStorage("appTheme") private var appTheme = AppThemeType.system.rawValue
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Novel.self,
            Chapter.self,
            Bookmark.self,
            Note.self,
            SyncJob.self,
            ReadingSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .preferredColorScheme(preferredColorScheme)
                .onAppear {
                    // Inject DI dependencies implicitly if needed, or pass them down
                    let _ = DIContainer.shared
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .task {
                    appState.isAuthenticated = await DIContainer.shared.googleAuthManager.restorePreviousSignIn()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private var preferredColorScheme: ColorScheme? {
        switch AppThemeType(rawValue: appTheme) {
        case .dark, .oled, .night: return .dark
        case .light, .sepia, .warm: return .light
        default: return nil
        }
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var authenticationError: String?
}