# PR Actions — iOS Test Plan

> Based on requirements in `../../product/pr-actions.md` and `../../product/ios/pr-actions.md`
> Based on design in `../../design/ios/pr-actions.md`
> Based on technical spec in `../../engineering/ios/pr-actions.md`

Logic (event building, merge gate, gating) is shared with macOS and covered by `qa/macos/pr-actions.md` plus the shared package tests. This plan covers the iOS presentation, manual unless noted.

## Coverage Matrix

| Requirement | Test Cases |
|---|---|
| `AC-pa-comment-publishes` | `TC-pai-comment-sheet` |
| `AC-pa-approval-tip` / `AC-pa-merge-publishes` | `TC-pai-verdict-merge` |
| `AC-pa-live-replies` | `TC-pai-live-reply` |
| `AC-pa-capabilities` | `TC-pai-capabilities` |

## Test Cases

- `TC-pai-comment-sheet` — Composer and "Post to PR" reachable and functional on iPhone and iPad; posted/failed indicators render. Status: Not started.
- `TC-pai-verdict-merge` — Review sheet (verdict segmented control, summary, tip commit, Submit) and Merge button with gate-reason popover present correctly; merge confirm dialog publishes and status badge flips. Status: Not started.
- `TC-pai-live-reply` — With the PR open, an incoming reply appears in the thread without refresh; "N new replies" pill when scrolled up. Status: Not started.
- `TC-pai-capabilities` — Signed-out shows disabled controls with explanation; non-maintainer sees no Merge control. Status: Not started.
