# PR Actions — iOS Platform

> iOS-specific requirements for PR Actions. See `../pr-actions.md` for shared requirements.

All shared `FR-pa-*` requirements apply unchanged on iOS. Signing and publishing reuse the platform-neutral identity/relay stack the iOS app already uses for patch-thread replies (`FR-sri-event-sign`, `FR-sri-event-publish` in `./shepherd-review.md`); the merge gate and kind `1620`/`1631` shapes are identical to macOS. No iOS-only divergence is specified: comment, review verdicts, live reply streaming, capability gating, and merge are all driven by the shared spec.

Presentation is specified in `design/ios/pr-actions.md`.
