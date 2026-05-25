---
name: ayan-profile
description: Profile a repository to teach ayan its conventions, naming patterns, and idioms. Run once when bootstrapping ayan on a new repo or after major refactors so future reviews ground on the repo's actual style instead of language defaults. Not a code review — this populates a knowledge base.
allowed-tools: Bash(ayan profile *), Read
---

## When to use this skill

Invoke when:
- The user is onboarding ayan onto a new repo: "set up ayan for this repo" / "teach ayan our conventions".
- The repo's conventions have drifted (large refactor, new style guide) and the user wants ayan to re-learn.
- Future review quality has been low and the user asks why ayan is missing the repo's conventions.

Skip when:
- The user just wants a review — that's `ayan-review-local` / `ayan-review-pr-*`. Profiling does NOT review code.
- The repo has already been profiled recently (within the last few weeks) and nothing major has changed. Conventions live in postgres / memory storage; re-profiling re-emits the same knowledge.

## What profiling does

`ayan profile --repo org/repo` clones the repo at a given ref and runs multi-pass analysis to extract:

- **Naming conventions** — function casing, file naming, package layout
- **Error-handling idioms** — wrap/unwrap patterns, fmt.Errorf style, custom error types
- **Test patterns** — table-driven vs case-per-test, naming
- **Architecture signals** — directory roles, layering rules, common patterns
- **Style preferences** picked up from `.golangci.yml`, `.editorconfig`, `CONTRIBUTING.md`, `CLAUDE.md`, etc.

The output is a set of `Convention` records persisted to ayan's storage (postgres or memory). Future review runs grep that store and surface findings phrased in terms of the repo's own conventions.

## Authentication

Same as PR review skills — needs `gh auth login` or `GITHUB_TOKEN`. Profile fetches the repo via clone.

## Invocation

### 1. Profile main branch (most common)

```bash
ayan profile --repo org/repo
```

Defaults to `--ref main`. Pass `--ref master` / `--ref develop` for non-`main` defaults.

### 2. Profile a specific tag or SHA

```bash
ayan profile --repo org/repo --ref v2.0.0
ayan profile --repo org/repo --ref abc1234
```

Useful when conventions changed at a known milestone and you want to anchor on that.

### 3. Profile via positional URL

```bash
ayan profile https://github.com/org/repo
```

Same as `--repo org/repo`.

## Steps

1. Confirm auth: `gh auth status`.
2. Run `ayan profile --repo <org/repo>`. Profiling takes longer than a review (5–20 min on a large repo) — it walks many files.
3. Watch the output: each pass logs `<pass-name>: N conventions from M files`. Errors per-pass are surfaced as warnings; the profile still completes.
4. Summary at end: `Profile complete: N conventions discovered, M saved (duration)`.
5. Confirm to user: "Profiled <repo> at <ref>. ayan can now reference these conventions in future reviews."

## Latency

Profiling is the longest-running ayan command. Expect 5–20 minutes depending on repo size. The output streams pass-by-pass so there's no risk of "is it dead" silence — every pass writes a status line on completion.

## Don'ts

- Don't run profile expecting a code review — it writes to the knowledge store, doesn't post any comments.
- Don't run profile on every PR — profiling is a periodic operation, not a per-review step.
- Don't run profile on an unrelated fork — it ingests THAT repo's conventions, which won't match the base repo.
