import Foundation
import Combine

@MainActor
public final class EditorViewModel: ObservableObject {
    @Published public var text: String = ""
    @Published public var isLoading: Bool = false
    @Published public var isSaving: Bool = false
    @Published public var saveStatusMessage: String = "Saved"
    
    private var saveTask: Task<Void, Never>?
    
    public init() {}
    
    public func loadDocument(for novel: Novel) {
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.text = "Chapter 1: The Beginning\n\nAs the sun rose over the digital horizon, the AI began its long awaited compilation."
            self.isLoading = false
        }
    }
    
    public func documentDidChange() {
        saveStatusMessage = "Unsaved changes"
        saveTask?.cancel()
        
        // Debounce 2 seconds before auto-saving
        saveTask = Task {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { return }
                
                self.isSaving = true
                // Perform actual local DB save here
                // SyncJob creation for offline sync happens here
                
                try await Task.sleep(nanoseconds: 500_000_000) // Mock save time
                self.isSaving = false
                self.saveStatusMessage = "Saved"
            } catch {
                // Task cancelled
            }
        }
    }
}
