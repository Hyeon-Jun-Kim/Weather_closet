import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
}

protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

final class APIClient: @unchecked Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func request<T: Decodable>(_ endpoint: any APIEndpoint) async throws -> T {
        guard var components = URLComponents(string: endpoint.baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        Log.d("HJHJ", "API 요청 - \(endpoint.method.rawValue) \(url.absoluteString)")
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                Log.e("HJHJ", "API 응답 오류 - HTTPURLResponse 변환 실패")
                throw APIError.invalidResponse
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                Log.e("HJHJ", "API HTTP 오류 - statusCode: \(httpResponse.statusCode), url: \(url.absoluteString)")
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }
            Log.d("HJHJ", "API 응답 성공 - statusCode: \(httpResponse.statusCode), dataSize: \(data.count) bytes")
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            Log.e("HJHJ", "API 오류 - \(error)")
            throw error
        } catch let error as DecodingError {
            Log.e("HJHJ", "API 디코딩 오류 - \(error)")
            throw APIError.decodingError(error)
        } catch {
            Log.e("HJHJ", "API 네트워크 오류 - \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
}
