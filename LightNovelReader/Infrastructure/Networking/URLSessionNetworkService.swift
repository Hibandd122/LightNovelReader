import Foundation

@MainActor
public final class URLSessionNetworkService: NetworkService {
    private let session: URLSession
    private let interceptor: AuthInterceptor?
    
    public init(session: URLSession? = nil, interceptor: AuthInterceptor? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.waitsForConnectivity = true
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 120
            self.session = URLSession(configuration: configuration)
        }
        self.interceptor = interceptor
    }
    
    public func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let data = try await requestRaw(endpoint: endpoint)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    public func requestRaw(endpoint: Endpoint) async throws -> Data {
        guard var components = URLComponents(url: endpoint.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems
        guard let requestURL = components.url else { throw NetworkError.invalidURL }
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = endpoint.method.rawValue
        
        if let headers = endpoint.headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = endpoint.body {
            urlRequest.httpBody = body
        }
        
        // Intercept to inject tokens if needed
        if let interceptor = interceptor {
            urlRequest = try await interceptor.adapt(urlRequest)
        }
        
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw NetworkError.noConnection
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(statusCode: 0)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            // Attempt to retry after refresh token
            if let interceptor = interceptor {
                let retryRequest = try await interceptor.retry(urlRequest)
                let (retryData, retryResponse) = try await session.data(for: retryRequest)
                guard let retryHTTP = retryResponse as? HTTPURLResponse, 200...299 ~= retryHTTP.statusCode else {
                    throw NetworkError.unauthorized
                }
                return retryData
            }
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 400:
            throw NetworkError.revisionConflict
        case 429:
            let retryAfter = Int(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "5") ?? 5
            throw NetworkError.tooManyRequests(retryAfter: retryAfter)
        case 500...599:
            throw NetworkError.serverError
        default:
            throw NetworkError.unknown(statusCode: httpResponse.statusCode)
        }
    }
}
