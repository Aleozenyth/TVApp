# Part 3 — AI Code Review Exercise

Reviewing (iOS / Swift):

```swift
class MovieViewModel: ObservableObject {
    var movies: [Movie] = []
    func loadMovies() {
        let data = try! Data(contentsOf: URL(string: "https://api.example.com/movies")!)
        movies = try! JSONDecoder().decode([Movie].self, from: data)
    }
}
```

## Problems and fixes

1. **`try!` on the network call — crashes the app on any failure.**
   Offline, a 500 response, a timeout — anything at all — and `Data(contentsOf:)`
   throws, which `try!` turns into an immediate, unrecoverable crash. There is no
   error path at all.
   **Fix:** `do`/`catch` (or `async throws`) and surface failures through a state
   the view can render — e.g. this project's `ViewState<T>.failure(String)`.

2. **`try!` on `JSONDecoder().decode` — same problem, different failure mode.**
   Any malformed/unexpected JSON body (including an HTML error page returned by a
   misconfigured server) crashes decoding instead of producing a handled error.
   **Fix:** same `do`/`catch`, and check the HTTP status code *before* attempting
   to decode the body as the success type.

3. **`Data(contentsOf:)` on a remote URL is synchronous and blocking.**
   Called from a SwiftUI action on the main thread, this freezes the entire UI —
   no scrolling, no animations, no responsiveness — until the request completes.
   On a slow connection this risks the watchdog killing the app.
   **Fix:** `URLSession.shared.data(from:)` (async) or the completion-handler API
   dispatched off the main thread — never a blocking `Data(contentsOf:)` call to a
   network URL.

4. **`URL(string: ...)!` force-unwrapped.**
   Here the string is a literal so it happens to always succeed, but this teaches
   an unsafe pattern that becomes a real crash risk the moment the URL is built
   dynamically (user input, config value, etc.).
   **Fix:** `guard let url = URL(string: ...) else { throw ... }`, or a validated
   `static let` constant with a unit test asserting it's non-nil.

5. **`movies` is not `@Published`.**
   Without `@Published`, mutating `movies` never triggers `objectWillChange` —
   any SwiftUI view observing this `ObservableObject` simply won't update.
   **Fix:** `@Published private(set) var movies: [Movie] = []`.

6. **No `@MainActor` isolation.**
   If `loadMovies()` is ever made `async` and does work off the main thread (as it
   should, per point 3), nothing here enforces that `movies` is only ever mutated
   on the main actor — a data race waiting to happen once concurrency is
   introduced.
   **Fix:** mark the class `@MainActor`.

7. **Hard-coded URL, no dependency injection.**
   The ViewModel owns its own networking logic and URL directly, so it cannot be
   unit-tested without hitting a real (and here, clearly placeholder) endpoint,
   and cannot be mocked.
   **Fix:** inject a `MovieServicing` protocol (mirrors `ShowServicing` in this
   project) so tests can substitute a mock.

8. **No loading/error UI state at all.**
   `loadMovies()` is fire-and-forget with no way for a view to know it's in
   progress or that it failed — violates the assignment's explicit 3-state
   requirement (loading / error / success).
   **Fix:** back this with a `ViewState<[Movie]>` (or equivalent) that the view
   switches over.

9. **No cancellation handling.**
   Nothing stops `loadMovies()` from being called multiple times in a row (e.g.
   pull-to-refresh spam) and racing several outstanding requests against each
   other, with the last one to complete silently winning.
   **Fix:** use a `Task` handle the ViewModel can cancel before starting a new one,
   or Swift Concurrency's structured cancellation via `.task { }` in the view.

10. **No HTTP status check before decoding.**
    Even without the `try!`, decoding a 404/500 response body directly as
    `[Movie]` would either crash or silently produce misleading data if the error
    body happens to parse as valid (but wrong) JSON.
    **Fix:** validate `(response as? HTTPURLResponse)?.statusCode` is in the
    2xx range before attempting to decode.
