import SwiftUI
import SharedModels

/// Maps coarse token types to colors for the code viewer. Uses semantic system
/// colors so it reads acceptably in both light and dark appearance.
enum SyntaxTheme {
    static func color(for type: SyntaxToken.TokenType) -> Color? {
        switch type {
        case .keyword: return .pink
        case .string: return Color(red: 0.70, green: 0.25, blue: 0.20)
        case .comment: return .secondary
        case .number: return .orange
        case .type: return .teal
        case .function: return .blue
        case .property: return .purple
        case .operator: return .secondary
        case .punctuation: return .secondary
        case .variable, .plain: return nil
        }
    }
}

/// Build one colored `AttributedString` per source line from absolute-range tokens.
/// Done once per (file, tokens) change; `LineView` then renders the prebuilt line.
/// Returns plain (uncolored) lines when there are no tokens.
/// Implements: FR-crp-syntax-highlight
func buildLineAttributedStrings(content: String, tokens: [SyntaxToken]) -> [AttributedString] {
    let lineRanges = lineRanges(of: content)

    guard !tokens.isEmpty else {
        return lineRanges.map { AttributedString(String(content[$0])) }
    }

    // Distribute each token across the line(s) it covers, clipped to each line.
    // Token order is preserved (highlighter sorts broad-first) so that within a
    // line the narrower/more-specific run is applied last and wins on overlap.
    var runsPerLine = [[(range: Range<String.Index>, type: SyntaxToken.TokenType)]](
        repeating: [], count: lineRanges.count
    )
    for token in tokens {
        guard var li = lineIndex(for: token.range.lowerBound, in: lineRanges) else { continue }
        while li < lineRanges.count {
            let lr = lineRanges[li]
            let low = Swift.max(token.range.lowerBound, lr.lowerBound)
            let high = Swift.min(token.range.upperBound, lr.upperBound)
            if low < high {
                runsPerLine[li].append((low..<high, token.type))
            }
            if token.range.upperBound <= lr.upperBound { break }
            li += 1
        }
    }

    var result: [AttributedString] = []
    result.reserveCapacity(lineRanges.count)
    for (i, lr) in lineRanges.enumerated() {
        var attr = AttributedString(String(content[lr]))
        for run in runsPerLine[i] {
            guard let color = SyntaxTheme.color(for: run.type) else { continue }
            let localStart = content.distance(from: lr.lowerBound, to: run.range.lowerBound)
            let localCount = content.distance(from: run.range.lowerBound, to: run.range.upperBound)
            let aStart = attr.index(attr.startIndex, offsetByCharacters: localStart)
            let aEnd = attr.index(aStart, offsetByCharacters: localCount)
            attr[aStart..<aEnd].foregroundColor = color
        }
        result.append(attr)
    }
    return result
}

/// The `Range<String.Index>` of each line (newline-delimited), matching the line
/// count of `content.components(separatedBy: "\n")`.
private func lineRanges(of content: String) -> [Range<String.Index>] {
    var ranges: [Range<String.Index>] = []
    var lineStart = content.startIndex
    var idx = content.startIndex
    while idx < content.endIndex {
        if content[idx] == "\n" {
            ranges.append(lineStart..<idx)
            lineStart = content.index(after: idx)
        }
        idx = content.index(after: idx)
    }
    ranges.append(lineStart..<content.endIndex)
    return ranges
}

/// Binary-search the line whose range contains `pos` (a line's trailing newline
/// position belongs to no line, so tokens never start there).
private func lineIndex(for pos: String.Index, in ranges: [Range<String.Index>]) -> Int? {
    var lo = 0
    var hi = ranges.count - 1
    while lo <= hi {
        let mid = (lo + hi) / 2
        let r = ranges[mid]
        if pos < r.lowerBound {
            hi = mid - 1
        } else if pos >= r.upperBound && !(r.isEmpty && pos == r.lowerBound) {
            lo = mid + 1
        } else {
            return mid
        }
    }
    return nil
}
