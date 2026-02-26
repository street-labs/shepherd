import Foundation
import ComposableArchitecture
import SharedModels

/// File system operations.
/// Implements: FR-crp-file-load, FR-crp-macos-file-open-panel,
/// FR-crp-macos-drag-drop-finder, FR-crp-macos-sandboxed-file-access
public struct FileClient: Sendable {
    /// Read a file's content. Returns (content, fileName, url).
    public var readFile: @Sendable (URL) async throws -> (String, String, URL)
    /// Check if a file is binary by scanning for null bytes in the first 8192 bytes.
    public var isBinaryFile: @Sendable (URL) async throws -> Bool
    /// Read all files from a list of URLs. Filters out binary files.
    public var readFiles: @Sendable ([URL]) async throws -> [(content: String, name: String, url: URL)]

    public init(
        readFile: @escaping @Sendable (URL) async throws -> (String, String, URL),
        isBinaryFile: @escaping @Sendable (URL) async throws -> Bool,
        readFiles: @escaping @Sendable ([URL]) async throws -> [(content: String, name: String, url: URL)]
    ) {
        self.readFile = readFile
        self.isBinaryFile = isBinaryFile
        self.readFiles = readFiles
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
            var results: [(content: String, name: String, url: URL)] = []
            for url in urls {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                let scanLength = min(data.count, 8192)
                let isBinary = data.prefix(scanLength).contains(0x00)
                guard !isBinary else { continue }
                guard let content = String(data: data, encoding: .utf8) else { continue }
                results.append((content, url.lastPathComponent, url))
            }
            return results
        }
    )

    public static let testValue = FileClient(
        readFile: unimplemented("FileClient.readFile"),
        isBinaryFile: unimplemented("FileClient.isBinaryFile"),
        readFiles: unimplemented("FileClient.readFiles")
    )
}

extension DependencyValues {
    public var fileClient: FileClient {
        get { self[FileClient.self] }
        set { self[FileClient.self] = newValue }
    }
}
