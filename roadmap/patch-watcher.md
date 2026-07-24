# Patch Watcher

Where in-app patch review goes next, now that opening a single patch by event id is specified (`product/macos/shepherd-review.md` → In-app patch open). The headline future item is watching repos for patches so the reviewer can pick one from a list instead of pasting an event id. This file also parks the related full-file-view fast-follow for the current diff-as-tabs in-app flow.

See `../product/macos/shepherd-review.md` for the current in-app patch-open behavior, and `../product/shepherd-review.md` for the CLI `--patch` path.

## Fast Follow

- **Full-file view for in-app-opened patches.** The v1 in-app path loads each changed file as a tab whose content is that file's diff block, because reconstructing full post-patch file contents needs the base files the diff is against (a git checkout of the parent commit). To match the CLI experience, the app could fetch base files via the NIP-34 repo coordinate (`a` tag → `30617:<owner>:<repo>`) or a configured git remote, apply the diff in-memory, and show full post-patch file content per tab. Rationale: parity with the CLI path, which reviewers coming from `/shepherd-review --patch` already expect. Open question (see `product/macos/shepherd-review.md` Open Question 4): whether to do this at all vs. keep the diff-as-tabs view.

## V2

- **Watch repos for patches; select from a list.** Instead of pasting an event id, the reviewer configures one or more NIP-34 repo coordinates to watch. The app subscribes to patch events (kinds 1617/1621) for those repos on the configured relays and presents an in-app list of open patches (author, message, status, age). The reviewer picks one to open, reusing the in-app patch-open load path (`FR-srm-patch-open-load`). Rationale: the reviewer should not have to copy event ids out of a separate Nostr client; Shepherd becomes the place where incoming patches are triaged and reviewed. Design questions to settle at kickoff: where the watched-repos list lives (in-app settings vs. config file), how the list is paginated/refreshed, whether closed/merged patches are shown, and how this relates to the existing live patch-thread subscription.

## Later

- **Patch status actions from the app.** Let the reviewer change a patch's status (open → merged/closed) from the review window, publishing the NIP-34 status-transition event, so triage and review happen in one place. Depends on the watcher list above being present.
- **Notifications for new patches on watched repos.** Background or foreground notification when a new open patch arrives on a watched repo, so the reviewer does not have to poll the list.
