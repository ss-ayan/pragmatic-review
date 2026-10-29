---
name: profile
description: Profile a repository so ayan learns its conventions and uses them in later reviews. Run once when onboarding a repo or after a major refactor. Not a code review.
allowed-tools: Bash(ayan *), Bash(gh auth status), Bash(*install-ayan.sh), Read
---
## When to use
- Onboarding ayan on a repo, or after the repo's conventions changed a lot.
- Not for reviewing code: use `local`, `pr-dryrun` or `pr-post`.

`ayan profile --repo org/repo` reads the repo at a ref (naming, error handling, tests, architecture, `.golangci.yml`, `CONTRIBUTING.md`, `CLAUDE.md`) and saves conventions to ayan's storage. Reviews for that repo then quote them. The storage must be postgres in `ayan.yaml`; with memory storage `ayan profile` refuses to run, because the results would vanish. It needs ayan's LLM key and `GITHUB_TOKEN` or `gh auth login`.

## Steps
1. Pre-flight. If `command -v ayan` fails, run `${CLAUDE_PLUGIN_ROOT}/bin/install-ayan.sh`. Then `ayan version --check v0.1.0` and `gh auth status`.
2. `ayan profile --repo <org/repo>`, or `ayan profile <URL>`. `--ref` takes a branch, tag or SHA (default `main`). It takes 5 to 20 minutes on a large repo.
3. It ends with `Profile complete: N conventions discovered, M saved`. Report that.
4. To use the saved conventions without ayan's LLM key, `ayan rules --repo <org/repo>` prints them with the rubric (the `local` skill does not do this by itself).

## Don'ts
- Don't profile on every PR, or a repo that isn't the user's.
