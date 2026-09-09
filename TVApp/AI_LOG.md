# Part 2 — AI Usage Log

> Draft generated from my actual working session with Claude while building this
> project. I reviewed each entry and edited anything that didn't match what I
> actually kept/changed — this is meant to be an honest log, not a transcript.

## 1. Generating the full MVVM codebase

**Asked:** Full Swift/SwiftUI codebase (Models, NetworkService, ViewModels, Views,
Tests) for the TVMaze List/Detail/Share app, split by file, following clean MVVM.

**Got:** A complete multi-file project — protocol-based `NetworkServicing`/
`ShowServicing` for testability, a generic `ViewState<T>` enum shared by both
screens, and SwiftUI views using `AsyncImage` (no image-loading dependency needed).

**What I did:** Accepted the overall structure as-is. [Edit here if you changed
anything, e.g. renamed folders, changed the deployment target, etc.]

**Verified/got wrong:** The AI's claim that "no 3rd-party dependency is needed for
image loading" relies on `AsyncImage`, which is iOS 15+ only — I double-checked our
deployment target (iOS 16 for `NavigationStack` anyway) actually supports it before
trusting that claim.

## 2. Safe HTML stripping without blocking the UI

**Asked:** How to strip HTML tags from the `summary` field safely, without
blocking the main thread.

**Got:** A regex + manual HTML-entity-decoding utility run via `Task.detached`,
with an explicit trade-off note explaining why `NSAttributedString(html:)` was
*not* used (thread-safety concerns, pulls in WebKit).

**What I did:** Accepted, but I independently verified the specific limitation the
AI called out — the regex `<[^>]+>` genuinely does not decode numeric character
references like `&#x2019;`, and would mangle deliberately malformed markup. Logged
as a known limitation rather than taking the AI's word for it.

## 3. Avoiding a redundant network call on the Detail screen

**Asked:** Whether the Detail screen needs its own call to `/shows/{id}`, or can
reuse the data already fetched by the List screen.

**Got:** A dual-initializer `ShowDetailViewModel` — `init(show:)` when navigating
from the list (no network call), `init(showId:)` for a future deep-link path (does
fetch). Reasoning: TVMaze's `/shows?page=n` already returns the full show object.

**What I did:** Accepted the pattern, kept both initializers.

**One thing I verified myself:** I hit `https://api.tvmaze.com/shows?page=0`
manually to confirm `summary` and `image.original` really are present on every
item in the list response before trusting this "avoid the extra call" optimization
— the AI stated this as fact without me asking it to prove it.

## 4. Unit tests with a mock service

**Asked:** At least 2 unit tests covering ViewModel state changes and error handling.

**Got:** A `MockShowService` conforming to `ShowServicing` via `@unchecked Sendable`,
plus 6 tests across list/detail/HTML-stripping covering success, HTTP error,
transport error, and a retry-after-failure flow.

**What I did:** Accepted as-is.

**What the AI flagged (and I confirmed):** the `@unchecked Sendable` mock is only
safe under XCTest's default *sequential* execution — it would need an actor-based
rewrite if parallel test execution were ever turned on in the scheme. I left it as
sequential-only for this scope rather than over-engineering it.

## 5. Packaging the project and testing without a Mac

**Asked:** To bundle everything into a downloadable project folder, and how to
actually try running it without owning a Mac (I develop on Windows).

**Got:** A zipped project with an `XcodeGen` spec (`project.yml`) instead of a
hand-written `.xcodeproj`, plus a GitHub Actions workflow that builds/tests on a
macOS runner, and a rundown of cloud-Mac / iPad alternatives for the actual visual
demo.

**What I did:** [Fill in once you've actually tried the CI workflow / a cloud Mac —
did it work first try, or did you have to fix the simulator name in the workflow?]

**Important thing to note:** the AI was explicit that it cannot compile or run
Swift/Xcode itself (no macOS in its own environment) — it did not claim this code
was "verified to compile." I treated the whole submission as a strong starting
point to validate myself, not a guarantee.

## 6. Reviewing the deliberately broken sample ViewModel

**Asked:** To review the force-unwrapping, main-thread-blocking `MovieViewModel`
snippet from Part 3 of the assessment.

**Got:** A structured review flagging the `try!` crashes, the synchronous
`Data(contentsOf:)` call blocking the main thread, the missing `@Published`, and
the lack of dependency injection — see `CODE_REVIEW.md`.

**What I did:** Cross-checked each point against what I already knew about
SwiftUI's `ObservableObject`/`@Published` requirement and confirmed I agreed with
all of them before writing up `CODE_REVIEW.md` in my own words.

## 7. Testing with literally zero budget

**Asked:** How to test the app without spending any money at all (no MacinCloud,
no paid services), given I only have Windows.

**Got:** A restructuring into two modules — `TVAppCore` (a Combine-free Swift
Package with all the models/networking/HTML-stripping logic) that builds and
tests locally on Windows via the official `winget install --id Swift.Toolchain`,
plus a `core-ci.yml` GitHub Actions workflow on a free Linux runner, plus
reasoning for why the macOS `ios-ci.yml` runner is free specifically on *public*
repositories (verified against GitHub's current Actions pricing docs, not just
assumed from training data).

**What I did:** [Fill in once you've actually run `swift test` locally on
Windows and pushed to a public repo — note anything that didn't work as
described, especially around `FoundationNetworking`/`URLSession` availability.]

**Important thing to note:** the AI was upfront that it has no Windows machine
or GitHub account of its own to actually execute any of this — it explicitly
flagged the Linux/Windows `URLSession` async API as the most likely place for a
real gap between "should work" and "does work." I'm treating that as a specific,
falsifiable thing to check first rather than a vague disclaimer.
