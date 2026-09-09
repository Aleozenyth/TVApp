import Foundation
import TVAppCore

@MainActor
final class ShowDetailViewModel: ObservableObject {
    @Published private(set) var state: ViewState<Show>
    @Published private(set) var strippedSummary: String = ""

    private let service: ShowServicing
    private let showId: Int

    /// Use when navigating from the List screen. TVMaze's `/shows` endpoint already
    /// returns the *full* Show payload (summary, premiered, image.original included),
    /// so there is no need to hit `/shows/{id}` again — avoids a redundant round trip.
    init(show: Show, service: ShowServicing = ShowService()) {
        self.showId = show.id
        self.service = service
        self.state = .success(show)
    }

    /// Use when only an id is available (e.g. deep link) and the full payload must
    /// be fetched from `/shows/{id}`.
    init(showId: Int, service: ShowServicing = ShowService()) {
        self.showId = showId
        self.service = service
        self.state = .loading
    }

    /// Called from the view's `.task` modifier. If we already have data (came from
    /// the list), just prepare the summary; otherwise fetch from the network.
    func loadIfNeeded() async {
        if case .success(let show) = state {
            await prepareSummary(for: show)
            return
        }
        await fetchDetail()
    }

    func retry() async {
        await fetchDetail()
    }

    private func fetchDetail() async {
        state = .loading
        do {
            let show = try await service.fetchShowDetail(id: showId)
            state = .success(show)
            await prepareSummary(for: show)
        } catch let error as NetworkError {
            state = .failure(error.errorDescription ?? "Something went wrong.")
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    private func prepareSummary(for show: Show) async {
        strippedSummary = await HTMLStripper.strip(show.summary ?? "")
    }
}
