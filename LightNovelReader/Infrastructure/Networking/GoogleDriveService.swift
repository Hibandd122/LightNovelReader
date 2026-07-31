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
        let folderId = "1g1ExSDNBmOo_UvW7yiktBkl265aHfJCs"
        let query = "'\(folderId)' in parents and mimeType='application/vnd.google-apps.document' and trashed=false"
        let endpoint = GoogleDocsEndpoint.listFiles(query: query)
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
