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

The baseline capture (`zstack-baseline`) runs automatically at the start of every pipeline via `/z:implement`. You do not need to run it manually after setup. It captures pre-existing lint/test failures so quality gates only block on new regressions.

If the user wants to capture a baseline immediately (e.g., to inspect it), they can run:

```bash
ZSTACK_DIR=$(dirname $(dirname $(readlink -f ~/.claude/skills/z:build))) && bash "$ZSTACK_DIR/bin/zstack-baseline"
```
