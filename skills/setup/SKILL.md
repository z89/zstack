---
name: z:setup
description: Detect project runtime, framework, app type, linter, test runner, and package manager. Writes .zstack/project.json.
---

# Project Setup

Run the setup script to generate `.zstack/project.json` for the current project.

## Instructions

Run this command:

```bash
ZSTACK_DIR=$(dirname $(dirname $(readlink -f ~/.claude/skills/z:build))) && bash "$ZSTACK_DIR/bin/zstack-setup"
```

Show the user the detected configuration from the output.

If any field is `unknown` or `none`, ask the user to clarify:
- If `app_type` is `unknown`: "What type of app is this? (web-app, api, cli, library, desktop-app, infrastructure)"
- If `linter` is `none`: "No linter detected. Want to set one up, or skip linting gates?"
- If `test_runner` is `none`: "No test runner detected. Want to set one up, or skip test gates?"

After detection, suggest running `zstack-baseline` to capture pre-existing lint/test state:

```bash
ZSTACK_DIR=$(dirname $(dirname $(readlink -f ~/.claude/skills/z:build))) && bash "$ZSTACK_DIR/bin/zstack-baseline"
```

This baseline allows the quality gate hooks to distinguish between pre-existing failures and new ones the agent introduces.
