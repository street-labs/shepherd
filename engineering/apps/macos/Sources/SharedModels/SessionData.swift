import Foundation

/// Session data loaded from ~/.shepherd/sessions/<session-id>/
/// Implements: FR-crp-macos-slash-command-launch
public struct SessionData: Equatable, Codable, Sendable {
    public let sessionID: String
    public let workingDirectory: String?
    public let projectName: String?
    public let files: [SessionFile]
    public let reviewContext: ReviewContext?

    public init(
        sessionID: String,
        workingDirectory: String? = nil,
        projectName: String? = nil,
        files: [SessionFile] = [],
        reviewContext: ReviewContext? = nil
    ) {
        self.sessionID = sessionID
        self.workingDirectory = workingDirectory
        self.projectName = projectName
        self.files = files
        self.reviewContext = reviewContext
    }

    public struct SessionFile: Equatable, Codable, Sendable {
        public let path: String
        public let content: String

        public init(path: String, content: String) {
            self.path = path
            self.content = content
        }
    }
}
