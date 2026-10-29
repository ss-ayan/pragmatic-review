---
name: pr-dryrun
description: Review a GitHub pull request with ayan without posting anything. Comments are captured into a local transcript. Use to preview what a live review would say, or to evaluate ayan on a real PR.
allowed-tools: Bash(ayan *), Bash(gh pr view *), Bash(gh auth status), Bash(*install-ayan.sh), Read
---
## When to use
- A PR URL plus "review without posting", "preview" or "dry run".
- To post for real, use `pr-post`. With no PR, use `local`.

`ayan review --dry-run` runs the full pipeline on the real PR but routes every comment, reply and approval into a transcript. The GitHub credentials are only used to read. It needs ayan's LLM key in `ayan.yaml` (`ayan init` writes one) and `GITHUB_TOKEN` or `gh auth login`.

## Steps
1. Pre-flight. If `command -v ayan` fails, run `${CLAUDE_PLUGIN_ROOT}/bin/install-ayan.sh`. Then `ayan version --check v0.1.0` and `gh auth status`; on failure stop and show the message.
2. Run it and read stdout (never a file: with the Docker wrapper a file lands inside the container):
   ```bash
   ayan review --dry-run <URL> --output -
   ```
   Or `--repo org/repo --pr 42`. `--force` re-reviews a commit that was already reviewed. `--only review` or `--only staticanalysis` runs one analyzer. `--config` points at another `ayan.yaml`. Expect 2 to 15 minutes.
3. Summarize by severity, then walk the important findings by `path:line`.
4. Ask whether to fix them locally, post them (`pr-post`), or stop.

## Don'ts
- Don't say comments were posted: nothing reaches the PR.
- Don't expect cross-repo context on fork PRs: it is disabled for them.
