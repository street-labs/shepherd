import Testing
import SwiftUI
import ComposableArchitecture
import SnapshotTesting
import SharedModels
@testable import AppFeature

// Demo screenshot capture — NOT a normal test suite.
//
// It renders AppView in a few representative states and records PNGs, which
// `scripts/capture-demos.sh` then copies into `docs/demos/` for the README.
//
// Guarded by CAPTURE_DEMOS=1 so a normal `swift test` (and CI) skips it entirely
// — it never asserts against reference images, it only *records* them.
//
// macOS note: there is no SwiftUI `.image` snapshot strategy on macOS, so each
// view is hosted in an NSHostingController (an NSViewController) and captured
// with the NSViewController image strategy. Complex AppKit-backed subviews (the
// code viewer) render most reliably at a generous fixed size.
@MainActor
@Suite(
  "Demo capture",
  .enabled(if: ProcessInfo.processInfo.environment["CAPTURE_DEMOS"] == "1")
)
struct DemoCaptureTests {
  private let size = CGSize(width: 1440, height: 900)

  private func capture(_ view: some View, named name: String) {
    let host = NSHostingController(rootView: view.frame(width: size.width, height: size.height))
    host.view.frame = CGRect(origin: .zero, size: size)
    // record: .all → always (re)write the PNG rather than compare.
    withSnapshotTesting(record: .all) {
      assertSnapshot(of: host, as: .image(size: size), named: name)
    }
  }

  private let sampleTS = """
  export function greet(name: string): string {
    // returns a greeting for the given name
    return `Hello, ${name}!`
  }

  export const DEFAULT_GREETING = greet("world")
  """

  private let sampleConfig = """
  export const MAX_RETRIES = 3
  export const TIMEOUT_MS = 5_000
  export const BASE_URL = "https://example.test"
  """

  // Single file, one inline comment — the core annotate flow.
  @Test func annotate() {
    let fileID = UUID()
    let file = FileNode(
      id: fileID, name: "greeter.ts", filePath: "src/greeter.ts",
      language: .typescript, content: sampleTS
    )
    let comment = Comment(
      fileID: fileID, startLine: 3, endLine: 3,
      text: "An empty name should throw rather than return \"Hello, !\"."
    )
    let store = Store(
      initialState: AppFeature.State(files: [file], allComments: [comment], activeFileID: fileID)
    ) { AppFeature() }
    capture(AppView(store: store), named: "annotate")
  }

  // Multi-file review session with the agent's self-review attached — /shepherd-review.
  @Test func shepherdReview() {
    let f1 = UUID(); let f2 = UUID()
    let file1 = FileNode(
      id: f1, name: "greeter.ts", filePath: "src/greeter.ts",
      language: .typescript, content: sampleTS
    )
    let file2 = FileNode(
      id: f2, name: "config.ts", filePath: "src/config.ts",
      language: .typescript, content: sampleConfig
    )
    var state = AppFeature.State(files: [file1, file2], activeFileID: f1)
    state.reviewContextData = ReviewContext(
      overall: .init(
        neutral: "Adds a greeting helper and a small config module.",
        review: "Looks reasonable; the greeting helper needs empty-input handling."
      ),
      files: [
        "src/greeter.ts": .init(
          neutral: "New greet() helper and a DEFAULT_GREETING export.",
          review: "greet() doesn't guard an empty name — consider throwing."
        ),
        "src/config.ts": .init(
          neutral: "Introduces retry, timeout, and base-URL constants.",
          review: "Consider sourcing BASE_URL from the environment."
        ),
      ]
    )
    let store = Store(initialState: state) { AppFeature() }
    capture(AppView(store: store), named: "shepherd-review")
  }
}
