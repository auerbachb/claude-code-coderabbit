# Claude Code + CodeRabbit Workflow

A battle-tested `CLAUDE.md` configuration that teaches [Claude Code](https://docs.anthropic.com/en/docs/claude-code) to collaborate with [CodeRabbit](https://coderabbit.ai) for automated PR planning, code review, and merge workflows — all driven from your terminal.

## What this does

When you drop this `CLAUDE.md` into your project (or `~/.claude/`), Claude Code will automatically:

- **Plan with CodeRabbit** — When starting a GitHub issue, Claude kicks off `@coderabbitai plan` asynchronously, builds its own plan in parallel, then merges the two into a single implementation plan.
- **Review loop** — After every push, Claude polls for CodeRabbit's review comments, fixes all valid findings, replies to every thread, and re-requests review until the PR is clean.
- **Handle rate limits** — Batches fixes into single commits, respects CodeRabbit's 8-reviews/hour and 50-chats/hour Pro tier limits, and backs off when throttled.
- **Verify acceptance criteria** — Before offering to merge, Claude reads every checkbox in the PR's Test Plan section, verifies each against the actual code, and checks them off.
- **Squash and merge** — Clean PRs get squash-merged with branch cleanup, only after user confirmation.

## Why this exists

CodeRabbit and Claude Code are each powerful on their own. Together they catch more bugs, but only if Claude Code knows *how* to interact with CodeRabbit — when to poll, how to parse findings, when to back off on rate limits, and how to properly resolve comment threads.

This config encodes all of that into reusable instructions so you don't have to repeat yourself every session.

## Quick start

### Option 1: Global config (applies to all your projects)

```bash
# Back up your existing CLAUDE.md if you have one
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak 2>/dev/null

# Copy or append
cp CLAUDE.md ~/.claude/CLAUDE.md
```

### Option 2: Per-project config

```bash
# Copy into your project root
cp CLAUDE.md /path/to/your/project/CLAUDE.md
```

Claude Code loads `CLAUDE.md` from the project root first, then `~/.claude/CLAUDE.md` as a fallback. Per-project configs let you customize per repo.

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- [CodeRabbit](https://coderabbit.ai) installed on your GitHub repo (free or Pro tier)

## What's in the config

| Section | What it does |
|---|---|
| **PR & Issue Workflow** | Branch naming, squash-merge policy, issue linking, acceptance criteria rules |
| **Issue Planning Flow** | 7-step flow: read issue, kick off CR plan, build Claude's plan, merge plans, post final plan, start coding |
| **CodeRabbit Review Loop** | Polling strategy, rate-limit-aware behavior, feedback processing, comment thread resolution |
| **Completion Flow** | 2 consecutive clean reviews, AC verification, user-confirmed merge |
| **Subagent Context** | Ensures spawned subagents inherit the workflow rules |

## Key design decisions

**Polling, not webhooks.** Claude Code runs in your terminal, so it polls GitHub's API for CodeRabbit comments. The config specifies 60-second intervals with a 10-minute timeout before re-triggering review.

**Batch fixes, single push.** Every push consumes a CodeRabbit review from your hourly quota. The config instructs Claude to fix all findings from a round in one commit rather than pushing per-finding.

**Verify before merge.** Claude won't offer to merge until it has read the source files and confirmed every acceptance criteria checkbox. This catches regressions introduced during the CR fix loop.

**Two consecutive clean reviews.** A single clean pass isn't enough — the config requires two consecutive `@coderabbitai full review` requests with no findings before considering the PR ready.

## Customizing

The config is plain Markdown. Edit it to match your workflow:

- **Change branch naming** — Modify the `issue-N-short-description` pattern in the Branching & Merging section.
- **Adjust polling intervals** — The 60-second interval and 10-minute timeout are in the Polling section.
- **Add autonomy boundaries** — The Autonomy Boundaries section controls which files Claude can fix without asking. Restrict it if you want approval for certain paths.
- **Skip CodeRabbit** — The config auto-detects whether a repo uses CodeRabbit (checks for `.coderabbit.yaml` or past CR comments). If CodeRabbit isn't set up, those sections are skipped automatically.

## How the review loop works

```
Push to PR branch
       |
       v
Poll for CR comments (60s intervals, 10 min timeout)
       |
       v
CR posts findings? ──No──> Trigger @coderabbitai full review
       |                              |
      Yes                        Poll 5 more min
       |                              |
       v                              v
Verify each finding against code   No response? Tell user
       |
       v
Fix all valid findings in one commit
       |
       v
Reply to every CR comment thread
       |
       v
Push (consumes 1 review from quota)
       |
       v
Poll again... repeat until clean
       |
       v
2 consecutive clean full reviews?
       |
      Yes
       |
       v
Verify all acceptance criteria checkboxes
       |
       v
Ask user: merge or review diff first?
```

## FAQ

**Does this work with CodeRabbit's free tier?**
Yes, but the rate limits in the config are tuned for Pro (8 reviews/hour, 50 chats/hour). Free tier limits are lower — you may want to increase polling timeouts.

**Can I use this without CodeRabbit?**
Yes. The config auto-detects CodeRabbit. Without it, you still get the PR workflow, branch naming, acceptance criteria verification, and squash-merge flow.

**Does Claude Code actually poll in a loop?**
Yes. The `CLAUDE.md` instructions tell Claude to use `gh api` calls in a polling loop. Claude executes shell commands via its Bash tool and tracks state (like the highest comment ID seen) across iterations.

**What if CodeRabbit and Claude disagree?**
During planning, the config tells Claude to pick the best ideas from both plans. During review, Claude verifies every CR finding against the actual code before applying it — it won't blindly apply suggestions that would break things.

## Contributing

Found an edge case or improvement? PRs welcome. This config evolved from real-world usage across multiple repos, but there's always room to handle more scenarios.

## License

MIT
