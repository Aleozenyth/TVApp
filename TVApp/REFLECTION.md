# Part 4 — Written Reflection

## 1. Which part of your submission are you least confident about, and why?

I am least confident about relying on regular expressions for HTML tag stripping in `HTMLStripper.swift` instead of a full document parser. While regex is lightweight, thread-safe, and runs off the main thread without pulling in WebKit, it inherently struggles with malformed nested tags or raw numeric character entities (e.g., `&#x2019;`). Given more time, I would write a custom lightweight `Scanner`-based HTML parser or integrate SwiftSoup.

## 2. Describe a moment during this project (or any past project) where you got completely stuck. What did you do, step by step?

During this project, while writing unit tests for `ShowListViewModel` under Swift Concurrency, my test assertions were executing before the asynchronous network calls fully updated the UI state, leading to false positives.
* **Step 1**: I isolated the issue by reproducing it with a single test case using `XCTest`.
* **Step 2**: I inspected thread execution and verified `@MainActor` task scheduling behavior.
* **Step 3**: I refactored the test suite to properly `await` the state update pipeline using Swift Concurrency primitives instead of relying on fixed sleep delays.
* **Step 4**: I verified that both success and failure state transitions updated deterministically before running assertions.

## 3. Imagine: it's Thursday, your task is due Friday, and you realize you misunderstood the requirement — half your work is wrong. What are you doing now?

1. **Immediate Communication**: Notify the tech lead or product manager immediately to raise visibility on the scope mismatch.
2. **Triage & Preserve**: Salvage core components that are correct (data models, base networking, state machines) and discard non-essential features.
3. **Execute Core MVP**: Prioritize delivering a robust 70% working application (working list, detail view, error states) over a messy, half-baked 100%.
4. **Post-Mortem**: Document the root cause of the misunderstanding to improve requirement clarification in future sprints.

## 4. Your mentor asks you to change an approach you believe is worse. What do you do?

1. **Active Listening**: Seek to understand their reasoning first—there may be architecture constraints, team standards, or maintenance overhead I haven't considered.
2. **Data-Driven Discussion**: Present my alternative objectively using trade-offs (e.g., performance impact, memory footprint, unit testing complexity).
3. **Align and Commit**: If the mentor still prefers their approach after reviewing the trade-offs, I defer to their judgment, implement it cleanly, and document the decision in code comments.

## 5. What's something technical you taught yourself recently outside of class/work, and how did you learn it?

I recently taught myself modern Swift Concurrency (`async/await`, `Actors`, and `@MainActor` isolation). I learned it by reading Apple's official WWDC documentation, refactoring legacy completion-handler networking logic into modern async pipelines, and building modular Swift Packages to test cross-platform execution.