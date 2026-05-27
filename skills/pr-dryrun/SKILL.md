---
name: pr-dryrun
description: Review a GitHub pull request with ayan WITHOUT posting any comments to the PR. Captures every inline comment, summary, and approval into a local markdown transcript instead. Use when the user wants to evaluate ayan's findings before letting it speak on a real PR — also useful for previewing what a live review would produce.
allowed-tools: Bash(ayan *), Bash(gh pr view *), Bash(gh auth status), Read
---

## When to use this skill

Invoke when:
- The user mentions a GitHub PR URL and says "review this without posting" / "preview" / "dry run" / "what would ayan say".
- The user is debugging ayan's behavior and wants to see findings without affecting the PR.
- The user wants to dogfood ayan on a real PR to evaluate quality.

Skip when:
- The user wants comments actually posted to the PR — use `pr-post` instead.
- There's no PR URL — use `local` instead.

## What dry-run does

`ayan review --dry-run <PR URL>` exercises the full review pipeline against the real PR (fetches diff, indexes head SHA, runs analyzers, generates comments) but routes every would-be mutation through an in-memory decorator:

- **Inline comments** → captured into the transcript with file:line address
- **Summary comment** → captured into the transcript
- **"+1" replies** to existing threads → captured
- **PR approval** (if `--approve` is passed) → captured but never submitted

Nothing reaches GitHub. The bot's GitHub credentials are still used to READ the PR — they're just never used to write.

## Requires

This skill requires ayan **v4.0.13 or later** and either `GITHUB_TOKEN` env var or `gh auth login`. Step 1 verifies both.

## Invocation modes

### 1. Dry-run with file output (default)

```bash
ayan review --dry-run https://github.com/org/repo/pull/42 --output /tmp/ayan-findings.md
```

Default output path is `ayan-dryrun-<org>-<repo>-<pr>.md` in cwd if `--output` is omitted. Pass `--output -` to stream to stdout.

### 2. Stream to stdout

```bash
ayan review --dry-run https://github.com/org/repo/pull/42 --output -
```

Status logs go to stderr so stdout is clean markdown.

### 3. Repo+PR flags instead of URL

```bash
ayan review --dry-run --repo org/repo --pr 42 --output /tmp/ayan-findings.md
```

### 4. Force re-review of a previously-reviewed commit

```bash
ayan review --dry-run --force https://github.com/org/repo/pull/42 --output -
```

By default ayan dedups: same head SHA already reviewed → skip. `--force` re-runs.

### 5. Fast partial review (`--only` / `--skip`)

```bash
ayan review --dry-run --only security,staticanalysis https://github.com/org/repo/pull/42 --output -
ayan review --dry-run --skip idiom,slop https://github.com/org/repo/pull/42 --output -
```

Useful for evaluating only specific analyzer outputs on a PR.

### 6. Custom config file

```bash
ayan review --dry-run --config /path/to/ayan.yaml https://github.com/org/repo/pull/42 --output -
```

## Steps

1. **Pre-flight: verify ayan + GitHub auth.**
   ```bash
   ayan version --check v4.0.13
   gh auth status
   ```
   On non-zero exit from `ayan version --check`, stop and surface the stderr message (install/upgrade ayan). If `gh auth status` fails, stop and tell the user to run `gh auth login`.

2. Confirm the PR URL is valid:
   ```bash
   gh pr view <URL> --json title,state,headRefName
   ```
   Useful sanity check; not strictly required.

3. Run the dry-run:
   ```bash
   ayan review --dry-run <URL> --output /tmp/ayan-findings.md
   ```

4. Read `/tmp/ayan-findings.md` after completion.

5. Summarize the findings to the user — counts by severity, then walk the most important ones with `file:line` addresses.

6. Ask whether to:
   - Address findings locally (load the PR's branch and apply fixes), OR
   - Post the comments live (switch to `pr-post`), OR
   - Just close out — the review was for evaluation.

## Heartbeat & latency

PR reviews are typically larger than local reviews. Expected duration: 2–15 minutes for a typical PR. The heartbeat log every 30s shows progress. Don't kill unless the heartbeat stalls completely.

## Don'ts

- Don't tell the user "comments were posted" — nothing reaches the PR.
- Don't run on a fork PR expecting the same behavior as a same-repo PR — ayan auto-disables cross-repo context on fork PRs for security reasons.
- Don't mix this with `pr-post` in the same conversation without an explicit user confirmation — they have opposite intent.
