# ayan-skill

Claude Code skills for the [ayan](https://github.com/ss-ayan/ayan) code-review bot. Each skill teaches Claude Code when and how to invoke a specific `ayan` mode and address the findings it surfaces.

## Skills

| Skill | When Claude invokes it | What it runs |
|-------|------------------------|--------------|
| **ayan-review-local** | User finished a chunk of work; before commit/push; any "review my local changes" request | `ayan review --local [...]` — diffs base...head or working tree, captures findings in a markdown transcript locally |
| **ayan-review-pr-dryrun** | User wants to preview ayan's findings on a GitHub PR without posting | `ayan review --dry-run <PR URL>` — exercises the full pipeline against a real PR, transcript stays local |
| **ayan-review-pr-post** | User explicitly authorized posting comments to a GitHub PR | `ayan review <PR URL>` — posts inline + summary; `--approve` for approval gate |
| **ayan profile** | User onboarding ayan onto a new repo or re-learning after a refactor | `ayan profile --repo org/repo` — extracts conventions to the knowledge store |

Local and PR-dry-run skills emit findings as a markdown transcript to a file or stdout. Live PR mode posts directly to GitHub and is gated on explicit user confirmation.

## Installation

```bash
# 1. Install ayan itself (Go 1.21+; the binary is what skills call)
git clone https://github.com/ss-ayan/ayan
cd ayan && go install ./cmd/cli
# verify
ayan languages

# 2. Install this skill plugin
git clone https://github.com/ss-ayan/ayan-skill
# Drop the plugin into a Claude Code plugin directory or invoke via:
claude --plugin-dir ./ayan-skill
```

After install, the skills become available as `/ayan-review-local`, `/ayan-review-pr-dryrun`, `/ayan-review-pr-post`, and `/ayan-profile`. Claude Code will also invoke them proactively when the conversation context matches the skill's description (e.g., "I just finished refactoring this — does it look OK?" triggers `ayan-review-local`).

## Auth & dependencies

| Skill | Requires |
|-------|----------|
| ayan-review-local | A git checkout. No GitHub auth needed. |
| ayan-review-pr-dryrun | `gh auth login` or `GITHUB_TOKEN` (read). |
| ayan-review-pr-post | `gh auth login` or `GITHUB_TOKEN` with `repo` write scope. |
| ayan-profile | `gh auth login` or `GITHUB_TOKEN` (read). |

The ayan binary itself uses your existing Claude Code subscription via the `claude` CLI subprocess — no Console API key required.

## How findings are surfaced

A transcript looks like:

```
# ayan review transcript
Captured at: 2026-05-25T22:00:00+05:30
**Counts:** 3 inline, 1 summary, 0 +1 replies, 0 approvals.

---
## Summary comment(s)
<overall review block>

---
## Inline comments (3)
### 1. `internal/auth/token.go:47`
**Severity:** blocker | **Category:** security
The bearer token is logged at WARN level on parse failure...
**Suggested fix:** ...

### 2. ...
```

Claude reads the transcript and addresses findings one by one, applying suggested fixes when they're clearly right and asking the user when there's ambiguity.

## Heartbeat & long-running calls

ayan emits a `review.heartbeat` log line every 30 seconds with stage, in-flight LLM count, and the longest-running call's analyzer + duration. If a heartbeat stalls (no new line for >2 min), the underlying claude-cli subprocess may be hung — the skill body tells Claude to surface this rather than wait silently.

## Adding a skill

Drop a new directory into `skills/<skill-name>/` with a `SKILL.md` that has the canonical frontmatter (`name`, `description`, `allowed-tools`). The plugin manifest auto-discovers it.
