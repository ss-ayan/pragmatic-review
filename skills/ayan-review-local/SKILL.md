---
name: ayan-review-local
description: Review local git commits or uncommitted edits with the ayan code-review bot. Use after finishing a logical chunk of work, before committing, or before pushing — surfaces idiom, slop, security, and static-analysis findings without touching any remote. No GitHub PR required.
allowed-tools: Bash(ayan review *), Bash(git status), Bash(git diff *), Bash(git log *), Read
---

## When to use this skill

Invoke proactively when:
- The user has just finished a non-trivial chunk of work in a long plan ("now I want to verify nothing's broken").
- The user is about to commit ("ready to commit", "looks good?") or about to push ("ready to push").
- The user explicitly asks for a review of local changes, a feature branch, or working-tree edits.

Skip when:
- The user is asking a question about how code works (no review needed).
- A pull request URL is in scope — use `ayan-review-pr-dryrun` or `ayan-review-pr-post` instead.

## What ayan checks

The ayan binary analyzes a diff with multiple parallel analyzers:

- **idiom** — language conventions, naming, ergonomics
- **slop** — duplication of existing functions, dead code, AI-overengineering smells
- **security** — injection, unbounded reads, auth bypass, hardcoded secrets
- **staticanalysis** — gofmt, go vet, ruff, rubocop, brakeman, bundler-audit (when the toolchains are installed)
- **guideline** — repo conventions learned from CONTRIBUTING.md / CLAUDE.md / .golangci.yml
- **pragmatism** — flags over-engineering against the PR's stated intent

Languages auto-detected from file extensions: Go, Python, Ruby (with Rails framework detection).

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

`--output -` writes the markdown transcript to stdout so you can read it back into the conversation without a temp file. The status line (`Reviewing X (Y...Z, head abc1234)`) goes to stderr so the stdout stream is pure transcript.

### 5. Custom repo path

```bash
ayan review --local --repo-path /path/to/repo --output -
```

By default ayan reviews the current working directory. Pass `--repo-path` when invoking from elsewhere.

## Steps

1. Confirm the user is in a git repo by running `!git status --short` (block hangs/errors). If not in a git repo, stop and tell the user.
2. Decide which mode fits:
   - Working-tree edits not yet committed → `--working-tree`
   - One or more commits on a feature branch → default (or explicit `--base`)
3. Run `ayan review --local --output /tmp/ayan-findings.md` (or `--output -` for inline).
4. Read the transcript at `/tmp/ayan-findings.md` (or capture stdout).
5. Address findings in order of severity (blocker > warning > suggestion). For each:
   - Show the user the finding's file:line and title.
   - Apply the suggested fix if it's clearly right.
   - Flag any disagreement and ask the user.
6. If no findings, say so explicitly ("ayan found nothing — looks clean").

## Heartbeat & latency

ayan emits a heartbeat log every 30s with stage, in-flight LLM call count, and the longest-running call. A typical local review takes 1–5 minutes depending on diff size — most time is spent in parallel LLM calls. If the heartbeat stalls (no new lines for >2 min), the underlying `claude` CLI may be hung; tell the user to investigate rather than waiting silently.

## Output shape

The transcript is markdown with sections:

```
# ayan review transcript
Captured at: <RFC3339>
**Counts:** N inline, M summary, K replies, L approvals.

---
## Summary comment(s)
<one block of overall review notes>

---
## Inline comments (N)
### 1. `path/to/file.go:42`
**Severity:** warning | **Category:** security
<finding body with explanation and suggested fix>
```

Read the file path + line numbers exactly as printed — those are the addresses to edit.

## Don'ts

- Don't run this against a GitHub PR URL — that's what `ayan-review-pr-dryrun` is for.
- Don't pass `--approve` in local mode (it's a no-op; the dry-run decorator captures it).
- Don't ignore the heartbeat — it's the operator's only signal that the review is alive.
