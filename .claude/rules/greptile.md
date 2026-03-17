# Greptile — Peer Reviewer & CodeRabbit Fallback

> **Always:** Trigger Greptile on every PR alongside CR. Poll for response. Reply to every thread. Fix all valid findings.
> **Ask first:** Never — fix findings autonomously.
> **Never:** Skip Greptile on a PR. Merge without a clean Greptile pass. Ignore Greptile findings because "CR already reviewed."

Greptile is an AI code reviewer that runs as a **peer** alongside CodeRabbit on every PR. It also serves as the fallback when CR is rate-limited.

## Greptile Basics

- **GitHub App:** Greptile Apps
- **Bot username:** `greptile-apps[bot]`
- **Trigger:** Comment `@greptileai` on any PR (no special "full review" suffix needed)
- **Auto-trigger:** OFF — must be explicitly triggered via @mention
- **Rate limits:** None documented (50 reviews/seat/month included, $1/extra — no per-hour throttle)
- **Review time:** ~1-3 minutes for most PRs
- **Completion signals:** 👀 emoji on the PR = analyzing, 👍 = complete, 😕 = failed
- **No CLI:** Greptile cannot do local pre-push reviews. Local review loop uses CR CLI only.
- **Config:** Optional `greptile.json` in repo root (supports `strictness`, `customInstructions`, `scope`)
- **Feedback loop:** 👍/👎 reactions on Greptile comments train it over 2-3 weeks

## When to Trigger Greptile

### On every PR (peer review mode)

After pushing code and creating/updating a PR, trigger BOTH reviewers:

1. CR auto-triggers on push (or use `@coderabbitai full review`)
2. Comment `@greptileai` on the PR to trigger Greptile

Both run in parallel — there is no conflict. Process findings from whichever responds first.

### As CR fallback (rate-limit recovery)

When CR is rate-limited (detected via fast-path check-run signal or 8-minute timeout):

1. Greptile should already be running (triggered in step above)
2. If Greptile was not yet triggered, comment `@greptileai` immediately
3. Process Greptile findings while waiting for CR to recover
4. After fixing + pushing, CR auto-triggers on the new SHA — enter normal polling

## Polling for Greptile Response

Poll every 60 seconds on all three endpoints (same pattern as CR):

- `repos/{owner}/{repo}/pulls/{N}/reviews?per_page=100`
- `repos/{owner}/{repo}/pulls/{N}/comments?per_page=100`
- `repos/{owner}/{repo}/issues/{N}/comments?per_page=100`

Filter by `greptile-apps[bot]` (with `[bot]` suffix).

**Timeout:** 5 minutes. Greptile typically responds in 1-3 minutes. If no response after 5 minutes, proceed without it and note in the PR that Greptile did not respond.

**Completion detection:**

- Check for 👍 reaction on the PR from Greptile (signals review complete)
- Also check for review objects or comments from `greptile-apps[bot]`
- If a review comment appears, it's done — process findings
- If no comments appear after 5 minutes and no 👍, treat as timeout

> **Note:** Check-run names for Greptile are not yet documented. After the first Greptile
> review on this repo, check `gh api "repos/{owner}/{repo}/commits/{SHA}/check-runs"` and
> update this section with the actual check-run name and completion detection logic.

## Processing Greptile Findings

Same protocol as CR findings:

1. Verify each finding against the actual code before fixing
2. Fix **all valid findings** in a single commit
3. Push once
4. **Reply to every Greptile comment thread** confirming the fix:
   - Inline comments: `gh api repos/{owner}/{repo}/pulls/comments/{id}/replies -f body="Fixed in \`SHA\`: <what changed>"`
   - Issue comments: `gh api repos/{owner}/{repo}/issues/{N}/comments -f body="@greptileai Fixed: <summary>"`
5. Resolve threads via GraphQL (same as CR threads)
6. Use 👍/👎 reactions on Greptile comments to provide feedback

## Detecting a Clean Greptile Pass

A Greptile review is **clean** when:

- `greptile-apps[bot]` posted a review or summary with no actionable findings, OR
- 👍 completion signal appeared with no inline comments or review findings

A clean Greptile pass counts as 1 of the 3 required reviews for merge readiness.

## Self-Review Fallback

If BOTH CR and Greptile are unavailable (CR rate-limited + Greptile timeout):

1. Perform a self-review of the full diff (`git diff main...HEAD`)
2. Check for: bugs, security issues, error handling, types, naming, edge cases
3. A clean self-review does NOT satisfy the 3-review merge requirement
4. Tell the user both reviewers are down and what was left unreviewed
