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
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}

public enum NetworkError: LocalizedError {
    case invalidURL
    case noConnection
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case tooManyRequests(retryAfter: Int)
    case decodingError(Error)
    case unknown(statusCode: Int)
    
    public var errorDescription: String? {
        switch self {
        case .noConnection: return "No internet connection."
        case .unauthorized: return "Session expired. Please log in again."
        case .serverError: return "Internal server error."
        default: return "An unexpected network error occurred."
        }
    }
}
