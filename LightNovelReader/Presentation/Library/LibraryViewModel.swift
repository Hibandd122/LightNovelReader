import Foundation
import Combine
import SwiftData

@MainActor
public final class LibraryViewModel: ObservableObject {
    @Published public var isSyncing: Bool = false
    @Published public var error: String?

    private let repository: GoogleDocsRepositoryProtocol

    public init(repository: GoogleDocsRepositoryProtocol = DIContainer.shared.googleDocsRepository) {
        self.repository = repository
    }
    
    public func syncFromGoogleDocs(context: ModelContext) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            error = nil
            try await repository.fetchAndSaveDocument(id: SupportedGoogleDocument.documentID, context: context)
        } catch {
            self.error = error.localizedDescription
        }
    }
}