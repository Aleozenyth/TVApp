@testable import TVApp
import TVAppCore
import XCTest

@MainActor
final class ShowListViewModelTests: XCTestCase {

    func test_loadShows_onSuccess_updatesStateToSuccessWithShows() async {
        // Arrange
        let mock = MockShowService()
        let expectedShows = [Show.mock(id: 1, name: "Breaking Bad"), Show.mock(id: 2, name: "Better Call Saul")]
        mock.showsResult = .success(expectedShows)
        let sut = ShowListViewModel(service: mock)

        // Act
        await sut.loadShows()

        // Assert
        guard case .success(let shows) = sut.state else {
            XCTFail("Expected .success state, got \(sut.state)")
            return
        }
        XCTAssertEqual(shows, expectedShows)
        XCTAssertEqual(mock.fetchShowsCallCount, 1)
    }

    func test_loadShows_onHTTPError_updatesStateToFailureWithReadableMessage() async {
        // Arrange
        let mock = MockShowService()
        mock.showsResult = .failure(NetworkError.httpError(statusCode: 500))
        let sut = ShowListViewModel(service: mock)

        // Act
        await sut.loadShows()

        // Assert
        guard case .failure(let message) = sut.state else {
            XCTFail("Expected .failure state, got \(sut.state)")
            return
        }
        XCTAssertTrue(message.contains("500"), "Error message should surface the status code to the user")
    }

    func test_loadShows_onTransportError_mapsUnderlyingErrorMessage() async {
        // Arrange
        let mock = MockShowService()
        mock.showsResult = .failure(NetworkError.transportError("The Internet connection appears to be offline."))
        let sut = ShowListViewModel(service: mock)

        // Act
        await sut.loadShows()

        // Assert
        guard case .failure(let message) = sut.state else {
            XCTFail("Expected .failure state, got \(sut.state)")
            return
        }
        XCTAssertTrue(message.contains("offline"))
    }
}
