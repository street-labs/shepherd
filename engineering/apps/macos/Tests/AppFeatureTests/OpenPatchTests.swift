import Testing
import ComposableArchitecture
import Foundation
@testable import AppFeature
@testable import SharedModels
@testable import ShepherdDependencies
@testable import OpenPatchFeature

@Suite("NIP19Decode")
struct NIP19DecodeTests {
    /// Build a `nevent1` entity from raw TLVs so the decode round-trip can be
    /// tested without a fixture pulled from the network.
    private func encodeNEvent(eventID: String, relays: [String]) -> String {
        var tlv: [UInt8] = []
        let idBytes = hexToBytes(eventID.lowercased())
        tlv.append(contentsOf: [0x00, 0x00, UInt8(idBytes.count)])
        tlv.append(contentsOf: idBytes)
        for url in relays {
            let u = Array(url.utf8)
            tlv.append(contentsOf: [0x01, UInt8((u.count >> 8) & 0xFF), UInt8(u.count & 0xFF)])
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
        let nevent = Bech32.encode(Data([0x00, 0x00, 0x20] + Array(repeating: 0x01, count: 32)), prefix: "nevent")
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
}
