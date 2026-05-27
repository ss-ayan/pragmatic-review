---
name: pr-post
description: Review a GitHub pull request with ayan AND post inline comments, a summary, and (optionally) an approval directly to the PR. Use ONLY when the user has explicitly asked for a live review on the PR — this writes to GitHub. For previewing first, use pr-dryrun.
allowed-tools: Bash(ayan *), Bash(gh pr view *), Bash(gh auth status), Read
---

## When to use this skill

Invoke ONLY when the user has explicitly asked for ayan to leave comments on the PR. Trigger phrases:

- "Review this PR" + a PR URL (and no "dry run" qualifier)
- "Post the ayan review to PR #N"
- "Run ayan on this PR and leave comments"
- "Approve PR #N with ayan if it's clean" (use `--approve`)

DO NOT invoke this skill when:
- The user said "dry run", "preview", "without posting", "before posting" — use `pr-dryrun`.
- No PR URL is in scope — use `local`.
- The user is unsure whether to post — default to `pr-dryrun` and ask.

## What live mode does

`ayan review <PR URL>` exercises the full pipeline AND posts:

- **Inline comments** on file:line addresses inside the diff
- **One summary comment** at the bottom of the PR with overall notes
- **"+1" replies** to any of ayan's prior comment threads that re-surface on this commit
- **PR approval** ONLY if `--approve` is passed AND no blocker-severity findings exist

Posting is irreversible — the comments are visible to anyone with PR access immediately. Confirm intent before invoking.

## Requires

This skill requires ayan **v4.0.13 or later** and a `GITHUB_TOKEN` (with `repo` write scope) OR `gh auth login` with write access. Reviewer-only tokens cannot post comments. Step 1 verifies.

## Confirmation gate

Before running, repeat back what will happen:

> "I'll run ayan on PR #N at <URL>. This will post inline comments on findings, a summary comment, and any +1 replies to existing threads. Approval will [be / not be] requested. Proceed?"

Wait for explicit "yes" / "go". Don't proceed on ambiguous responses.

## Invocation modes

### 1. Live review (default — comments only, no approval)

```bash
ayan review https://github.com/org/repo/pull/42
```

### 2. Live review with approval gate

```bash
ayan review --approve https://github.com/org/repo/pull/42
```

After posting comments, if there are zero blocker-severity findings, ayan submits an APPROVE review.

### 3. Force re-review (override dedup)

```bash
ayan review --force https://github.com/org/repo/pull/42
```

### 4. Custom config

```bash
ayan review --config /path/to/ayan.yaml https://github.com/org/repo/pull/42
```

### 5. Restrict analyzers (`--only` / `--skip`)

```bash
ayan review --skip slop https://github.com/org/repo/pull/42        # full review minus slop (faster)
ayan review --only security https://github.com/org/repo/pull/42    # security-only review
```

## Steps

1. **Pre-flight: verify ayan + write-scoped GitHub auth.**
   ```bash
   ayan version
   gh auth status
   ```
   Surface error if ayan is missing/old or token lacks write access.

2. Re-read the user's request — is the intent definitely "post to GitHub"? If ambiguous, ask before continuing.

3. Confirm the PR is in the expected state:
   ```bash
   gh pr view <URL> --json state,isDraft,headRefName
   ```
   If the PR is draft, ayan will skip by default — warn the user.

4. State the confirmation gate (above), wait for explicit "go".

5. Run `ayan review <URL>` (with `--approve` if requested).

6. Watch the heartbeat. On completion, fetch the PR comments to confirm:
   ```bash
   gh pr view <URL> --comments | head -50
   ```

7. Report back: "Posted N inline + M summary [+ approval]. PR is at <URL>."

## Heartbeat & latency

Live PR reviews emit the same heartbeat as dry-run. Wait for completion — interrupting mid-post may leave a partial set of comments. If the heartbeat stalls for >3 minutes, the claude-cli subprocess may be hung; investigate before killing.

## Failure modes

- **Auth 401/403**: token lacks write scope. Stop and ask user to refresh credentials.
- **PR closed/merged**: ayan still runs but comments are posted on a closed PR. Warn the user.
- **Rate limited**: GitHub returns 429. ayan retries with backoff; partial comments may already be posted. Surface and let the user decide whether to rerun with `--force`.

## Don'ts

- Don't run without an explicit user-side "post to GitHub" confirmation. The wrong default is to post.
- Don't run `--approve` on a PR the user hasn't authorized you to approve. Approvals carry weight.
- Don't run on a draft PR without flagging that draft-skip is configured (the run will be a no-op).
- Don't paste the full transcript back to the user after a live run — the comments are on GitHub now, so summarize instead.
