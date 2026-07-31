import Foundation
import Combine
import UIKit

@MainActor
public final class EditorViewModel: ObservableObject {
    @Published public var text = ""
    @Published public var attributedText = NSAttributedString()
    @Published public var selectedRange = NSRange(location: 0, length: 0)
    @Published public var isLoading = false
    @Published public var isSaving = false
    @Published public var saveStatusMessage = "Đã lưu"

    private var saveTask: Task<Void, Never>?
    private weak var chapter: Chapter?

    public init() {}

    public func loadDocument(for novel: Novel) {
        chapter = novel.chapters.first
        text = chapter?.content ?? ""
        attributedText = NSAttributedString(string: text, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
        selectedRange = NSRange(location: 0, length: 0)
        isLoading = false
    }

    public func documentDidChange() {
        text = attributedText.string
        saveStatusMessage = "Chưa lưu"
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled, let self, let chapter = self.chapter else { return }
                self.isSaving = true
                chapter.content = self.text
                chapter.novel?.lastModified = Date()
                if let context = chapter.modelContext {
                    let documentID = chapter.novel?.id ?? ""
                    let payload = try JSONEncoder().encode(self.text)
                    let descriptor = FetchDescriptor<SyncJob>(predicate: #Predicate {
                        $0.documentId == documentID && $0.operationType == 0 && $0.status != 1
                    })
                    if let pendingJob = try context.fetch(descriptor).first {
                        pendingJob.payload = payload
                        pendingJob.retryCount = 0
                        pendingJob.status = 0
                        pendingJob.nextAttemptAt = nil
                    } else {
                        context.insert(SyncJob(documentId: documentID, operationType: 0, payload: payload))
                    }
                    chapter.novel?.syncStatus = 1
                    try context.save()
                    DIContainer.shared.syncManager.configure(context: context)
                    DIContainer.shared.syncManager.triggerSync()
                }
                self.isSaving = false
                self.saveStatusMessage = "Đã lưu"
            } catch {
                guard !Task.isCancelled else { return }
                self?.isSaving = false
                self?.saveStatusMessage = "Lưu thất bại"
            }
        }
    }
}