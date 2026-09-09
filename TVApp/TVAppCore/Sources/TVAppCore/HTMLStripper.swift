import Foundation

/// Strips HTML tags (`<p>`, `<b>`, `<i>`, etc.) from TVMaze's `summary` field and
/// decodes the handful of HTML entities TVMaze actually emits.
///
/// Runs off the main thread via `Task.detached` so a long summary never blocks
/// scrolling or animation on the Detail screen.
///
/// Trade-off (see AI_LOG.md): this is a regex-based stripper, not a full HTML
/// parser. `NSAttributedString(data:options:[.documentType: .html], ...)` was
/// deliberately avoided because it is not guaranteed thread-safe for background
/// use and pulls in WebKit under the hood. The regex approach is safe to run
/// concurrently but will not correctly handle malformed/nested markup, HTML
/// comments, or numeric character references (e.g. `&#x2019;`). Acceptable for
/// TVMaze's simple <p>/<b>/<i> summaries, not a general-purpose HTML sanitizer.
public enum HTMLStripper {
    public static func strip(_ html: String) async -> String {
        guard !html.isEmpty else { return "" }
        return await Task.detached(priority: .userInitiated) {
            stripSync(html)
        }.value
    }

    /// Pure, synchronous, thread-safe (no shared mutable state) — safe to run on
    /// any thread/queue, which is what makes offloading it via `Task.detached` valid.
    private static func stripSync(_ html: String) -> String {
        var result = html.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        let entities: [String: String] = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&nbsp;": " "
        ]
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
