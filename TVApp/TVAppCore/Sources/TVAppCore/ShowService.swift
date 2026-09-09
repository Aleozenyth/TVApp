import Foundation

/// Abstraction over show-related API calls. ViewModels depend on this protocol —
/// never on `ShowService` or `NetworkService` directly — so tests can inject a
/// lightweight mock instead of hitting the real TVMaze API.
public protocol ShowServicing: Sendable {
    func fetchShows(page: Int) async throws -> [Show]
    func fetchShowDetail(id: Int) async throws -> Show
}

public final class ShowService: ShowServicing {
    private let networkService: NetworkServicing

    public init(networkService: NetworkServicing = NetworkService()) {
        self.networkService = networkService
    }

    public func fetchShows(page: Int) async throws -> [Show] {
        try await networkService.fetch(.shows(page: page))
    }

    public func fetchShowDetail(id: Int) async throws -> Show {
        try await networkService.fetch(.show(id: id))
    }
}
