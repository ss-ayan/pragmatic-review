# pragmatic-review

Claude Code plugin for comprehensive code review using the [ayan](https://github.com/ss-ayan/ayan) bot — idiom, slop, security, static analysis, pragmatism, and guideline checks. Works on local commits, working-tree edits, and GitHub PRs (dry-run or live).

## Skills

| Slash command | When Claude invokes it | What it runs |
|---|---|---|
| `/pragmatic-review:local` | User finished a chunk of work; before commit/push; "review my local changes" | `ayan review --local [...]` — diffs base...head or working tree, transcript to file or stdout |
| `/pragmatic-review:pr-dryrun` | User wants to preview ayan's findings on a GitHub PR without posting | `ayan review --dry-run <PR URL>` — full pipeline against the real PR, transcript stays local |
| `/pragmatic-review:pr-post` | User explicitly authorized posting comments to a GitHub PR | `ayan review <PR URL>` — posts inline + summary; `--approve` for approval gate |
| `/pragmatic-review:profile` | User onboarding ayan onto a new repo or re-learning after a refactor | `ayan profile --repo org/repo` — extracts conventions to the knowledge store |

Local and PR-dry-run skills emit findings as a markdown transcript to a file or stdout. Live PR mode posts directly to GitHub and is gated on explicit user confirmation.

## Requirements

- **ayan binary v4.0.13 or later** on `$PATH` (verified by each skill's first step via `ayan version`)
- **Claude Code CLI** installed and signed in
- **For PR modes:** `gh auth login` or `GITHUB_TOKEN`

Install ayan first → see [github.com/ss-ayan/ayan](https://github.com/ss-ayan/ayan) for binary tarballs or Docker images.

## Install the plugin

### Option 1 — Claude Code marketplace (recommended once submitted)

```bash
claude plugin install pragmatic-review
```

The plugin auto-discovers via the marketplace listing once it's been submitted at [platform.claude.com/plugins/submit](https://platform.claude.com/plugins/submit). Until then, use Option 2.

### Option 2 — From a local checkout

```bash
git clone https://github.com/ss-ayan/pragmatic-review.git
claude --plugin-dir ./pragmatic-review
```

Each Claude Code session started with `--plugin-dir` picks up the four skills. To make it persistent, drop a symlink into wherever your `claude` CLI looks for plugins (consult `claude plugin list` to see active plugin paths).

### Option 3 — Pinned to a specific version

```bash
git clone --branch v0.2.0 https://github.com/ss-ayan/pragmatic-review.git
claude --plugin-dir ./pragmatic-review
```

Pin to a tag if you need a known-good version against a specific ayan binary release.

## Verify install

```bash
claude
> /pragmatic-review:local
```

Claude should respond with the skill's pre-flight check (running `ayan version`). If `ayan` isn't installed or is too old, the skill stops immediately with a clear message instead of producing confusing output.

## How findings are surfaced

A transcript looks like:

```
# ayan review transcript
Captured at: 2026-05-26T22:00:00+05:30
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

ayan emits a `review.heartbeat` log line every 30 seconds with stage, in-flight LLM count, and the longest-running call's analyzer + duration. If a heartbeat stalls (no new line for >2 min), the underlying `claude` CLI subprocess may be hung — the skill body tells Claude to surface this rather than wait silently.

For long plans where reviews fire repeatedly, prefer the fast partial form:

```bash
ayan review --local --only staticanalysis --output -    # ~7 seconds — gofmt/lint only
```

## Version pinning

This plugin pins itself to ayan **v4.0.13 or later**. The required version is declared in `.claude-plugin/plugin.json`:

```json
{
  "name": "pragmatic-review",
  "version": "0.2.0",
  "requires": {
    "ayan_version": ">=4.0.13"
  }
}
```

Each SKILL.md's first step runs `ayan version` and aborts on mismatch. If you upgrade ayan, the plugin works as long as the binary's version meets the minimum. If you downgrade ayan, expect skill invocations to refuse to proceed — that's by design.

To upgrade either side:

| Side | Where |
|---|---|
| ayan binary | [github.com/ss-ayan/ayan/releases](https://github.com/ss-ayan/ayan/releases) |
| pragmatic-review plugin | `cd pragmatic-review && git pull` (or reinstall via marketplace) |

## Adding a skill

Drop a new directory into `skills/<skill-name>/` with a `SKILL.md` carrying the canonical YAML frontmatter (`name`, `description`, `allowed-tools`). The plugin manifest auto-discovers it. Bump the plugin `version` in `plugin.json` and tag a release.

## License

(Same as ayan — see github.com/ss-ayan/ayan for the canonical license file.)
