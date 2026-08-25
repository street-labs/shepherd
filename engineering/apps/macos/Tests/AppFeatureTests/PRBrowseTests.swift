import Testing
import ComposableArchitecture
import Foundation
@testable import AppFeature
@testable import SharedModels
@testable import ShepherdDependencies
@testable import PRBrowseFeature
@testable import OpenPatchFeature

@Suite("RepoCoordinate")
struct RepoCoordinateTests {
    let pubkey = String(repeating: "ab", count: 32)

    @Test("valid coordinate parses; pubkey lowercased, whitespace trimmed")
    func valid() {
        let c = RepoCoordinate.parse(" 30617:\(pubkey.uppercased()):shepherd ")
        #expect(c?.raw == "30617:\(pubkey):shepherd")
        #expect(c?.d == "shepherd")
    }

    @Test("malformed input rejected")
    func invalid() {
        #expect(RepoCoordinate.parse("not-a-coordinate") == nil)
        #expect(RepoCoordinate.parse("1617:\(pubkey):shepherd") == nil)       // wrong kind
        #expect(RepoCoordinate.parse("30617:abc:shepherd") == nil)            // short pubkey
        #expect(RepoCoordinate.parse("30617:\(pubkey):") == nil)              // empty d
        #expect(RepoCoordinate.parse("30617:\(pubkey):d:extra") == nil)       // extra segment
        #expect(RepoCoordinate.parse("") == nil)
    }
}

@Suite("NostrFilter #a / #p serialization")
struct NostrFilterTagTests {
    @Test("a and p tags serialize to #a / #p keys")
    func serialization() {
        let f = NostrFilter(aTag: "30617:abc:def", pTag: "1234", kinds: [1618])
        let json = f.jsonObject
        #expect(json["#a"] as? [String] == ["30617:abc:def"])
        #expect(json["#p"] as? [String] == ["1234"])
        #expect(json["kinds"] as? [Int] == [1618])
        #expect(json["#e"] == nil)
    }
}

@Suite("PRBrowseFeature")
@MainActor
struct PRBrowseFeatureTests {
    let pubkey = String(repeating: "ab", count: 32)
    let coord = "30617:\(String(repeating: "ab", count: 32)):shepherd"

    private func prEvent(id: String, subject: String?, createdAt: Int64) -> NostrEvent {
        var tags: [[String]] = [["a", coord]]
        if let subject { tags.append(["subject", subject]) }
        return NostrEvent(id: id, pubkey: pubkey, kind: 1618, content: "fallback subject \(id)", tags: tags, createdAt: createdAt)
    }

    // MARK: - Watchlist (TC-pb-watchlist-add/invalid/remove/persist)

    @Test("valid coordinate is added, persisted; invalid and duplicate rejected")
    func watchlistManagement() async {
        let saved = ActorBox<[String]>([])
        let store = TestStore(initialState: PRBrowseFeature.State()) {
            PRBrowseFeature()
        } withDependencies: {
            $0.watchlistClient.load = { [] }
            $0.watchlistClient.save = { saved.value = $0 }
        }
        store.exhaustivity = .off
        await store.send(.addTapped) {
            $0.addError = "Enter a repo coordinate: 30617:<pubkey>:<d>"
        }
        await store.send(.set(\.addInput, "garbage"))
        await store.send(.addTapped) {
            $0.addError = "Enter a repo coordinate: 30617:<pubkey>:<d>"
        }
        await store.send(.set(\.addInput, coord))
        await store.send(.addTapped) {
            $0.watchlist = [coord]
            $0.addInput = ""
        }
        await store.send(.set(\.addInput, coord))
        await store.send(.addTapped) {
            $0.addError = "Already watching this repo"
        }
        await store.send(.removeTapped(coord)) {
            $0.watchlist = []
        }
        #expect(saved.value == [])
    }

    @Test("onAppear loads the persisted watchlist")
    func watchlistLoad() async {
        let store = TestStore(initialState: PRBrowseFeature.State()) {
            PRBrowseFeature()
        } withDependencies: {
            $0.watchlistClient.load = { [coord] }
            $0.watchlistClient.save = { _ in }
        }
        await store.send(.onAppear) {
            $0.watchlist = [coord]
        }
    }

    // MARK: - Repo lookup (TC-pb-repo-list)

    @Test("repo lookup dedupes, sorts newest first, uses subject tag over content")
    func repoLookup() async {
        // Out of order, one duplicate id; subject tag wins for one, content first line for another.
        let events = [
            prEvent(id: "old", subject: nil, createdAt: 10),
            prEvent(id: "new", subject: "Tagged subject", createdAt: 30),
            prEvent(id: "mid", subject: nil, createdAt: 20),
            prEvent(id: "new", subject: nil, createdAt: 30), // duplicate id
        ]
        let store = TestStore(initialState: PRBrowseFeature.State()) {
            PRBrowseFeature()
        } withDependencies: {
            $0.watchlistClient.load = { [] }
            $0.watchlistClient.save = { _ in }
            $0.relayClient.reachableRelays = { _ in ["wss://relay.example"] }
            $0.relayClient.subscribe = { _ in
                AsyncStream { continuation in
                    for e in events { continuation.yield(e) }
                    continuation.finish()
                }
            }
        }
        store.exhaustivity = .off
        await store.send(.repoSelected(coord)) {
            $0.mode = .repo(coord)
            $0.loading = true
        }
        await store.receive(\.lookupFinished) {
            $0.loading = false
            $0.prs = [
                PRBrowseFeature.PRSummary(id: "new", subject: "Tagged subject", author: pubkey, createdAt: 30),
                PRBrowseFeature.PRSummary(id: "mid", subject: "fallback subject mid", author: pubkey, createdAt: 20),
                PRBrowseFeature.PRSummary(id: "old", subject: "fallback subject old", author: pubkey, createdAt: 10),
            ]
        }
    }

    @Test("no reachable relays surfaces noRelays")
    func noRelays() async {
        let store = TestStore(initialState: PRBrowseFeature.State()) {
            PRBrowseFeature()
        } withDependencies: {
            $0.watchlistClient.load = { [] }
            $0.watchlistClient.save = { _ in }
            $0.relayClient.reachableRelays = { _ in [] }
        }
        store.exhaustivity = .off
        await store.send(.repoSelected(coord)) {
            $0.mode = .repo(coord)
            $0.loading = true
        }
        await store.receive(\.noRelaysReached) {
            $0.loading = false
            $0.noRelays = true
        }
    }

    // MARK: - Npub lookup (TC-pb-npub-list, TC-pb-npub-invalid)

    @Test("invalid npub input rejected without a lookup")
    func npubInvalid() async {
        let store = TestStore(initialState: PRBrowseFeature.State()) {
            PRBrowseFeature()
        } withDependencies: {
            $0.watchlistClient.load = { [] }
            $0.watchlistClient.save = { _ in }
            $0.relayClient.reachableRelays = { _ in [] }
        }
        await store.send(.set(\.npubInput, "npub1xyz")) {
            $0.npubInput = "npub1xyz"
        }
        await store.send(.npubLookupTapped) {
            $0.npubError = "Enter an npub1… or 64-char hex pubkey"
        }
        await store.send(.set(\.npubInput, "tooshort")) {
            $0.npubInput = "tooshort"
            $0.npubError = nil
        }
        await store.send(.npubLookupTapped) {
            $0.npubError = "Enter an npub1… or 64-char hex pubkey"
        }
    }

    @Test("hex pubkey input runs a p-tag lookup")
    func npubHex() async {
        let store = TestStore(initialState: PRBrowseFeature.State()) {
            PRBrowseFeature()
        } withDependencies: {
            $0.watchlistClient.load = { [] }
            $0.watchlistClient.save = { _ in }
            $0.relayClient.reachableRelays = { _ in ["wss://relay.example"] }
            $0.relayClient.subscribe = { _ in AsyncStream { $0.finish() } }
        }
        store.exhaustivity = .off
        await store.send(.set(\.npubInput, pubkey.uppercased()))
        await store.send(.npubLookupTapped) {
            $0.mode = .npub(pubkey)
            $0.loading = true
        }
        await store.receive(\.lookupFinished) {
            $0.loading = false
            $0.prs = []
        }
    }

    // MARK: - Open (TC-pb-open-pr)

    @Test("prTapped emits the openPR delegate")
    func openPR() async {
        let store = TestStore(initialState: PRBrowseFeature.State()) {
            PRBrowseFeature()
        } withDependencies: {
            $0.watchlistClient.load = { [] }
            $0.watchlistClient.save = { _ in }
        }
        await store.send(.prTapped("deadbeef"))
        await store.receive(.delegate(.openPR("deadbeef")))
    }
}

@Suite("NIP19Decode.decodeNPub")
struct DecodeNPubTests {
    @Test("npub1 round-trips to the 32-byte hex pubkey")
    func roundTrip() {
        let bytes = (0...31).map(UInt8.init)
        let npub = Bech32.encode(Data(bytes), prefix: "npub")
        let expected = bytes.map { String(format: "%02x", $0) }.joined()
        #expect(NIP19Decode.decodeNPub(npub) == expected)
    }

    @Test("wrong prefix and bad checksum rejected")
    func invalid() {
        let npub = Bech32.encode(Data((0...31).map(UInt8.init)), prefix: "npub")
        #expect(NIP19Decode.decodeNPub("nsec" + npub.dropFirst(4)) == nil)
        #expect(NIP19Decode.decodeNPub("npub1qqq") == nil)
        #expect(NIP19Decode.decodeNPub("") == nil)
    }
}

/// Tiny reference box so test closures can record saved values.
final class ActorBox<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

// Implements: FR-pb-default-state — browse is the default empty state, and a
// PR picked there routes through the existing Open Patch flow (FR-pb-open-pr).
@Suite("PR Browse default state")
@MainActor
struct PRBrowseDefaultStateTests {
    @Test("browse state present at launch; PR selection routes through Open Patch")
    func browseIsDefault() async {
        #expect(AppFeature.State().prBrowse == PRBrowseFeature.State())

        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        store.exhaustivity = .off

        // Invalid ref: Open Patch is presented, prefilled, and shows its
        // existing invalid-input state — same surface as pasting by hand.
        await store.send(.prBrowse(.delegate(.openPR("not-a-valid-ref"))))
        #expect(store.state.openPatch?.input == "not-a-valid-ref")
        #expect(store.state.prBrowse == PRBrowseFeature.State())
    }
}
