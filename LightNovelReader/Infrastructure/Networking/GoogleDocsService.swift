import Foundation

public protocol GoogleDocsServiceProtocol {
    func getDocument(id: String) async throws -> GoogleDocsDocument
    func batchUpdate(id: String, requests: [GoogleDocsRequest], requiredRevisionId: String?) async throws -> GoogleDocsBatchUpdateResponse
}

public struct GoogleDocsService: GoogleDocsServiceProtocol {
    private let networkService: NetworkService
    
    public init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    public func getDocument(id: String) async throws -> GoogleDocsDocument {
        let endpoint = GoogleDocsEndpoint.getDocument(id: id)
        return try await networkService.request(endpoint: endpoint)
    }
    
    public func batchUpdate(id: String, requests: [GoogleDocsRequest], requiredRevisionId: String? = nil) async throws -> GoogleDocsBatchUpdateResponse {
        let payload = try JSONEncoder().encode(GoogleDocsBatchUpdatePayload(requests: requests, writeControl: requiredRevisionId.map { GoogleDocsWriteControl(requiredRevisionId: $0) }))
        let endpoint = GoogleDocsEndpoint.batchUpdate(id: id, payload: payload)
        return try await networkService.request(endpoint: endpoint)
    }
}

private struct GoogleDocsBatchUpdatePayload: Encodable {
    let requests: [GoogleDocsRequest]
    let writeControl: GoogleDocsWriteControl?
}

private struct GoogleDocsWriteControl: Encodable {
    let requiredRevisionId: String
}

// Minimal models for decoding
public struct GoogleDocsDocument: Decodable, Sendable {
    public let documentId: String
    public let title: String
    public let body: GoogleDocsBody?
    public let revisionId: String?
    public let tabs: [GoogleDocsTab]?
}

public struct GoogleDocsTab: Decodable, Sendable {
    public let tabProperties: GoogleDocsTabProperties
    public let documentTab: GoogleDocsDocumentTab?
}

public struct GoogleDocsTabProperties: Decodable, Sendable {
    public let tabId: String
    public let title: String
    public let index: Int?
}

public struct GoogleDocsDocumentTab: Decodable, Sendable {
    public let body: GoogleDocsBody?
}

public struct GoogleDocsBody: Decodable, Sendable {
    public let content: [StructuralElement]
}

public struct StructuralElement: Decodable, Sendable {
    public let paragraph: Paragraph?
    public let table: GoogleDocsTable?
}

public struct Paragraph: Decodable, Sendable {
    public let elements: [ParagraphElement]
    public let paragraphStyle: ParagraphStyle?
}

public struct ParagraphElement: Decodable, Sendable {
    public let textRun: TextRun?
}

public struct TextRun: Decodable, Sendable {
    public let content: String
    public let textStyle: TextStyle?
}

public struct ParagraphStyle: Decodable, Sendable {
    public let namedStyleType: String?
}

public struct TextStyle: Decodable, Sendable {
    public let bold: Bool?
    public let italic: Bool?
}

public struct GoogleDocsTable: Decodable, Sendable {}

// Encodables for updates
public struct GoogleDocsRequest: Encodable, Sendable {
    public let insertText: InsertTextRequest?
    public let deleteContentRange: DeleteContentRangeRequest?
}

public struct InsertTextRequest: Encodable, Sendable {
    public let text: String
    public let location: Location
}

public struct DeleteContentRangeRequest: Encodable, Sendable {
    public let range: RangeElement
}

public struct Location: Encodable, Sendable {
    public let index: Int
    public let tabId: String?

    public init(index: Int, tabId: String? = nil) {
        self.index = index
        self.tabId = tabId
    }
}

public struct RangeElement: Encodable, Sendable {
    public let startIndex: Int
    public let endIndex: Int
    public let tabId: String?

    public init(startIndex: Int, endIndex: Int, tabId: String? = nil) {
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.tabId = tabId
    }
}

public struct GoogleDocsBatchUpdateResponse: Decodable, Sendable {
    public let documentId: String
}
