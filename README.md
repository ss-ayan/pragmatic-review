# pragmatic-review

Claude Code plugin that runs [ayan](https://github.com/ss-ayan/ayan) reviews from inside a session. Claude then works through the findings.

| Command | Runs |
|---|---|
| `/pragmatic-review:local` | `ayan review --local` on commits or working-tree edits |
| `/pragmatic-review:pr-dryrun` | `ayan review --dry-run <PR>` (nothing is posted) |
| `/pragmatic-review:pr-post` | `ayan review <PR>` (posts comments; asks for confirmation first) |
| `/pragmatic-review:profile` | `ayan profile` (learns the repo's conventions) |

```bash
git clone https://github.com/ss-ayan/pragmatic-review.git
claude --plugin-dir ./pragmatic-review
```

Needs `ayan` ≥ the version in `.claude-plugin/plugin.json` on `$PATH` ([install](https://github.com/ss-ayan)). PR commands also need `GITHUB_TOKEN` or `gh auth login`.
