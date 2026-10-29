---
name: local
description: Review local git commits or uncommitted edits with ayan, without touching any remote. Use after finishing a chunk of work, before committing, or before pushing. No PR needed.
allowed-tools: Bash(ayan *), Bash(git *), Bash(*install-ayan.sh), Agent, Read
---
## When to use
- The user finished a non-trivial chunk of work, is about to commit or push, or asks to review local changes.
- Not for a PR URL: use `pr-dryrun` or `pr-post`.

## Steps
1. Pre-flight. If `command -v ayan` fails, run `${CLAUDE_PLUGIN_ROOT}/bin/install-ayan.sh` (native binary, Docker wrapper as fallback). Then `ayan version --check v0.1.0`; on failure stop and show the message.
2. Pick the diff flags: uncommitted edits `--working-tree`; commits on a branch `--base main` (use `master` or `develop` if main does not exist; any ref works, and `--head` too). Add `--repo-path` for another checkout.
3. Pick the path. Use B when `ayan.yaml` exists in the repo or the user asks for ayan's own LLM review. Otherwise use A.

### A. Claude Code is the reviewer (no API key)
1. `ayan rules --lang <go,python,ruby: those in the diff>` prints the rules. Run `ayan static <flags>` for the linter findings as JSON; a linter that is not installed is reported on stderr and skipped.
2. Launch the `pragmatic-review:reviewer` agent. Its prompt holds the rules text, the flags, and the linter JSON.
3. Pipe its JSON array through the filter:
   ```bash
   ayan filter <flags> <<'EOF'
   [...the agent's array...]
   EOF
   ```
   The result is what is worth fixing: snapped to changed lines, deduplicated, under the thresholds.

### B. ayan reviews with its own LLM key
```bash
ayan review --local <flags> --output -
```
Stdout is the markdown transcript (logs go to stderr). `--only staticanalysis` runs the linters alone in seconds; `--only review` skips them. A full review takes 1 to 5 minutes.

## Then
Work through the findings by severity (blocker, warning, suggestion), using the `path:line` addresses. Show each, apply the fix when it is clearly right, and ask when you disagree. If there are none, say "ayan found nothing".

## Don'ts
- Don't pass `--approve` here.
- Don't write findings to a file: with the Docker wrapper a file lands inside the container. Read stdout.
