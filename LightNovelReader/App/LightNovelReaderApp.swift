import SwiftUI
import SwiftData

@main
struct LightNovelReaderApp: App {
    // Khởi tạo Dependency Injection Container
    @StateObject private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Novel.self,
            Chapter.self,
            Bookmark.self,
            SyncJob.self
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
                .onAppear {
                    // Inject DI dependencies implicitly if needed, or pass them down
                    let _ = DIContainer.shared
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
}
