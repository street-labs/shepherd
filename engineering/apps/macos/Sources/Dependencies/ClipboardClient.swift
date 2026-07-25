#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import ComposableArchitecture

/// System pasteboard operations.
/// Implements: FR-crp-prompt-copy, FR-crp-macos-clipboard, FR-crp-ios-clipboard
@DependencyClient
public struct ClipboardClient: Sendable {
    /// Copy text to the system clipboard.
    public var copyText: @Sendable (String) async -> Void
    /// Read plain text from the system clipboard (for paste-to-load).
    public var readText: @Sendable () async -> String?
}

extension ClipboardClient: DependencyKey {
    public static let liveValue = ClipboardClient(
        copyText: { text in
            await MainActor.run {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                #elseif os(iOS)
                UIPasteboard.general.string = text
                #endif
            }
        },
        readText: {
            await MainActor.run {
                #if os(macOS)
                return NSPasteboard.general.string(forType: .string)
                #elseif os(iOS)
                return UIPasteboard.general.string
                #endif
            }
        }
    )

    public static let testValue = Self()
}

extension DependencyValues {
    public var clipboardClient: ClipboardClient {
        get { self[ClipboardClient.self] }
        set { self[ClipboardClient.self] = newValue }
    }
}
