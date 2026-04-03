---
name: z:build
description: Router skill — detects project type and task scope, selects the right pipeline tier (Quick/Standard/Full), orchestrates the build lifecycle
argument-hint: [task description or --quick/--standard/--full]
allowed-tools: Bash, Read, Glob, Grep, Write, Edit, Agent
---

# Build Router

Entry point for all work. Detects context, classifies scope, runs the right pipeline.

## 1. Project Detection

Read `.zstack/project.json` from the current working directory. If it does not exist, tell the user:

> No `.zstack/project.json` found. Run `/z:setup` from your project root to generate one.

Stop here until the file exists.

Extract from `project.json`:
- `type`: one of `web-app`, `api`, `cli`, `library`, `desktop-app`, `infrastructure`, `unknown`
- `name`, `language`, `framework`, `testRunner`, `packageManager`

If `type` is `unknown`, ask the user to classify it before proceeding.

## 2. Task Scope Detection

Classify the user's prompt into one of three tiers.

### Quick
Single file change, config tweak, styling fix, typo, small bug fix.

Signals:
- Mentions one file, one component, or one function
- No architectural changes
- Words like "fix", "tweak", "update", "rename", "typo", "adjust"

### Standard
Multi-file feature, new component, refactor, medium bug fix.

Signals:
- Mentions a feature or component to build
- References multiple files or "add X to Y"
- Words like "add", "create", "refactor", "implement", "component"

### Full
New app, major feature, new subsystem, production ship, design decisions required.

Signals:
- "Build an app", "new feature", "redesign", "from scratch"
- Multiple subsystems involved
- Words like "architecture", "system", "redesign", "migrate", "launch"

### Confidence Gate

If confidence in the detected tier is below 70%, ask:

> This looks like a **[tier]** task. Confirm, or override with a different tier?

### Tier Override

User can force a tier with `--quick`, `--standard`, or `--full` flags. These bypass auto-detection.

## 3. Scope Escalation

Monitor file count during implementation:
- **Quick**: if more than 5 files are touched, pause and suggest upgrading to Standard
- **Standard**: if more than 15 files are touched, pause and suggest upgrading to Full

## 4. Checkpoint Resume

On startup, run `zstack-checkpoint verify`. If a valid checkpoint exists, offer to resume from where the previous session left off. Present the checkpoint summary and ask the user to confirm or start fresh.

## 5. Pipelines

### Quick

```
/z:implement  (inline, no subagents, flexible test order)
/z:ship       (commit only)
```

### Standard

```
/z:plan       (task decomposition)
Create worktree
/z:implement  (sequential subagents, flexible test order)
/z:review
/z:qa         (adapted to app type)
/z:ship       (PR + CI monitor)
```

### Full

```
/z:design     (brainstorm + spec)
/z:plan       (task decomposition with parallel execution analysis)
Create worktree
/z:implement  (parallel subagents, up to 5, strict TDD)
/z:review
/z:qa         (adapted to app type)
/z:secure     (security audit)
/z:ship       (PR + CI + deploy verify)
```

## 6. Skip Flags

User can pass any of these to skip a phase:
- `--skip-secure`
- `--skip-qa`
- `--skip-review`
- `--skip-design`

Record all skipped phases internally. `/z:ship` will emit a warning listing what was skipped so the user makes an informed decision before merging.

## 7. App Type Adaptations

The pipeline adapts based on the detected app type:

| App Type         | /z:qa Behavior               | /z:implement Notes              | /z:secure Focus             |
|------------------|------------------------------|---------------------------------|-----------------------------|
| `web-app`        | Visual regression + a11y     | Component tree awareness        | XSS, CSRF, auth flows       |
| `api`            | Endpoint testing, load check | Route/handler structure         | Auth, injection, rate limits |
| `cli`            | Arg parsing, exit codes      | Command/subcommand structure    | Input validation, path traversal |
| `library`        | API surface tests, examples  | Public API contract awareness   | Dependency audit             |
| `desktop-app`    | Platform smoke tests         | IPC/renderer split              | Sandbox, update mechanism    |
| `infrastructure` | Plan diff review             | State file awareness            | IAM, network exposure        |

Specific rules:
- **CLI** and **library** apps skip visual QA entirely. `/z:qa` runs functional tests only.
- **API** apps replace visual QA with endpoint contract testing and response validation.
- **Infrastructure** replaces `/z:qa` with a plan diff review (dry-run validation).
- **Web-app** and **desktop-app** get the full visual QA pass.

## 8. Execution

When invoked:

1. Read `.zstack/project.json`
2. Parse user prompt and any flags
3. Detect or override tier
4. Check for checkpoint
5. Print the selected pipeline to the user:
   ```
   Project: <name> (<type>)
   Tier: <tier>
   Pipeline: /z:design -> /z:plan -> /z:implement -> /z:review -> /z:qa -> /z:ship
   Skipped: [none | list]
   ```
6. Ask for confirmation, then begin executing phases in order
7. Between each phase, save a checkpoint via `zstack-checkpoint write`
