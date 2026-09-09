@testable import TVApp
import TVAppCore
import XCTest

@MainActor
final class ShowDetailViewModelTests: XCTestCase {

    func test_initWithShow_startsInSuccessState_withoutHittingNetwork() async {
        // Arrange
        let mock = MockShowService()
        let show = Show.mock(id: 42)
        let sut = ShowDetailViewModel(show: show, service: mock)

        // Act
        await sut.loadIfNeeded()

        // Assert: no network call should happen when data was passed in from the list.
        XCTAssertEqual(mock.fetchDetailCallCount, 0)
        guard case .success(let resultShow) = sut.state else {
            XCTFail("Expected .success state, got \(sut.state)")
            return
        }
        XCTAssertEqual(resultShow, show)
    }

    func test_initWithId_fetchesDetailAndStripsHTMLSummary() async {
        // Arrange
        let mock = MockShowService()
        let show = Show.mock(id: 7, summary: "<p>Strip <b>me</b>!</p>")
        mock.detailResult = .success(show)
        let sut = ShowDetailViewModel(showId: 7, service: mock)

        // Act
        await sut.loadIfNeeded()

        // Assert
        XCTAssertEqual(mock.fetchDetailCallCount, 1)
        guard case .success = sut.state else {
            XCTFail("Expected .success state, got \(sut.state)")
            return
        }
        XCTAssertEqual(sut.strippedSummary, "Strip me!")
    }

    func test_retry_afterFailure_transitionsBackToSuccess() async {
        // Arrange
        let mock = MockShowService()
        mock.detailResult = .failure(NetworkError.httpError(statusCode: 404))
        let sut = ShowDetailViewModel(showId: 99, service: mock)
        await sut.loadIfNeeded()

        guard case .failure = sut.state else {
            XCTFail("Precondition failed: expected .failure before retry")
            return
        }

        // Act
        mock.detailResult = .success(Show.mock(id: 99))
        await sut.retry()

        // Assert
        guard case .success(let show) = sut.state else {
            XCTFail("Expected .success state after retry, got \(sut.state)")
            return
        }
        XCTAssertEqual(show.id, 99)
        XCTAssertEqual(mock.fetchDetailCallCount, 2)
    }
}
