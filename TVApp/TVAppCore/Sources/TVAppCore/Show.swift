import Foundation

// MARK: - Show

/// Maps 1:1 to the payload returned by both `/shows?page={n}` and `/shows/{id}`.
/// TVMaze conveniently returns the *same* shape from both endpoints, which is why
/// a single model can serve the List and Detail screens.
public struct Show: Codable, Identifiable, Equatable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let summary: String?
    public let premiered: String?
    public let url: String
    public let image: ShowImage?
    public let rating: ShowRating?

    public init(
        id: Int,
        name: String,
        summary: String?,
        premiered: String?,
        url: String,
        image: ShowImage?,
        rating: ShowRating?
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.premiered = premiered
        self.url = url
        self.image = image
        self.rating = rating
    }
}

public struct ShowImage: Codable, Equatable, Hashable, Sendable {
    public let medium: String?
    public let original: String?

    public init(medium: String?, original: String?) {
        self.medium = medium
        self.original = original
    }
}

public struct ShowRating: Codable, Equatable, Hashable, Sendable {
    public let average: Double?

    public init(average: Double?) {
        self.average = average
    }
}

// MARK: - Convenience accessors

public extension ShowImage {
    var mediumURL: URL? { medium.flatMap(URL.init(string:)) }
    var originalURL: URL? { original.flatMap(URL.init(string:)) }
}

public extension ShowRating {
    /// Formats the rating for display, safely handling the `null` case documented
    /// by the TVMaze API for shows that haven't been rated yet.
    var formattedAverage: String? {
        guard let average else { return nil }
        return String(format: "%.1f", average)
    }
}
