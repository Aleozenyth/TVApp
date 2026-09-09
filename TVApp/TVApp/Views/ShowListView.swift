import SwiftUI
import TVAppCore

struct ShowListView: View {
    @StateObject private var viewModel = ShowListViewModel()

    var body: some View {
        content
            .navigationTitle("TV Shows")
            .task {
                if case .idle = viewModel.state {
                    await viewModel.loadShows()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView(message: "Loading shows…")
        case .failure(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.loadShows() }
            }
        case .success(let shows):
            List(shows) { show in
                NavigationLink(value: show) {
                    ShowRowView(show: show)
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: Show.self) { show in
                ShowDetailView(viewModel: ShowDetailViewModel(show: show))
            }
        }
    }
}
