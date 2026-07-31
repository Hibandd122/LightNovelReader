import Foundation

public protocol GoogleDocsServiceProtocol {
    func getDocument(id: String) async throws -> GoogleDocsDocument
    func batchUpdate(id: String, requests: [GoogleDocsRequest]) async throws -> GoogleDocsBatchUpdateResponse
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
    
    public func batchUpdate(id: String, requests: [GoogleDocsRequest]) async throws -> GoogleDocsBatchUpdateResponse {
        let payload = try JSONEncoder().encode(["requests": requests])
        let endpoint = GoogleDocsEndpoint.batchUpdate(id: id, payload: payload)
        return try await networkService.request(endpoint: endpoint)
    }
}

// Minimal models for decoding
public struct GoogleDocsDocument: Decodable {
    public let documentId: String
    public let title: String
    public let body: GoogleDocsBody
    public let revisionId: String
}

public struct GoogleDocsBody: Decodable {
    public let content: [StructuralElement]
}

public struct StructuralElement: Decodable {
    public let paragraph: Paragraph?
    // other elements omitted for brevity
}

public struct Paragraph: Decodable {
    public let elements: [ParagraphElement]
}

public struct ParagraphElement: Decodable {
    public let textRun: TextRun?
}

public struct TextRun: Decodable {
    public let content: String
}

// Encodables for updates
public struct GoogleDocsRequest: Encodable {
    public let insertText: InsertTextRequest?
    public let deleteContentRange: DeleteContentRangeRequest?
}

public struct InsertTextRequest: Encodable {
    public let text: String
    public let location: Location
}

public struct DeleteContentRangeRequest: Encodable {
    public let range: RangeElement
}

public struct Location: Encodable {
    public let index: Int
}

public struct RangeElement: Encodable {
    public let startIndex: Int
    public let endIndex: Int
}

public struct GoogleDocsBatchUpdateResponse: Decodable {
    public let documentId: String
}
