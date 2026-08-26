import XCTest
import ComposableArchitecture
import SharedModels
@testable import ShepherdDependencies

/// Scratch verification of the full RelayClient.subscribe path against a real
/// AUTH-required relay. Skipped unless RELAY_PROBE=1.
final class RelaySubscribeLiveProbe: XCTestCase {
    func testSubscribePathAgainstRealRelay() async throws {
        let env = ProcessInfo.processInfo.environment
        guard env["RELAY_PROBE"] == "1" else { throw XCTSkip("set RELAY_PROBE=1 to run") }
        guard let relay = env["RELAY_PROBE_URL"], let nsec = env["RELAY_PROBE_NSEC"] else {
            throw XCTSkip("RELAY_PROBE_URL / RELAY_PROBE_NSEC not set")
        }
        guard let (_, data) = Bech32.decode(nsec), data.count == 32 else {
            XCTFail("bad nsec"); return
        }
        let secret = data

        let filter = NostrFilter(
            aTag: "30617:b6390bde3c6378e40278bb35ee3a3cb54d8806b63aaa77d7a441158a44109153:coffee-shop",
            kinds: [1618],
            relays: [relay]
        )
        let events: [NostrEvent] = await withDependencies {
            $0.identityClient.sign = { event in event.sign(secretKey: secret) }
        } operation: {
            await PRSubscribeCollect.collect(RelayClient.liveValue.subscribe(filter), seconds: 8)
        }
        print("RELAYPROBE SUBSCRIBE EVENT COUNT: \(events.count)")
        for e in events { print("RELAYPROBE EVENT: \(e.id) kind=\(e.kind)") }
        XCTAssertFalse(events.isEmpty, "subscribe returned no events from an AUTH-required relay that has them")
    }
}

enum PRSubscribeCollect {
    static func collect(_ stream: AsyncStream<NostrEvent>, seconds: UInt64) async -> [NostrEvent] {
        let buffer = Buffer()
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await event in stream { await buffer.append(event) }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            }
            await group.next()
            group.cancelAll()
        }
        return await buffer.events
    }

    private actor Buffer {
        private(set) var events: [NostrEvent] = []
        func append(_ event: NostrEvent) { events.append(event) }
    }
}
