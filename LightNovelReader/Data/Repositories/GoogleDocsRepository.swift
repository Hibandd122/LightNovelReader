import Foundation
import SwiftData

public protocol GoogleDocsRepositoryProtocol {
    func fetchAndSaveDocument(id: String, context: ModelContext) async throws
    func pushLocalChanges(for novel: Novel, context: ModelContext) async throws
}

public struct GoogleDocsRepository: GoogleDocsRepositoryProtocol {
    private let docsService: GoogleDocsServiceProtocol
    private let parser: DocumentParser
    private let serializer: DocumentSerializer
    
    public init(docsService: GoogleDocsServiceProtocol, parser: DocumentParser, serializer: DocumentSerializer) {
        self.docsService = docsService
        self.parser = parser
        self.serializer = serializer
    }
    
    public func fetchAndSaveDocument(id: String, context: ModelContext) async throws {
        let doc = try await docsService.getDocument(id: id)
        let plainText = parser.parseToPlainText(document: doc)
        
        // Find existing Novel/Chapter or create new
        // Normally done with FetchDescriptor in SwiftData
        let newChapter = Chapter(id: doc.documentId, title: doc.title, content: plainText)
        context.insert(newChapter)
        try context.save()
    }
    
    public func pushLocalChanges(for novel: Novel, context: ModelContext) async throws {
        // Fetch SyncJobs from context where documentId == novel.id
        // Serialize them to GoogleDocsRequests
        // let requests = serializer.computeDiffAndSerialize(...)
        // try await docsService.batchUpdate(id: novel.id, requests: requests)
    }
}
