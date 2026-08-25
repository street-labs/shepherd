# Patch Watcher

Where in-app patch review goes next, now that opening a single patch by event id is specified (`product/macos/shepherd-review.md` → In-app patch open). The headline future item is watching repos for patches so the reviewer can pick one from a list instead of pasting an event id. This file also parks the related full-file-view fast-follow for the current diff-as-tabs in-app flow.

See `../product/macos/shepherd-review.md` for the current in-app patch-open behavior, and `../product/shepherd-review.md` for the CLI `--patch` path.

## Fast Follow

- **Patch status from NIP-34 status events.** v1 of the in-app patch open renders status as `open` unconditionally, because NIP-34 status is conveyed by separate kind `1630`–`1633` status events (Open / Applied-Merged-Resolved / Closed / Draft) that reference the patch via an `e` tag, not by a tag on the patch event itself. Fetch the most recent status event (by `created_at`, from the patch author or a repo maintainer) for the opened patch and render the real status in the metadata section. This same correction is needed in the CLI path (`/shepherd-review --patch`), whose command prompt currently reads a non-existent `status` tag — see `product/macos/shepherd-review.md` Open Question 5. Rationale: the metadata section's status badge is currently wrong for every real ngit patch; this makes it right for both entry points.

- **Full-file view for in-app-opened patches.** The v1 in-app path loads each changed file as a tab whose content is that file's diff block, because reconstructing full post-patch file contents needs the base files the diff is against (a git checkout of the parent commit). To match the CLI experience, the app could fetch base files via the NIP-34 repo coordinate (`a` tag → `30617:<owner>:<repo>`) or a configured git remote, apply the diff in-memory, and show full post-patch file content per tab. Rationale: parity with the CLI path, which reviewers coming from `/shepherd-review --patch` already expect. Open question (see `product/macos/shepherd-review.md` Open Question 4): whether to do this at all vs. keep the diff-as-tabs view.

- **Deeplinks for issues (kind `1621`).** Issues are markdown conversational threads, not code changes. They have no diff to review and no clone URL. An issue deeplink would open a conversational thread view, not a code review surface — a fundamentally different surface that is out of scope for the current kickoff. Issue deeplinks are deferred to the roadmap. (PR deeplinks, kind `1618`, were previously roadmaped here but are now in scope — see `product/macos/shepherd-review.md` In-app pull request open.)

- **Deeplinks on iOS.** iOS has its own in-app patch open (`FR-sri-patch-open-*`) but no registered `shepherd://` scheme in its app bundle and a different URL-scheme / universal-link model. Rationale: a reviewer on iPhone/iPad should be able to open a patch link from Buzz on mobile too. Depends on: deciding the iOS link model (custom scheme vs universal links) and registering it. See `product/macos/shepherd-review.md` Open Question 9.

## V2

- **Patches in the browse lists.** The PR Browse feature (`product/pr-browse.md`) lists pull requests (kind `1618`) for watched repos and tagged npubs; extending the repo lookup to patches (kind `1617`) is a follow-on once PR browsing has landed.
- **Open-PR-only filtering and status badges.** PR Browse v1 lists every PR for a repo because NIP-34 status is conveyed by separate kind `1630`–`1633` status events (see the shared spec's Out of Scope). Fetch the most recent status event per PR and both filter to open PRs and show a real status badge. Rationale: the "open" in "browse open PRs" is currently approximated by recency, not truth.
- **Live updates for browse lists.** Keep the browse subscription open while the sheet is shown so new PRs stream in, mirroring the live patch-thread subscription. Depends on: measured relay load with multi-repo watchlists.
- **naddr / git-URL repo input.** Accept `naddr1…` and `git clone` URLs as watchlist input, resolving to `30617:<pubkey>:<d>` coordinates. Rationale: paste-anything ergonomics match the Open Patch reference input.

(graduated: the original V2 item "watch repos for patches; select from a list" is now in scope as PR Browse, `product/pr-browse.md` — PRs first, patches deferred above.)

## Later

- **Patch status actions from the app.** Let the reviewer change a patch's status (open → merged/closed) from the review window, publishing the NIP-34 status-transition event, so triage and review happen in one place. Depends on the watcher list above being present.
- **Notifications for new patches on watched repos.** Background or foreground notification when a new open patch arrives on a watched repo, so the reviewer does not have to poll the list.
