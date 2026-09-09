import TVAppCore
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest

/// These tests stub the transport layer with `URLProtocol` instead of hitting
/// the real TVMaze API — so they run fully offline, on any platform, including
/// `swift test` on Windows with no internet connection at all.
final class NetworkServiceTests: XCTestCase {

    override func tearDown() {
        StubURLProtocol.stub = nil
        super.tearDown()
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    func test_fetch_onHTTPErrorStatus_throwsHttpError() async {
        StubURLProtocol.stub = .init(statusCode: 404, data: Data())
        let sut = NetworkService(session: makeSession())

        do {
            let _: [Show] = try await sut.fetch(.shows(page: 0))
            XCTFail("Expected to throw")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .httpError(statusCode: 404))
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }

    func test_fetch_onSuccessStatus_decodesPayload() async throws {
        let json = """
        [{"id":1,"name":"Test Show","summary":null,"premiered":null,"url":"https://example.com","image":null,"rating":null}]
        """.data(using: .utf8)!
        StubURLProtocol.stub = .init(statusCode: 200, data: json)
        let sut = NetworkService(session: makeSession())

        let shows: [Show] = try await sut.fetch(.shows(page: 0))
        XCTAssertEqual(shows.first?.name, "Test Show")
    }

    func test_fetch_onInvalidJSON_throwsDecodingFailed() async {
        StubURLProtocol.stub = .init(statusCode: 200, data: Data("not json".utf8))
        let sut = NetworkService(session: makeSession())

        do {
            let _: [Show] = try await sut.fetch(.shows(page: 0))
            XCTFail("Expected to throw")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
}

// MARK: - Stub

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Stub {
        let statusCode: Int
        let data: Data
    }

    static var stub: Stub?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let stub = StubURLProtocol.stub, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: stub.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
