# Diff View — macOS Design

> Based on requirements in `../../product/diff-view.md`

## Overview

A diff is presented in the existing code viewer, not in a separate surface. The reviewer sees the same tab bar, the same line gutter, and the same comment interaction as when reviewing a whole file — only the content is a unified diff, and its lines are tinted by kind. There is no mode switch in the window: the review either opened as diffs or it did not.

## Line treatment

Each line of a diff is drawn by the existing line row, with a tint applied behind the code:

| Line kind | Tint | Text |
|---|---|---|
| Added (`+…`) | Green wash, low opacity | Primary |
| Removed (`-…`) | Red wash, low opacity | Primary |
| Header (`diff --git`, `index`, `---`/`+++`, `@@`, mode and rename lines) | None | Secondary — dimmed, so structural lines recede |
| Context | None | Primary |

The tints are low-opacity system green and red so they read on both light and dark backgrounds and never fight the syntax colors on top of them. `+++` and `---` are file-header lines, not added and removed lines, and are treated as headers.

## Interaction states take precedence

A line can be tinted and interactive at once. The interaction states are drawn instead of the diff tint, in this order: focused comment, selected range, has-comment, then diff tint. A selected added line therefore reads as selected, not as an addition — selection is transient and needs to be unambiguous.

## Line numbers

The gutter numbers the diff's own lines, starting at 1 for the `diff --git` header. It does not show old and new file line numbers side by side. Comments anchor to these numbers, and the generated prompt quotes the diff lines themselves, so the reviewer and the agent are looking at the same coordinates. `FR-diff-display`.

## Accessibility

Tint is never the only signal: every added and removed line still carries its `+` or `-` prefix as the first character of the line, which is what the prompt carries through to the agent. `NFR-diff-accessibility`.

## What is not here

No mode toggle, no expand-collapsed-region control, no refresh button, no side-by-side view. The diff is whatever `git` emitted at launch; to see more of the file, the reviewer opens the file itself.
