import Foundation
import ComposableArchitecture
import SharedModels

/// File system operations.
/// Implements: FR-crp-file-load, FR-crp-macos-file-open-panel,
/// FR-crp-macos-drag-drop-finder, FR-crp-macos-sandboxed-file-access
@DependencyClient
public struct FileClient: Sendable {
    /// Read a file's content. Returns (content, fileName, url).
    public var readFile: @Sendable (URL) async throws -> (String, String, URL)
    /// Check if a file is binary by scanning for null bytes in the first 8192 bytes.
    public var isBinaryFile: @Sendable (URL) async throws -> Bool
    /// Read all files from a list of URLs, reporting a per-file outcome so callers
    /// can surface which files failed and why (`FR-crp-macos-sandboxed-file-access`,
    /// `AC-crp-binary-file-rejected`, `AC-crp-macos-file-permission-error`).
    public var readFiles: @Sendable ([URL]) async throws -> [FileReadResult]
}

/// Per-file outcome of a batch read. Kept Equatable/Sendable so it can travel
/// through a TCA action back to the reducer.
public enum FileReadResult: Equatable, Sendable {
    case loaded(content: String, name: String, url: URL)
    case failed(name: String, reason: FileLoadFailureReason)
}

/// Why a file could not be loaded. Titles/messages match the design spec's
/// native-alert wording (design/macos/code-review-prompt.md, error states).
public enum FileLoadFailureReason: Equatable, Sendable {
    /// Contains null bytes or is not valid UTF-8 text.
    case notText
    case permissionDenied
    case readFailed

    public var alertTitle: String {
        switch self {
        case .notText: return "Cannot Open File"
        case .permissionDenied: return "Cannot Read File"
        case .readFailed: return "Failed to Read File"
        }
    }

    public var alertMessage: String {
        switch self {
        case .notText: return "This file does not appear to contain text. Only plain-text files are supported."
        case .permissionDenied: return "The file could not be read. Check that the application has permission to access this file."
        case .readFailed: return "An error occurred while reading the file. Please try again."
        }
    }

    /// Compact reason for listing several failed files in one alert.
    public var shortLabel: String {
        switch self {
        case .notText: return "not a text file"
        case .permissionDenied: return "permission denied"
        case .readFailed: return "could not be read"
        }
    }
}

public enum FileClientError: Error, LocalizedError {
    case notTextFile
    case permissionDenied
    case readFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .notTextFile: return "This file does not appear to contain text."
        case .permissionDenied: return "The file could not be read. Check permissions."
        case .readFailed(let e): return "Failed to read file: \(e.localizedDescription)"
        }
    }
}

extension FileClient: DependencyKey {
    public static let liveValue = FileClient(
        readFile: { url in
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) else {
                throw FileClientError.notTextFile
            }
            return (content, url.lastPathComponent, url)
        },
        isBinaryFile: { url in
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let scanLength = min(data.count, 8192)
            return data.prefix(scanLength).contains(0x00)
        },
        readFiles: { urls in
            var results: [FileReadResult] = []
            for url in urls {
                let name = url.lastPathComponent
                let data: Data
                do {
                    data = try Data(contentsOf: url, options: .mappedIfSafe)
                } catch {
                    let nsError = error as NSError
                    let isPermission =
                        (nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoPermissionError)
                        || (nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(EACCES))
                    results.append(.failed(name: name, reason: isPermission ? .permissionDenied : .readFailed))
                    continue
                }
                let scanLength = min(data.count, 8192)
                let isBinary = data.prefix(scanLength).contains(0x00)
                guard !isBinary, let content = String(data: data, encoding: .utf8) else {
                    results.append(.failed(name: name, reason: .notText))
                    continue
                }
                results.append(.loaded(content: content, name: name, url: url))
            }
            return results
        }
    )

    public static let testValue = Self()
}

extension DependencyValues {
    public var fileClient: FileClient {
        get { self[FileClient.self] }
        set { self[FileClient.self] = newValue }
    }
}
