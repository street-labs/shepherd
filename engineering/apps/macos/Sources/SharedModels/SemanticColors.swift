import SwiftUI

// Cross-platform semantic colors. `NSColor` call-sites are macOS-only; these
// helpers map the same intent to `UIColor` on iOS so shared feature views compile
// for both platforms without per-site `#if` guards.
extension Color {
    /// Faint label fill (macOS `.quaternaryLabelColor`, iOS `.quaternaryLabel`).
    public static var quaternaryLabelFill: Color {
        #if os(macOS)
        Color(nsColor: .quaternaryLabelColor)
        #else
        Color(uiColor: .quaternaryLabel)
        #endif
    }

    /// Window/sheet background (macOS `.windowBackgroundColor`, iOS `.systemBackground`).
    public static var windowBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    /// Text/code block background (macOS `.textBackgroundColor`, iOS `.secondarySystemBackground`).
    public static var textBackground: Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }
}
