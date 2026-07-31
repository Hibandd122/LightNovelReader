import Foundation
import SwiftData

@MainActor
public final class LibraryViewModel: ObservableObject {
    @Published public var isSyncing: Bool = false
    @Published public var error: String?
    
    // In real app, inject this
    // private let getNovelsUseCase: GetNovelsUseCase
    
    public init() {}
    
    public func syncFromGoogleDocs(context: ModelContext) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // Mocking a network call
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            // Insert mock data if empty just to show
            let novel = Novel(id: UUID().uuidString, title: "Sample Light Novel from Docs", author: "Author Name")
            context.insert(novel)
            
            try context.save()
            
        } catch {
            self.error = error.localizedDescription
        }
    }
}
