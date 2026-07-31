import Foundation

public protocol NetworkService {
    func request<T: Decodable>(endpoint: Endpoint) async throws -> T
    func requestRaw(endpoint: Endpoint) async throws -> Data
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}

public extension Endpoint {
    var queryItems: [URLQueryItem] { [] }
}

public enum NetworkError: LocalizedError {
    case invalidToken
    case invalidURL
    case noConnection
    case unauthorized
    case forbidden
    case notFound
    case revisionConflict
    case serverError
    case tooManyRequests(retryAfter: Int)
    case decodingError(Error)
    case unknown(statusCode: Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidToken: return "Phiên đăng nhập Google không hợp lệ hoặc đã hết hạn."
        case .revisionConflict: return "Tài liệu đã thay đổi trên Google Docs. Vui lòng đồng bộ lại trước khi lưu."
        case .noConnection: return "No internet connection."
        case .unauthorized: return "Session expired. Please log in again."
        case .serverError: return "Internal server error."
        default: return "An unexpected network error occurred."
        }
    }
}
