import SwiftUI
import TVAppCore

struct ShowDetailView: View {
    @StateObject private var viewModel: ShowDetailViewModel
    @State private var isShareSheetPresented = false

    init(viewModel: ShowDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .task { await viewModel.loadIfNeeded() }
            .toolbar { toolbarContent }
            .sheet(isPresented: $isShareSheetPresented) {
                if case .success(let show) = viewModel.state {
                    ShareSheet(activityItems: shareItems(for: show))
                }
            }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if case .success = viewModel.state {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShareSheetPresented = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingStateView(message: "Loading details…")
        case .failure(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.retry() }
            }
        case .success(let show):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    posterImage(for: show)
                    Text(show.name)
                        .font(.title.bold())

                    if let premiered = show.premiered, !premiered.isEmpty {
                        Label(premiered, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Text(viewModel.strippedSummary.isEmpty
                         ? "No summary available."
                         : viewModel.strippedSummary)
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle(show.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func posterImage(for show: Show) -> some View {
        AsyncImage(url: show.image?.originalURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fit)
            case .failure, .empty:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        Image(systemName: "tv")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    )
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 260, maxHeight: 400)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func shareItems(for show: Show) -> [Any] {
        var items: [Any] = ["\(show.name)\n\n\(viewModel.strippedSummary)"]
        if let url = URL(string: show.url) {
            items.append(url)
        }
        return items
    }
}
