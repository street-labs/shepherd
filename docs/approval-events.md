# Approval events (shepherd → merge service)

Status: proposed v1. Companion to `ngit-ci-cutover.md` (borg repo), cutover step 6.
 shepherd's review UI (PRs #41 / #43) emits this event when a reviewer approves;
 the merge service verifies it before advancing master.

## Event

Custom kind in the NIP-34 family (1617 patch, 1618 PR, 1619 PR-update, 1621 issue,
1630-1633 status; 1620 is currently unassigned upstream — we propose it upstream
if it sticks).

```json
{
  "kind": 1620,
  "pubkey": "<reviewer-pubkey>",
  "content": "<optional markdown review summary>",
  "tags": [
    ["e", "<pr-or-patch-event-id>", "<relay-url>", "root"],
    ["p", "<pr-author-pubkey>"],
    ["a", "30617:<repo-owner-pubkey>:<repo-id>"],
    ["t", "approval"],            // or "rejection" to withdraw an earlier approval
    ["c", "<approved-commit-id>"], // exact PR tip this verdict applies to
    ["merge-base", "<commit-id>"]  // optional, same meaning as NIP-34 PR tag
  ]
}
```

Published to the repo announcement's `relays`.

## Merge service verification rules

1. Signature valid; `pubkey` is in the repo's reviewer allowlist.
2. `e` tag references the currently-open PR/patch event.
3. `c` tag equals the PR's current tip commit (`c` tag of the newest 1618/1619).
   Stale-commit approvals do not count — a re-push forces re-review.
4. Verdict is the newest 1620 (by `created_at`) per (pubkey, PR); newest overall
   wins if reviewers disagree (v1: single approver keeps the gate simple).
5. A later `rejection` from the same reviewer invalidates their earlier approval.

## Why not kind 1631

1631 (Applied/Merged) asserts a merge already happened and carries
`merge-commit`/`applied-as-commits` tags that only make sense post-merge. The
gate needs a pre-merge verdict bound to a specific commit, which is what the
`c` tag gives us. 1631 remains the merge service's job after it advances master.

## Open

- ci status event shape is ci-bot's to define (spec open question); should
  follow the same `e` root + `c` commit binding so verification code is shared.
- Approver of record for v1 (shepherd reviewer vs review-bot) — spec open
  question; this shape works for either since both sign with their own keys.
