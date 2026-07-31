import Foundation

public enum GoogleDocsEndpoint: Endpoint {
    case getDocument(id: String)
    case batchUpdate(id: String, payload: Data)
    case listFiles(query: String)
    
    public var baseURL: URL {
        if case .listFiles = self {
            return URL(string: "https://www.googleapis.com/drive/v3")!
        }
        return URL(string: "https://docs.googleapis.com/v1")!
    }
    
    public var path: String {
        switch self {
        case .getDocument(let id): return "/documents/\(id)"
        case .batchUpdate(let id, _): return "/documents/\(id):batchUpdate"
        case .listFiles: return "/files"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .getDocument, .listFiles: return .get
        case .batchUpdate: return .post
        }
    }
    
    public var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    public var body: Data? {
        switch self {
        case .batchUpdate(_, let payload): return payload
        default: return nil
        }
    }
}
