# TV Show Browser — iOS (Swift + SwiftUI)

A small TVMaze browser app: a List screen, a Detail screen, and a native share action.
Built with pure Swift/SwiftUI/Swift Concurrency — no 3rd-party dependencies.

## Features

- **List screen** — `GET /shows?page=0`, shows poster (`image.medium`), title, rating
  (`rating.average`, safely handling `null`).
- **Detail screen** — larger poster (`image.original`), title, premiere date, and an
  HTML-stripped summary.
- **Share action** — native `UIActivityViewController` with title, summary, and the
  show's TVMaze URL.
- **Three explicit UI states** everywhere: `loading`, `error` (with retry), `success`.

## Architecture

MVVM, split into standard layers — and split into **two modules**, which is what
makes the $0 testing story below possible:

```
TVApp/                      (repo root)
├── TVAppCore/               Local Swift Package — NO Combine/SwiftUI/UIKit import.
│   ├── Package.swift        Buildable/testable with plain `swift build`/`swift test`
│   ├── Sources/TVAppCore/   on Linux and on the official Swift toolchain for Windows.
│   │   ├── Show.swift          Show, ShowImage, ShowRating (Codable models)
│   │   ├── ViewState.swift     Generic idle/loading/success/failure state
│   │   ├── NetworkService.swift Endpoint, NetworkError, NetworkServicing/NetworkService
│   │   ├── ShowService.swift    ShowServicing/ShowService (TVMaze API calls)
│   │   └── HTMLStripper.swift   Off-main-thread HTML tag stripping
│   └── Tests/TVAppCoreTests/    HTMLStripperTests, EndpointTests, NetworkServiceTests
│                                (network layer stubbed with URLProtocol — no real network)
│
├── TVApp/                   iOS app target (needs Xcode/macOS to build)
│   ├── App/                 App entry point (WindowGroup + NavigationStack root)
│   ├── ViewModels/          ShowListViewModel, ShowDetailViewModel (@MainActor,
│   │                        ObservableObject — the only place Combine is used)
│   └── Views/                SwiftUI views + reusable Loading/Error/ShareSheet
│
└── TVAppTests/               ViewModel tests (also need Xcode/macOS — see below)
```

Key decisions:

- **Protocol-oriented DI.** `ShowListViewModel`/`ShowDetailViewModel` depend on
  `ShowServicing`, not on a concrete network type — this is what makes them
  unit-testable with `MockShowService` (see `TVAppTests/`).
- **Generic `ViewState<T>`.** Both screens share one state machine
  (`idle`/`loading`/`success`/`failure`) instead of duplicating boolean flags.
- **Detail screen has two initializers.** Navigating from the List screen passes
  the already-fetched `Show` (TVMaze's list endpoint already returns the full
  payload — summary, `image.original`, `premiered` included), avoiding a
  redundant network call. A second initializer (`showId:`) exists for future
  deep-linking, which does hit `/shows/{id}`.
- **HTML stripping is regex-based, not `NSAttributedString`.** See the doc
  comment in `HTMLStripper.swift` and `AI_LOG.md` for the reasoning and the
  known limitation (doesn't handle malformed markup or numeric entities).

## How to Run

### If you have a Mac

1. Install Xcode 15+ (Mac App Store).
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. From the repo root: `xcodegen generate` → produces `TVApp.xcodeproj`
4. Open `TVApp.xcodeproj`, pick an iPhone simulator, `Cmd+R` to run, `Cmd+U` to test.

Command-line equivalent:
```bash
xcodegen generate
xcodebuild test -project TVApp.xcodeproj -scheme TVApp \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### If you don't have a Mac, and don't want to spend anything at all

Building and running the actual iOS app UI *requires* Xcode, which only runs on
macOS — there is no way around that for the final "app running on a simulator"
part. But every step *up to* that point can be done for $0, on Windows, today:

**1. Test the core logic locally on Windows — free, instant, no cloud.**
The `TVAppCore` package deliberately has zero Combine/SwiftUI/UIKit imports, so
the official Swift toolchain for Windows can build and test it directly:

```powershell
winget install --id Swift.Toolchain -e --source winget
# also needs the C++ toolchain + Windows SDK — winget install --id Microsoft.VisualStudio.2022.Community ...
# (see the "Windows" install guide at https://www.swift.org/install/windows/)

cd TVAppCore
swift test
```

This alone verifies the riskiest logic in the project — JSON decoding, HTTP
status → error mapping, URL construction, and HTML stripping — with real,
offline unit tests (`NetworkServiceTests` stubs the network with `URLProtocol`,
so nothing here needs an internet connection either). No Mac, no cloud, no CI
wait, $0.

**2. Let CI verify the rest, on a free GitHub-hosted runner.**
- `.github/workflows/core-ci.yml` runs the same `swift test` above on a Linux
  runner. Standard Linux runners are free on every GitHub plan (private repos
  included), so this workflow costs nothing regardless of repo visibility.
- `.github/workflows/ios-ci.yml` runs the *full* Xcode build + XCTest suite
  (including the `ObservableObject`-based ViewModel tests) on a macOS runner.
  **Make the repo public** and this is free too — GitHub does not meter standard
  macOS runner minutes on public repositories at all (only private repos have
  the monthly minutes quota, and macOS minutes there count at 10x). A public
  repo is normally fine for this kind of assessment submission anyway.

**3. Get an actual simulator recording without ever opening Xcode yourself.**
Add a step to `ios-ci.yml` that boots the simulator and records the screen
while an XCUITest taps through List → Detail → Share:
```yaml
- name: Record simulator video
  run: |
    xcrun simctl boot "iPhone 15" || true
    xcrun simctl io booted recordVideo demo.mp4 &
    RECORD_PID=$!
    xcodebuild test -project TVApp.xcodeproj -scheme TVApp \
      -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
    kill $RECORD_PID
- uses: actions/upload-artifact@v4
  with:
    name: simulator-demo
    path: demo.mp4
```
Download `demo.mp4` from the workflow run's Artifacts tab — that's real, on-device
footage of your app running, produced entirely by GitHub's free macOS runner.

**4. Turn that into your Part 5 walkthrough video — still free.**
Play `demo.mp4` back on your Windows screen and record yourself narrating over
it (explaining the code, pointing out the AI-driven decisions) using
[OBS Studio](https://obsproject.com) — free, open-source, runs natively on
Windows. That satisfies "record your screen + voice" without ever touching a
Mac or a paid service.

**If you'd rather see it live instead of pre-recorded:** borrow a Mac (a friend,
a campus/library lab), or if you own an iPad, the free **Swift Playgrounds** app
(iPadOS 17+) can build and run full SwiftUI App projects — including the share
sheet — directly on-device, with the built-in screen recorder for narration.
That's the only fully-free path to a genuinely *live*, interactive demo.

Whichever route you use, push commits as you go — `core-ci.yml` gives you
feedback in under a minute on every push, long before `ios-ci.yml`'s slower
macOS job even finishes.

> **Caveat I can't verify myself:** I don't have a Windows machine or a GitHub
> account to actually run any of the commands above — I've reasoned through them
> carefully (and checked GitHub's current Actions pricing docs before writing
> this), but you should treat the `winget`/`swift test`/CI YAML as a strong
> starting point to debug against, not a guarantee. The most likely snag is a
> Foundation API gap between Apple's URLSession and the Linux/Windows
> `FoundationNetworking` implementation used by `NetworkServiceTests` — if
> `swift test` fails specifically there, that's the first place to look.

## What I'd Improve With More Time

- Pagination beyond page 0, and the optional season/episode/cast bonus on Detail.
- A small in-memory or disk image cache (currently relying on `AsyncImage`'s
  default `URLCache` behavior — fine for a demo, not tuned for production).
- Parse `premiered` into a `Date` and format it with the user's locale, instead of
  displaying the raw `"2008-01-20"` string.
- Distinguish rate-limiting (HTTP 429) with its own retry-with-backoff message.
- Replace the regex-based `HTMLStripper` with a proper (still main-thread-safe)
  HTML parser if summaries ever get more complex than `<p>/<b>/<i>`.
- XCUITest coverage for the actual share-sheet flow and navigation, on top of the
  ViewModel-level unit tests.
- Accessibility pass: Dynamic Type sizing on the poster images, explicit
  `accessibilityLabel`s for rating/poster elements.
