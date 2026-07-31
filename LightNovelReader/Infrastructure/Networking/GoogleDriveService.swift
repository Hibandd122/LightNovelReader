import Foundation

public protocol GoogleDriveServiceProtocol {
    func listLightNovels() async throws -> GoogleDriveFileList
}

public struct GoogleDriveService: GoogleDriveServiceProtocol {
    private let networkService: NetworkService
    
    public init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    public func listLightNovels() async throws -> GoogleDriveFileList {
        // Only fetch Google Docs files
        let query = "mimeType='application/vnd.google-apps.document' and trashed=false"
        // Need to URL encode the query in real app
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = GoogleDocsEndpoint.listFiles(query: encodedQuery)
        return try await networkService.request(endpoint: endpoint)
    }
}

public struct GoogleDriveFileList: Decodable {
    public let files: [GoogleDriveFile]
}

public struct GoogleDriveFile: Decodable {
    public let id: String
    public let name: String
    public let mimeType: String
    public let modifiedTime: Date?
}
