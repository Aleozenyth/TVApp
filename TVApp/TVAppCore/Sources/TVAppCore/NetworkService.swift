import Foundation
#if canImport(FoundationNetworking)
// URLSession lives in a separate module on non-Darwin platforms (Linux, and
// the official Swift toolchain for Windows). This #if is what lets this exact
// file compile unmodified with `swift test` on Windows/Linux AND inside Xcode.
import FoundationNetworking
#endif

// MARK: - NetworkError

/// Everything that can go wrong talking to TVMaze. Kept `Equatable` so tests can
/// assert on the exact case instead of parsing `localizedDescription` strings.
public enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed
    case transportError(String)
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL could not be constructed."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .httpError(let statusCode):
            return "The server returned an error (status code \(statusCode))."
        case .decodingFailed:
            return "The data received could not be understood."
        case .transportError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Endpoint

/// Describes a single TVMaze call. Adding a new endpoint never touches transport code.
public struct Endpoint {
    public let path: String
    public let queryItems: [URLQueryItem]

    public var url: URL? {
        var components = URLComponents(string: "https://api.tvmaze.com" + path)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        return components?.url
    }
}

public extension Endpoint {
    static func shows(page: Int) -> Endpoint {
        Endpoint(path: "/shows", queryItems: [URLQueryItem(name: "page", value: String(page))])
    }

    static func show(id: Int) -> Endpoint {
        Endpoint(path: "/shows/\(id)", queryItems: [])
    }
}

// MARK: - NetworkServicing

/// Abstraction over the transport layer so higher layers (ShowService, ViewModels)
/// can be unit-tested without ever touching `URLSession`.
public protocol NetworkServicing: Sendable {
    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

// MARK: - NetworkService

/// Thin wrapper around `URLSession` + Swift Concurrency. No 3rd-party dependency —
/// Foundation's async `data(from:)` is enough for this scope.
public final class NetworkService: NetworkServicing {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    public func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            // Covers offline, timeout, DNS failure, cancellation, etc.
            throw NetworkError.transportError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}
