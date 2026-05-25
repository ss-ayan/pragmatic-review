---
name: ayan-review-pr-dryrun
description: Review a GitHub pull request with ayan WITHOUT posting any comments to the PR. Captures every inline comment, summary, and approval into a local markdown transcript instead. Use when the user wants to evaluate ayan's findings before letting it speak on a real PR — also useful for previewing what a live review would produce.
allowed-tools: Bash(ayan review --dry-run *), Bash(gh pr view *), Bash(gh auth status), Read
---

## When to use this skill

Invoke when:
- The user mentions a GitHub PR URL and says "review this without posting" / "preview" / "dry run" / "what would ayan say".
- The user is debugging ayan's behavior and wants to see findings without affecting the PR.
- The user wants to dogfood ayan on a real PR to evaluate quality.

Skip when:
- The user wants comments actually posted to the PR — use `ayan-review-pr-post` instead.
- There's no PR URL — use `ayan-review-local` instead.

## What dry-run does

`ayan review --dry-run <PR URL>` exercises the full review pipeline against the real PR (fetches diff, indexes head SHA, runs analyzers, generates comments) but routes every would-be mutation through an in-memory decorator:

- **Inline comments** → captured into the transcript with file:line address
- **Summary comment** → captured into the transcript
- **"+1" replies** to existing threads → captured
- **PR approval** (if `--approve` is passed) → captured but never submitted

Nothing reaches GitHub. The bot's GitHub credentials are still used to READ the PR (diff, files, existing comments) — they're just never used to write.

## Authentication

Requires either `GITHUB_TOKEN` in env or `gh auth login` having been run (ayan falls back to `gh auth token` automatically). Check first:

```bash
gh auth status
```

If unauthenticated, stop and tell the user to run `gh auth login`.

## Invocation modes

### 1. Dry-run with file output (default)

```bash
ayan review --dry-run https://github.com/org/repo/pull/42 --output /tmp/ayan-findings.md
```

Default output path is `ayan-dryrun-<org>-<repo>-<pr>.md` in cwd if `--output` is omitted. Pass `--output -` to stream to stdout instead.

### 2. Stream to stdout

```bash
ayan review --dry-run https://github.com/org/repo/pull/42 --output -
```

Stream the transcript inline. Status logs go to stderr so stdout is clean markdown.

### 3. Repo+PR flags instead of URL

```bash
ayan review --dry-run --repo org/repo --pr 42 --output /tmp/ayan-findings.md
```

Same behavior; useful in scripts that already have the (repo, pr) tuple split.

### 4. Force re-review of a previously-reviewed commit

```bash
ayan review --dry-run --force https://github.com/org/repo/pull/42 --output -
```

By default ayan dedups: if the same head SHA was already reviewed, it skips. `--force` re-runs the full pipeline. In dry-run mode, dedup uses whatever storage backend is configured (usually memory for one-off runs, postgres for long-lived deployments).

### 5. Custom config file

```bash
ayan review --dry-run --config /path/to/ayan.yaml https://github.com/org/repo/pull/42 --output -
```

Picks up a non-default config (severity thresholds, model selection, enabled analyzers, etc.).

## Steps

1. Check auth: `gh auth status`. If failed, stop and ask user to authenticate.
2. Confirm the PR URL is valid: `gh pr view <URL> --json title,state,headRefName` (cheap sanity check; not strictly required).
3. Run `ayan review --dry-run <URL> --output /tmp/ayan-findings.md`.
4. Read `/tmp/ayan-findings.md` after completion.
5. Summarize the findings to the user — counts by severity, then walk the most important ones with file:line addresses.
6. Ask whether to:
   - Address findings locally (load the PR's branch and apply fixes), OR
   - Post the comments live (switch to `ayan-review-pr-post`), OR
   - Just close out — the review was for evaluation.

## Heartbeat & latency

PR reviews are typically larger than local reviews (more files, deeper history). Expected duration: 2–15 minutes for a typical PR. The heartbeat log every 30s shows progress. Don't kill the process unless the heartbeat stalls completely.

## Output shape

```
# ayan review transcript
Captured at: <RFC3339>
**Counts:** N inline, M summary, K replies, L approvals.

---
## Summary comment(s)
<the overall review body — would have been posted as the top PR comment>

---
## Inline comments (N)
### 1. `path/to/file.py:108`
<would have appeared on file.py line 108 as an inline comment>

---
## +1 replies (K)
<replies to existing bot threads — issues that re-surfaced on the new commit>

---
## Approvals (L)
<only present if --approve was passed; never reaches GitHub in dry-run>
```

## Don'ts

- Don't tell the user "comments were posted" — nothing reaches the PR.
- Don't run on a fork PR expecting the same behavior as a same-repo PR — ayan auto-disables cross-repo context on fork PRs for security reasons. Read the transcript carefully; some advisory notes may explain skipped features.
- Don't mix this with `ayan-review-pr-post` in the same conversation without an explicit user confirmation — they have opposite intent.
