# pragmatic-review

Claude Code plugin. Each `skills/<name>/SKILL.md` (frontmatter: name, description, allowed-tools) drives the `ayan` CLI. Each skill's first step gates on `ayan version --check` against `requires.ayan_version` in `.claude-plugin/plugin.json`. For a release, bump `version` there and tag.
