import XCTest
import SharedModels
@testable import ShepherdDependencies

/// NIP-42 auth frame construction. Regression coverage for the bunker
/// sign-in bug: relay AUTH must work via an async signer (bunker identity,
/// no local secret), not only via a local secret key.
final class RelayAuthTests: XCTestCase {
    func testAuthEventCarriesChallengeAndRelayTags() {
        let event = RelayAuth.authEvent(challenge: "ch123", relayURL: "wss://relay.example")
        XCTAssertEqual(event.kind, 22242)
        XCTAssertEqual(event.tags, [["challenge", "ch123"], ["relay", "wss://relay.example"]])
    }

    func testAsyncSignerPathProducesFrameWithoutLocalSecret() async {
        // A bunker-style signer: no secret key, signs remotely. Before the fix
        // this path returned nil (currentSecret() == nil for bunker identities)
        // and AUTH-required relays silently returned empty lookups.
        let sign: @Sendable (NostrEvent) async -> NostrEvent? = { event in
            NostrEvent(
                id: String(repeating: "a", count: 64), pubkey: String(repeating: "b", count: 64), kind: event.kind,
                content: event.content, tags: event.tags,
                createdAt: event.createdAt, sig: String(repeating: "c", count: 64)
            )
        }
        let frame = await RelayAuth.authFrame(
            challenge: "ch123", relayURL: "wss://relay.example", sign: sign
        )
        XCTAssertNotNil(frame)
        guard let data = frame?.data(using: .utf8) else { return XCTFail("no frame") }
        guard let arr = try? JSONSerialization.jsonObject(with: data) as? [Any] else { return XCTFail("bad json") }
        XCTAssertEqual(arr[0] as? String, "AUTH")
        guard let event = arr[1] as? [String: Any] else { return XCTFail("no event") }
        XCTAssertEqual(event["kind"] as? Int, 22242)
        XCTAssertEqual((event["tags"] as? [[String]])?.first, ["challenge", "ch123"])
        XCTAssertNotNil(event["sig"])
    }

    func testAsyncSignerFailureReturnsNil() async {
        let sign: @Sendable (NostrEvent) async -> NostrEvent? = { _ in nil }
        let frame = await RelayAuth.authFrame(
            challenge: "ch123", relayURL: "wss://relay.example", sign: sign
        )
        XCTAssertNil(frame)
    }
}
