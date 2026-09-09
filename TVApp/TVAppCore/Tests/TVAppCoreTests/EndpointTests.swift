import TVAppCore
import XCTest

final class EndpointTests: XCTestCase {

    func test_shows_buildsCorrectURLWithPageQueryItem() {
        let endpoint = Endpoint.shows(page: 3)
        XCTAssertEqual(endpoint.url?.absoluteString, "https://api.tvmaze.com/shows?page=3")
    }

    func test_show_buildsCorrectURLWithIdInPath() {
        let endpoint = Endpoint.show(id: 82)
        XCTAssertEqual(endpoint.url?.absoluteString, "https://api.tvmaze.com/shows/82")
    }
}
