---
name: local
description: Review local git commits or uncommitted edits with ayan. Use after finishing a logical chunk of work, before committing, or before pushing — surfaces idiom, slop, security, static-analysis, pragmatism, and guideline findings without touching any remote. No GitHub PR required.
allowed-tools: Bash(ayan *), Bash(git status), Bash(git diff *), Bash(git log *), Read
---

## When to use this skill

Invoke proactively when:
- The user has just finished a non-trivial chunk of work in a long plan ("now I want to verify nothing's broken").
- The user is about to commit ("ready to commit", "looks good?") or about to push ("ready to push").
- The user explicitly asks for a review of local changes, a feature branch, or working-tree edits.

Skip when:
- The user is asking a question about how code works (no review needed).
- A pull request URL is in scope — use `pr-dryrun` or `pr-post` instead.

## What ayan checks

The ayan binary runs multiple parallel analyzers against a diff:

- **idiom** — language conventions, naming, ergonomics
- **slop** — duplication of existing functions, dead code, AI-overengineering smells
- **security** — injection, unbounded reads, auth bypass, hardcoded secrets
- **staticanalysis** — gofmt, go vet, ruff, rubocop, brakeman, bundler-audit (when toolchains installed)
- **guideline** — repo conventions learned from CONTRIBUTING.md / CLAUDE.md / .golangci.yml
- **pragmatism** — flags over-engineering against the PR's stated intent

Languages auto-detected from file extensions: Go, Python, Ruby (with Rails framework detection).

## Requires

This skill requires ayan **v4.0.13 or later** (for `--local`, `--only`/`--skip`, and the heartbeat). Step 1 in the recipe verifies this before running.

## Invocation modes

### 1. Compare current branch against main (default)

```bash
ayan review --local --output /tmp/ayan-findings.md
```

Reviews `git diff main...HEAD`. Default base ref is `main`; pass `--base master` or `--base develop` to override.

### 2. Compare against an arbitrary ref

```bash
ayan review --local --base HEAD~3 --output /tmp/ayan-findings.md
ayan review --local --base origin/main --head HEAD --output /tmp/ayan-findings.md
ayan review --local --base v1.2.0 --head HEAD --output /tmp/ayan-findings.md
```

Accepts any git ref (branch, tag, SHA) for `--base` and `--head`.

### 3. Review uncommitted working-tree changes

```bash
ayan review --local --working-tree --output /tmp/ayan-findings.md
```

Diffs staged + unstaged edits against HEAD. Useful right before `git commit`.

### 4. Stream the transcript to stdout

```bash
ayan review --local --output -
```

`--output -` writes the transcript to stdout so you can read it back into the conversation without a temp file. Status logs go to stderr so stdout is pure markdown.

### 5. Fast partial review (`--only` / `--skip`)

Skip slow analyzers for sub-minute sanity checks during long plans:

```bash
ayan review --local --only staticanalysis --output -          # ~7 seconds — gofmt/lint only
ayan review --local --only security,staticanalysis --output - # adds security; ~30-60s
ayan review --local --skip idiom --output -                   # full pipeline minus the slow idiom analyzer
```

`--only` is an allow-list; `--skip` is a deny-list. Mutually exclusive. Use `--skip idiom` when working on large diffs where idiom hits its per-call timeout.

### 6. Custom repo path

```bash
ayan review --local --repo-path /path/to/repo --output -
```

Default is the current working directory.

## Steps

1. **Pre-flight: verify ayan is installed and recent enough.** Run:
   ```bash
   ayan version
   ```
   If the command isn't found, stop and tell the user: "`ayan` binary not found on PATH. Install via `https://github.com/ss-ayan` (binary or Docker)." If the printed version is older than `v4.0.13`, tell the user: "ayan version is too old; this skill needs v4.0.13+. Upgrade and re-run." Do NOT continue past this step.

2. Confirm the user is in a git repo:
   ```bash
   git status --short
   ```
   If not in a git repo (`fatal: not a git repository`), stop and tell the user.

3. Decide which mode fits:
   - Working-tree edits not yet committed → `--working-tree`
   - One or more commits on a feature branch → default (or explicit `--base`)
   - Long plan, fast iteration → add `--only staticanalysis` or `--skip idiom,slop` to cut wall clock

4. Run the review:
   ```bash
   ayan review --local --output /tmp/ayan-findings.md
   ```
   Or `--output -` for inline reading.

5. Read the transcript at `/tmp/ayan-findings.md` (or capture stdout).

6. Address findings in order of severity (blocker > warning > suggestion). For each:
   - Show the user the finding's `file:line` and title.
   - Apply the suggested fix if it's clearly right.
   - Flag any disagreement and ask the user.

7. If no findings, say so explicitly ("ayan found nothing — looks clean").

## Heartbeat & latency

ayan emits a heartbeat log every 30s with stage, in-flight LLM call count, and the longest-running call. A typical local review takes 1–5 minutes depending on diff size — most time is spent in parallel LLM calls. If the heartbeat stalls (no new lines for >2 min), the underlying `claude` CLI may be hung; surface that to the user rather than waiting silently.

For long plans where you'll trigger reviews repeatedly, prefer `--only staticanalysis,security` to keep each check under a minute.

## Output shape

```
# ayan review transcript
Captured at: <RFC3339>
**Counts:** N inline, M summary, K replies, L approvals.

---
## Summary comment(s)
<overall review notes>

---
## Inline comments (N)
### 1. `path/to/file.go:42`
**Severity:** warning | **Category:** security
<finding body with explanation and suggested fix>
```

Read file paths + line numbers exactly as printed — those are the addresses to edit.

## Don'ts

- Don't run this against a GitHub PR URL — that's what `pr-dryrun` is for.
- Don't pass `--approve` in local mode (it's a no-op; the dry-run decorator captures it).
- Don't ignore the heartbeat — it's the operator's only signal that the review is alive.
