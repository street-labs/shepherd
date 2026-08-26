# Git Flow Review — Roadmap

Forward-looking ideas for the git flow review loop (`../product/git-flow-review.md`) that are deliberately not in the v1 spec. Captured so the intent isn't lost when the core loop ships.

## Fast Follow

- **NIP-34-mirrored internal conversation.** v1 conducts the reviewer-agent back-and-forth in the agent conversation, with the in-tool workshop as the reconciliation surface (`FR-gfr-workshop`). An alternative that reuses the app's existing conversation machinery: the recipe mints a local NIP-34 patch/PR event mirroring the GitHub pull request's diff, and the back-and-forth runs in Shepherd's existing multi-identity patch-thread surface — the reviewer and any participating agents hold their own Nostr identities and reply in the thread, exactly as they do for ngit patches today (kind `1617`/`1618` + kind `1` replies, live subscription, reply-to-reply). The recipe then synthesizes the thread (plus any workshop resolutions) into the single-voice review for GitHub (`NFR-gfr-single-voice`). Rationale: in an ngit repo, distinct bot/human identities are a feature; in a GitHub org, agent-authored comments read as slop — so the loop keeps the rich multi-party conversation internally and publishes only the synthesized result under the reviewer's identity. Depends on: local event minting + a local repo mirror in the recipe, and a synthesis step that distills a thread into line-anchored comments + summary. Deferred until the v1 loop has proven value in use, because it adds a local Nostr stack to what is currently a solo loop.

- **PR verdict at post time.** Whether the posted review also sets a GitHub review verdict (approve / request changes) or stays comment-only. Open Question 2 in the shared spec; smallest version is comment-only with the verdict left to the reviewer's own GitHub click.

## Later

- **Multi-agent kickoff.** More than one agent running the AI pass (e.g. a review-focused agent plus the feature's builder) with the workshop reconciling all sources. The workshop model (items with provenance and per-item resolution) extends naturally; the open question is orchestration and finding-volume noise.
- **Re-review on updated PR.** When the PR author pushes new commits, re-run the loop over just the new diff, carrying forward accepted-but-unresolved feedback.
