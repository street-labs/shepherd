import Testing
import ComposableArchitecture
import Foundation
@testable import AppFeature
@testable import SharedModels
@testable import ShepherdDependencies
@testable import OpenPatchFeature

@Suite("NIP19Decode")
struct NIP19DecodeTests {
    /// Build a `nevent1` entity from raw TLVs using the NIP-19 format
    /// (1-byte type, 1-byte length, value) so the decode round-trip is valid
    /// against real NIP-19 entities, not just self-consistent.
    private func encodeNEvent(eventID: String, relays: [String]) -> String {
        var tlv: [UInt8] = []
        let idBytes = hexToBytes(eventID.lowercased())
        tlv.append(contentsOf: [0x00, UInt8(idBytes.count)])
        tlv.append(contentsOf: idBytes)
        for url in relays {
            let u = Array(url.utf8)
            tlv.append(contentsOf: [0x01, UInt8(u.count)])
            tlv.append(contentsOf: u)
        }
        return Bech32.encode(Data(tlv), prefix: "nevent")
    }

    private func hexToBytes(_ s: String) -> [UInt8] {
        var bytes: [UInt8] = []
        var idx = s.startIndex
        while idx < s.endIndex {
            let next = s.index(idx, offsetBy: 2)
            bytes.append(UInt8(s[idx..<next], radix: 16) ?? 0)
            idx = next
        }
        return bytes
    }

    @Test("nevent1 decodes to event id + relay hints")
    func decodeNEvent() {
        let id = String(repeating: "ab", count: 32) // 64-char hex
        let nevent = encodeNEvent(eventID: id, relays: ["wss://relay.example.com"])
        guard let decoded = NIP19Decode.decodeNEvent(nevent) else {
            Issue.record("decode failed"); return
        }
        #expect(decoded.eventID == id)
        #expect(decoded.relays == ["wss://relay.example.com"])
    }

    @Test("A real-world nevent1 (1-byte TLV length) decodes correctly")
    func realWorldNEventDecodes() {
        // Hand-built with the NIP-19 format (1-byte length): TLV type 0 / len 32 /
        // event id 0102…20, then type 1 / len 25 / "wss://relay.damus.io".
        // Regression guard: if the decoder ever reads the length as 2 bytes again,
        // this real-format entity fails to decode.
        let nevent = "nevent1qqsqzqsrqszsvpcgpy9qkrqdpc83qygjzv2p29shrqv35xcur50p7gqpz3mhxue69uhhyetvv9ujuerpd46hxtnfdu9d348n"
        guard let decoded = NIP19Decode.decodeNEvent(nevent) else {
            Issue.record("real-world nevent1 failed to decode"); return
        }
        #expect(decoded.eventID == "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20")
        #expect(decoded.relays == ["wss://relay.damus.io"])
    }

    @Test("naddr1 is not accepted (wrong prefix)")
    func naddrRejected() {
        #expect(NIP19Decode.decodeNEvent("naddr1qpzry9x8gf2tvdw0s3jn") == nil)
    }

    @Test("garbage and empty input are rejected")
    func garbageRejected() {
        #expect(NIP19Decode.decodeNEvent("not-a-nevent") == nil)
        #expect(NIP19Decode.decodeNEvent("") == nil)
    }
}

@Suite("PatchRef")
struct PatchRefTests {
    @Test("64-char hex id accepted and lowercased")
    func hexID() {
        let id = String(repeating: "A", count: 64)
        guard case let .hexID(parsed) = PatchRef.parse(id) else {
            Issue.record("expected .hexID"); return
        }
        #expect(parsed == id.lowercased())
    }

    @Test("nevent1 accepted")
    func neventAccepted() {
        // NIP-19 1-byte length: type 0, len 32, 32-byte id.
        let nevent = Bech32.encode(Data([0x00, 0x20] + Array(repeating: 0x01, count: 32)), prefix: "nevent")
        guard case .nevent = PatchRef.parse(nevent) else {
            Issue.record("expected .nevent"); return
        }
    }

    @Test("naddr1, prose, and wrong-length hex rejected")
    func invalidRejected() {
        #expect(PatchRef.parse("naddr1abc") == nil)
        #expect(PatchRef.parse("here is my patch id: abc") == nil)
        #expect(PatchRef.parse(String(repeating: "a", count: 63)) == nil)
        #expect(PatchRef.parse("   ") == nil)
    }

    @Test("surrounding whitespace trimmed")
    func trimmed() {
        let id = String(repeating: "a", count: 64)
        guard case let .hexID(parsed) = PatchRef.parse("  \(id)\n") else {
            Issue.record("expected .hexID"); return
        }
        #expect(parsed == id)
    }

    @Test("shepherd deeplink pasted as text extracts the ref")
    func deeplinkURL() {
        let id = String(repeating: "a", count: 64)
        for url in ["shepherd://patch/\(id)", "shepherd://pr/\(id)"] {
            guard case let .hexID(parsed) = PatchRef.parse(url) else {
                Issue.record("expected .hexID from \(url)"); return
            }
            #expect(parsed == id)
        }
    }

    @Test("https viewer links extract the ref")
    func httpsViewerURL() {
        let id = String(repeating: "b", count: 64)
        guard case let .hexID(parsed) = PatchRef.parse("https://gitworkshop.dev/e/\(id)") else {
            Issue.record("expected .hexID"); return
        }
        #expect(parsed == id)
        let nevent = Bech32.encode(Data([0x00, 0x20] + Array(repeating: 0x01, count: 32)), prefix: "nevent")
        guard case .nevent = PatchRef.parse("https://gitworkshop.dev/patch/\(nevent)?utm=buzz") else {
            Issue.record("expected .nevent"); return
        }
    }

    @Test("URLs with no embedded ref rejected")
    func urlWithoutRefRejected() {
        #expect(PatchRef.parse("https://gitworkshop.dev/") == nil)
        #expect(PatchRef.parse("https://example.com/e/not-a-ref") == nil)
        #expect(PatchRef.parse("shepherd://foo/bar") == nil)
    }
}

@Suite("OpenPatchFeature")
@MainActor
struct OpenPatchFeatureTests {
    private let patchID = String(repeating: "a", count: 64)
    private let author = String(repeating: "b", count: 64)

    private func patchEvent(content: String, kind: Int = 1617) -> NostrEvent {
        NostrEvent(id: patchID, pubkey: author, kind: kind, content: content, tags: [], createdAt: 1)
    }

    @Test("Invalid input sets invalidInput state and fetches nothing")
    func invalidInput() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        await store.send(\.fetchButtonTapped) {
            $0.status = .invalidInput
        }
    }

    @Test("Valid patch event emits patchLoaded delegate")
    func patchLoaded() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        let content = "Fix\n\ndiff --git a/x b/x\n@@ -1 +1 @@\n+a"
        let event = patchEvent(content: content)
        // A valid patch leaves status unchanged and emits the .patchLoaded delegate.
        await store.send(.eventFetched(event))
        await store.receive(\.delegate.patchLoaded)
    }

    @Test("Wrong-kind event sets wrongKind state")
    func wrongKind() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        await store.send(.eventFetched(patchEvent(content: "hi", kind: 1))) {
            $0.status = .wrongKind("aaaaaaaa", 1)
        }
    }

    @Test("Malformed diff sets badDiff state")
    func badDiff() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        await store.send(.eventFetched(patchEvent(content: "no diff here"))) {
            $0.status = .badDiff("aaaaaaaa")
        }
    }

    @Test("Timeout sets notFound state")
    func notFound() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        await store.send(.fetchTimedOut(eventID: patchID)) {
            $0.status = .notFound("aaaaaaaa")
        }
    }

    @Test("No relays reachable sets noRelays state")
    func noRelays() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        await store.send(.noRelaysReached) {
            $0.status = .noRelays
        }
    }

    // MARK: - PR (kind 1618) dispatch — Implements: FR-srm-pr-open-fetch,
    // FR-srm-pr-open-clone, FR-srm-pr-open-load, FR-sri-pr-open-patches,
    // FR-sri-pr-open-load

    private let prID = String(repeating: "c", count: 64)
    private let prAuthor = String(repeating: "d", count: 64)

    private func prEvent(tags: [[String]], content: String = "PR body") -> NostrEvent {
        NostrEvent(id: prID, pubkey: prAuthor, kind: 1618, content: content, tags: tags, createdAt: 1)
    }

    private func patchEvent(id: String, content: String) -> NostrEvent {
        NostrEvent(id: id, pubkey: prAuthor, kind: 1617, content: content, tags: [], createdAt: 1)
    }

    @Test("A 1618 PR with no clone URL sets prError")
    func prMissingClone() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        let event = prEvent(tags: [["merge-base", String(repeating: "1", count: 64)]])
        await store.send(.eventFetched(event)) {
            $0.status = .prError("Pull request cccccccc has no clone URL — cannot fetch changes.")
        }
    }

    @Test("A 1618 PR with no c tag sets prError")
    func prMissingTip() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        let event = prEvent(tags: [["clone", "https://git.example/x"]])
        await store.send(.eventFetched(event)) {
            $0.status = .prError("Pull request cccccccc has no commit id.")
        }
    }

    @Test("A 1618 PR without merge-base proceeds to the tip-vs-parent diff")
    func prWithoutMergeBase() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        // merge-base absent: no immediate prError; the git effect runs (testValue
        // returns .empty) and the empty-diff error surfaces instead.
        let event = prEvent(tags: [
            ["clone", "https://git.example/x"],
            ["c", String(repeating: "2", count: 64)],
        ])
        await store.send(.eventFetched(event))
        await store.receive(\.prDiffResult) {
            $0.status = .prError("Pull request cccccccc has no changes.")
        }
    }

    @Test("prDiffResult .diff emits patchLoaded with PR metadata")
    func prDiffLoaded() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        let tags: [[String]] = [
            ["clone", "https://git.example/x"],
            ["c", String(repeating: "2", count: 64)],
            ["merge-base", String(repeating: "3", count: 64)],
            ["branch-name", "feature/x"],
            ["subject", "Add x"],
            ["a", "30617:acme:widget"],
        ]
        let event = prEvent(tags: tags)
        let diff = "diff --git a/x b/x\n@@ -1 +1 @@\n+a"
        await store.send(.prDiffResult(.diff(diff), event))
        await store.receive(\.delegate.patchLoaded)
    }

    @Test("prDiffResult .noGit / .empty / .fetchFailed set prError")
    func prDiffFailures() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        let event = prEvent(tags: [])
        await store.send(.prDiffResult(.noGit, event)) {
            $0.status = .prError("git is required to review pull requests but was not found on your system")
        }
        await store.send(.prDiffResult(.empty, event)) {
            $0.status = .prError("Pull request cccccccc has no changes.")
        }
        await store.send(.prDiffResult(.fetchFailed("https://git.example/x: unreachable"), event)) {
            $0.status = .prError("Could not fetch commits from https://git.example/x: unreachable")
        }
    }

    @Test("prPatchesFetched unions referenced patch diffs and emits patchLoaded")
    func prPatchesLoaded() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        let prEvent = prEvent(tags: [["e", String(repeating: "f", count: 64)], ["subject", "PR x"]])
        let p1 = patchEvent(id: String(repeating: "f", count: 64), content: "diff --git a/x b/x\n@@ -1 +1 @@\n+a")
        let p2 = patchEvent(id: String(repeating: "e", count: 64), content: "diff --git a/y b/y\n@@ -1 +1 @@\n+b")
        await store.send(.prPatchesFetched([p1, p2], prEvent))
        await store.receive(\.delegate.patchLoaded)
    }

    @Test("prPatchesFetched with no valid patches sets prError")
    func prPatchesEmpty() async {
        let store = TestStore(initialState: OpenPatchFeature.State()) {
            OpenPatchFeature()
        } withDependencies: {
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        let prEvent = prEvent(tags: [["e", String(repeating: "f", count: 64)]])
        // A non-1617 referenced event is skipped -> no reviewable patches.
        let nonPatch = patchEvent(id: String(repeating: "f", count: 64), content: "not a diff")
        await store.send(.prPatchesFetched([nonPatch], prEvent)) {
            $0.status = .prError("PR cccccccc has no reviewable patch events. Its changes may be available only via git clone — open this PR on macOS.")
        }
    }
}
