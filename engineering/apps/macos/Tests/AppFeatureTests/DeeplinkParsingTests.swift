import Testing
import Foundation
@testable import AppFeature

/// Implements the parsing half of TC for FR-srm-deeplink-patch-format /
/// FR-srm-deeplink-pr-format / FR-srm-deeplink-malformed: the URL grammar
/// (shepherd://patch/<hex>, shepherd://pr/<hex>, nevent refs, unknown host,
/// empty ref, malformed ref).
@Suite("Deeplink parsing / FR-srm-deeplink-patch-format, FR-srm-deeplink-pr-format, FR-srm-deeplink-malformed")
struct DeeplinkParsingTests {
    private let hex = String(repeating: "a", count: 64)

    @Test func hexPatchAndPRHosts() {
        #expect(AppFeature.parseDeeplinkRef(URL(string: "shepherd://patch/\(hex)")!) == hex)
        #expect(AppFeature.parseDeeplinkRef(URL(string: "shepherd://pr/\(hex)")!) == hex)
    }

    @Test func neventAccepted() {
        // bech32 body is not a valid hex id, so acceptance proves the nevent path.
        let nevent = "nevent1qqsqzqsrqszsvpcgpy9qkrqdpc83qygjzv2p29shrqv35xcur50p7gqpz3mhxue69uhhyetvv9ujuerpd46hxtnfdu9d348n"
        #expect(AppFeature.parseDeeplinkRef(URL(string: "shepherd://patch/\(nevent)")!) != nil)
    }

    @Test func unknownHostRejected() {
        #expect(AppFeature.parseDeeplinkRef(URL(string: "shepherd://open?session=abc")!) == nil)
        #expect(AppFeature.parseDeeplinkRef(URL(string: "shepherd://foo/\(hex)")!) == nil)
    }

    @Test func emptyOrMalformedRefRejected() {
        #expect(AppFeature.parseDeeplinkRef(URL(string: "shepherd://patch/")!) == nil)
        #expect(AppFeature.parseDeeplinkRef(URL(string: "shepherd://pr/not-a-ref")!) == nil)
    }
}
