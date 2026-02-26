import AppKit
import ComposableArchitecture

/// System pasteboard operations.
/// Implements: FR-crp-prompt-copy, FR-crp-macos-clipboard
public struct ClipboardClient: Sendable {
    /// Copy text to the system clipboard.
    public var copyText: @Sendable (String) async -> Void
    /// Read plain text from the system clipboard (for paste-to-load).
    public var readText: @Sendable () async -> String?

    public init(
        copyText: @escaping @Sendable (String) async -> Void,
        readText: @escaping @Sendable () async -> String?
    ) {
        self.copyText = copyText
        self.readText = readText
    }
}

extension ClipboardClient: DependencyKey {
    public static let liveValue = ClipboardClient(
        copyText: { text in
            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
        },
        readText: {
            await MainActor.run {
                NSPasteboard.general.string(forType: .string)
            }
        }
    )

    public static let testValue = ClipboardClient(
        copyText: unimplemented("ClipboardClient.copyText"),
        readText: unimplemented("ClipboardClient.readText")
    )
}

extension DependencyValues {
    public var clipboardClient: ClipboardClient {
        get { self[ClipboardClient.self] }
        set { self[ClipboardClient.self] = newValue }
    }
}
