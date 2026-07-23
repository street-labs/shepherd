import Testing
import Foundation
import ComposableArchitecture
@testable import ShepherdDependencies
@testable import SharedModels

/// Implements: TC-srm-bunker-uri-malformed — BunkerConfig.parse rejects malformed
/// URIs and accepts valid ones (including extra relay= params).
@Suite("BunkerConfig parsing / FR-srm-identity-load")
struct BunkerConfigTests {
    @Test("Valid bunker:// URI parses correctly")
    func validURI() throws {
        let config = try #require(BunkerConfig.parse(
            "bunker://79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798?relay=wss://relay.example.com&secret=mysecret"
        ))
        #expect(config.bunkerPubkeyHex == "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
        #expect(config.relayURL == "wss://relay.example.com")
        #expect(config.secret == "mysecret")
    }

    @Test("bunker:// without secret parses (secret is nil)")
    func noSecret() throws {
        let config = try #require(BunkerConfig.parse(
            "bunker://79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798?relay=wss://relay.example.com"
        ))
        #expect(config.secret == nil)
    }

    @Test("Multiple relay= params: first wins, extras accepted-but-ignored")
    func multipleRelays() throws {
        let config = try #require(BunkerConfig.parse(
            "bunker://79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798?relay=wss://first.relay.com&relay=wss://second.relay.com"
        ))
        #expect(config.relayURL == "wss://first.relay.com")
    }

    @Test("Missing relay= is malformed")
    func missingRelay() {
        #expect(BunkerConfig.parse(
            "bunker://79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798?secret=test"
        ) == nil)
    }

    @Test("Not bunker:// scheme is malformed")
    func wrongScheme() {
        #expect(BunkerConfig.parse(
            "https://79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798?relay=wss://relay.com"
        ) == nil)
    }

    @Test("Short pubkey (not 64 hex chars) is malformed")
    func shortPubkey() {
        #expect(BunkerConfig.parse(
            "bunker://abc123?relay=wss://relay.com"
        ) == nil)
    }

    @Test("No query string is malformed")
    func noQuery() {
        #expect(BunkerConfig.parse(
            "bunker://79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
        ) == nil)
    }
}
