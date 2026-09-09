import Foundation
import TVAppCore

@MainActor
final class ShowListViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[Show]> = .idle

    private let service: ShowServicing
    private let page: Int

    init(service: ShowServicing = ShowService(), page: Int = 0) {
        self.service = service
        self.page = page
    }

    func loadShows() async {
        state = .loading
        do {
            let shows = try await service.fetchShows(page: page)
            state = .success(shows)
        } catch let error as NetworkError {
            state = .failure(error.errorDescription ?? "Something went wrong.")
        } catch {
            state = .failure(error.localizedDescription)
        }
    }
}
