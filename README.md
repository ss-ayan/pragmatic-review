# pragmatic-review

Claude Code plugin that reviews your code with [ayan](https://github.com/ss-ayan/ayan).

| Command | Does |
|---|---|
| `/pragmatic-review:local` | Reviews local commits or working-tree edits. Claude Code is the reviewer (no API key), or `ayan review --local` with `ayan.yaml` |
| `/pragmatic-review:pr-dryrun` | `ayan review --dry-run <PR>`; nothing is posted |
| `/pragmatic-review:pr-post` | `ayan review <PR>`; posts after confirmation |
| `/pragmatic-review:profile` | `ayan profile`; learns the repo's conventions |

```bash
git clone https://github.com/ss-ayan/pragmatic-review.git
claude --plugin-dir ./pragmatic-review
```

The skills install `ayan` on first use with `bin/install-ayan.sh`: the native release binary into `~/.local/bin`, or a Docker wrapper when there is none for your platform. The minimum version is in `.claude-plugin/plugin.json`. PR commands also need `GITHUB_TOKEN` or `gh auth login`. Optional linters on PATH: `golangci-lint`, `ruff`, `rubocop`, `brakeman`.
