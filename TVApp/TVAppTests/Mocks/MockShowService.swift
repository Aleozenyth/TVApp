import TVAppCore
import Foundation

/// Test double for `ShowServicing`. Lets us drive success/failure paths
/// deterministically, without touching the network.
///
/// Note: marked `@unchecked Sendable` so it satisfies the `ShowServicing: Sendable`
/// requirement, even though its stored `var` properties are technically mutable
/// from multiple call sites. This is safe as long as XCTest runs tests
/// sequentially (the default). If parallel test execution is ever enabled in the
/// scheme, this mock would need an actor-based rewrite. See AI_LOG.md.
final class MockShowService: ShowServicing, @unchecked Sendable {
    var showsResult: Result<[Show], Error> = .success([])
    var detailResult: Result<Show, Error> = .failure(NetworkError.invalidResponse)

    private(set) var fetchShowsCallCount = 0
    private(set) var fetchDetailCallCount = 0

    func fetchShows(page: Int) async throws -> [Show] {
        fetchShowsCallCount += 1
        return try showsResult.get()
    }

    func fetchShowDetail(id: Int) async throws -> Show {
        fetchDetailCallCount += 1
        return try detailResult.get()
    }
}

extension Show {
    /// Convenience factory so tests don't have to hand-construct every field.
    static func mock(
        id: Int = 1,
        name: String = "Breaking Bad",
        summary: String? = "<p>A chemistry teacher turns to crime.</p>",
        premiered: String? = "2008-01-20",
        url: String = "https://www.tvmaze.com/shows/1/breaking-bad",
        image: ShowImage? = ShowImage(medium: "https://example.com/medium.jpg", original: "https://example.com/original.jpg"),
        rating: ShowRating? = ShowRating(average: 9.5)
    ) -> Show {
        Show(id: id, name: name, summary: summary, premiered: premiered, url: url, image: image, rating: rating)
    }
}
