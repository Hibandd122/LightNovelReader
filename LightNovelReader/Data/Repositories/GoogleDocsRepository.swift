import Foundation
import SwiftData

@MainActor
public protocol GoogleDocsRepositoryProtocol {
    func fetchAndSaveDocument(id: String, context: ModelContext) async throws
    func pushLocalChanges(for novel: Novel, context: ModelContext) async throws
}

public enum SupportedGoogleDocument {
    public static let folderID = "1g1ExSDNBmOo_UvW7yiktBkl265aHfJCs"
    public static let documentID = "1rXgLnk35GbHpRFRfB9Hj4LAthPpL7vl_"
}

@MainActor
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
        guard id == SupportedGoogleDocument.documentID else { throw NetworkError.notFound }
        let doc = try await docsService.getDocument(id: id)
        let novelDescriptor = FetchDescriptor<Novel>(predicate: #Predicate { $0.id == id })
        let novel: Novel
        if let existing = try context.fetch(novelDescriptor).first {
            novel = existing
        } else {
            novel = Novel(id: id, title: doc.title, author: "Google Docs")
            context.insert(novel)
        }

        let drafts = parser.parseChapters(document: doc)
        let draftIDs = Set(drafts.map(\.id))
        for staleChapter in novel.chapters where !draftIDs.contains(staleChapter.id) {
            context.delete(staleChapter)
        }

        for draft in drafts {
            let chapterID = draft.id
            let chapterDescriptor = FetchDescriptor<Chapter>(predicate: #Predicate { $0.id == chapterID })
            let chapter: Chapter
            if let existing = try context.fetch(chapterDescriptor).first {
                chapter = existing
            } else {
                chapter = Chapter(id: draft.id, title: draft.title, content: draft.content)
                context.insert(chapter)
            }
            chapter.title = draft.title
            chapter.content = draft.content
            chapter.novel = novel
        }
        novel.title = doc.title
        novel.lastModified = Date()
        try context.save()
    }
    
    public func pushLocalChanges(for novel: Novel, context: ModelContext) async throws {
        guard novel.id == SupportedGoogleDocument.documentID else { throw NetworkError.notFound }
        let remote = try await docsService.getDocument(id: novel.id)
        let remoteChapters = parser.parseChapters(document: remote)
        var requests: [GoogleDocsRequest] = []
        for chapter in novel.chapters {
            let oldText = remoteChapters.first(where: { $0.id == chapter.id })?.content ?? ""
            requests.append(contentsOf: serializer.computeDiffAndSerialize(oldText: oldText, newText: chapter.content).map { request in
                request.withTabID(chapter.id)
            })
        }
        if !requests.isEmpty {
            _ = try await docsService.batchUpdate(id: novel.id, requests: requests, requiredRevisionId: remote.revisionId)
        }
    }
}