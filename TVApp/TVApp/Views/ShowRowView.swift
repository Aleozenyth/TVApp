import SwiftUI
import TVAppCore

struct ShowRowView: View {
    let show: Show

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            posterImage
            VStack(alignment: .leading, spacing: 6) {
                Text(show.name)
                    .font(.headline)
                    .lineLimit(2)
                ratingView
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var posterImage: some View {
        AsyncImage(url: show.image?.mediumURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure, .empty:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .frame(width: 60, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .background(Color(.secondarySystemBackground))
    }

    private var placeholder: some View {
        Image(systemName: "tv")
            .resizable()
            .scaledToFit()
            .padding(14)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var ratingView: some View {
        // rating.average can be null per TVMaze docs — handled explicitly here.
        if let formatted = show.rating?.formattedAverage {
            Label(formatted, systemImage: "star.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
        } else {
            Text("Not rated")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
