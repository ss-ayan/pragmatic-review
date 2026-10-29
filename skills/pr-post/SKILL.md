---
name: pr-post
description: Review a GitHub pull request with ayan and post the review (inline comments, summary, optional approval) to the PR. Use only when the user explicitly asked for a live review; it writes to GitHub. To preview first, use pr-dryrun.
allowed-tools: Bash(ayan *), Bash(gh pr view *), Bash(gh auth status), Bash(*install-ayan.sh), Read
---
## When to use
Only when the user explicitly asks ayan to leave comments on a PR ("review this PR", "post the ayan review", "approve if clean" which means `--approve`). If they said dry run or preview, or are unsure, use `pr-dryrun`. With no PR, use `local`.

`ayan review <URL>` posts one GitHub review (inline comments plus a summary). With `--approve` it also approves when there are no blocker findings. Posting is visible immediately and cannot be undone. It needs ayan's LLM key in `ayan.yaml` and a token with write access (`GITHUB_TOKEN`, or `gh auth login`).

## Steps
1. Pre-flight. If `command -v ayan` fails, run `${CLAUDE_PLUGIN_ROOT}/bin/install-ayan.sh`. Then `ayan version --check v0.1.0` and `gh auth status`; on failure stop and show the message.
2. `gh pr view <URL> --json state,isDraft,headRefName`. Warn if it is a draft (skipped by default) or closed.
3. Confirm: "I'll run ayan on PR #N. It will post inline comments and a summary, and will [or will not] approve. Proceed?" Wait for an explicit yes.
4. Run `ayan review [--approve] [--force] [--only review|staticanalysis] <URL>`. Wait for it to finish: stopping mid-post leaves partial comments.
5. Report "Posted N inline comments [and an approval]" with the PR link. Summarize; don't paste the comments back.

## Failures
- 401/403: the token lacks write scope. Ask the user to refresh it.
- 429: ayan retries; some comments may already be posted. Let the user decide on `--force`.

## Don'ts
- Don't post without an explicit yes. Don't use `--approve` unless the user authorized an approval.
