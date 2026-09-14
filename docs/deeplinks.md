# Shepherd deep links

Canonical link for sharing a PR / patch in Buzz threads (GitHub is a backup mirror only; never post gitworkshop or GitHub PR URLs).

## Format

```
shepherd://pr/<ref>
```

- `<ref>` = Nostr event id of the root git patch/PR event:
  - `nevent1…` (preferred, NIP-19; carries relay hints so the fetch works off any relay config)
  - or 64-char lowercase hex event id
- Host must be `pr` (PRs) or `patch` (patches); both route to the same Open Patch flow.
- Path is percent-decoded before parsing; paste links as-is.
- Any other host, empty ref, or malformed ref is rejected.

Implementations: `AppFeature.parseDeeplinkRef` and `PatchRef.parse`
(`engineering/apps/macos/Sources/AppFeature/AppFeature.swift`,
`Sources/Dependencies/RelayClient.swift`). Tests:
`Tests/AppFeatureTests/DeeplinkParsingTests.swift`.

Builders: post `shepherd://pr/<nevent1…>` after pushing a PR via ngit. Take the
event id from the ngit output / published nostr event.
