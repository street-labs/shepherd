import XCTest
@testable import ShepherdDependencies

/// Scratch verification against a real AUTH-required relay: confirms the app's
/// NIP-42 auth frame is accepted (or rejected) end-to-end. Skipped unless
/// RELAY_PROBE=1 — not part of the deterministic suite.
final class RelayAuthLiveProbe: XCTestCase {
    func testAuthHandshakeAgainstRealRelay() async throws {
        let env = ProcessInfo.processInfo.environment
        guard env["RELAY_PROBE"] == "1" else {
            throw XCTSkip("set RELAY_PROBE=1 to run")
        }
        guard let relay = env["RELAY_PROBE_URL"], let nsec = env["RELAY_PROBE_NSEC"] else {
            throw XCTSkip("RELAY_PROBE_URL / RELAY_PROBE_NSEC not set")
        }
        guard let (_, data) = Bech32.decode(nsec), data.count == 32 else {
            XCTFail("bad nsec"); return
        }
        let secret = data

        guard let url = URL(string: relay) else {
            XCTFail("invalid relay URL: \(relay)"); return
        }
        let task = URLSession.shared.webSocketTask(with: url)
        task.resume()
        // 1. Receive AUTH challenge
        var challenge: String?
        for _ in 0..<5 {
            if case .string(let s) = try await task.receive(),
               let d = s.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: d) as? [Any],
               arr.first as? String == "AUTH",
               let ch = arr[1] as? String {
                challenge = ch; break
            }
        }
        guard let challenge else {
            XCTFail("no AUTH challenge received"); return
        }
        // 2. Sign + send AUTH frame using the app's own RelayAuth
        guard let frame = RelayAuth.authFrame(
            challenge: challenge, relayURL: relay,
            secret: secret, signer: NostrSigner.liveValue
        ) else {
            XCTFail("auth frame build failed"); return
        }
        try await task.send(.string(frame))
        // 3. Send REQ and watch what comes back
        let req = ##"[ "REQ", "probe", {"kinds":[1618],"#a":["30617:b6390bde3c6378e40278bb35ee3a3cb54d8806b63aaa77d7a441158a44109153:coffee-shop"],"limit":5}]"##
        try await task.send(.string(req))
        for _ in 0..<6 {
            guard case .string(let s) = try await task.receive() else { continue }
            print("RELAYPROBE FRAME: \(s.prefix(400))")
            if s.contains("EOSE") || s.contains("EVENT") { break }
        }
        task.cancel(with: .goingAway, reason: nil)
    }
}
