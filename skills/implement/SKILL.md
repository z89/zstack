---
name: z:implement
description: Execute a plan produced by z:plan using TDD, subagent dispatch, worktree isolation, and deterministic quality gates. Handles all tiers from inline Quick to parallel Full.
---

# z:implement — Implementation Engine

## When to Use

Run `/z:implement` after `/z:plan` has produced a plan document. Can also be invoked standalone for small changes (Quick tier).

Runs on all tiers.

---

## TDD Policy

### Full tier — strict TDD

- No production code without a failing test first
- Wrote code before the test? Delete it. Start over.
- Cycle: RED (write failing test) -> verify fails -> GREEN (minimal implementation) -> verify passes -> REFACTOR -> commit

### Standard / Quick tier — flexible order

- Tests must exist for every feature and bugfix
- Writing order is flexible (implementation first is acceptable)
- Every function that does something testable gets a test
- Edge cases and error paths are covered

### All tiers — exceptions (no tests needed)

- Config file changes
- CSS/styling-only changes
- Documentation
- Infrastructure-as-code (Terraform, Pulumi)
- Generated code

---

## Subagent Dispatch

### Quick tier

No subagents. Implement inline in the current conversation.

### Standard tier — sequential subagents

1. Dispatch one fresh subagent per task
2. Each subagent receives the implementer prompt (`implementer-prompt.md`) with the task injected
3. After each task completes, run two-stage review:
   - **Stage 1:** Spec compliance review (`spec-reviewer-prompt.md`) — does it match the plan?
   - **Stage 2:** Code quality review (`code-quality-reviewer-prompt.md`) — is the code good?
4. If a reviewer finds issues, the implementer fixes them and the reviewer re-reviews
5. **Bounded retry:** 2 fix attempts max. If still failing after 2 attempts, escalate.

### Full tier — parallel subagents (up to 5)

1. Each subagent works in its own worktree
2. Independent task groups (from `/z:plan` parallel analysis) dispatch simultaneously
3. Sequential tasks within a group run in order
4. After all complete, merge sequentially and resolve conflicts
5. Rate limit handling: start with 2 concurrent subagents, ramp up if no 429 errors
6. If rate limited, fall back to sequential dispatch

---

## Worktree Management (Standard + Full)

Before implementation begins:

1. Check for existing `.worktrees/` directory
2. If not found, create `.worktrees/` and add it to `.gitignore`
3. Create worktree:
   ```bash
   git worktree add .worktrees/<branch-name> -b <branch-name>
   ```
4. Run project setup (detect from `.zstack/project.json`):
   - **pnpm:** `pnpm install` (fast, shared store)
   - **npm/yarn:** install with warning about disk usage
   - **cargo:** `cargo build`
   - **go:** `go mod download`
   - **python:** `pip install -e .` or equivalent
5. Run baseline tests to verify a clean start
6. Capture baseline (runs automatically):
   ```bash
   ZSTACK_DIR=$(dirname $(dirname $(readlink -f ~/.claude/skills/z:build))) && bash "$ZSTACK_DIR/bin/zstack-baseline"
   ```
   This snapshots pre-existing lint/typecheck/test failures so the quality gate hooks only block on NEW failures the agent introduces, not pre-existing ones.

---

## Deterministic Quality Gates

These run automatically via hooks. The agent cannot skip them.

- **PostToolUse hook:** Lint the changed file after every file write
- **PreToolUse hook (git commit):** Type check + run colocated tests before every commit
- **Baseline-aware:** Only block on NEW failures, not pre-existing ones

---

## Bounded Retry

When lint or tests fail after implementation:

1. **Attempt 1:** Fix the issue and retry
2. **Attempt 2:** Fix again and retry
3. **Escalate:** Stop and report

```
STATUS: BLOCKED
REASON: [failure description]
ATTEMPTED: [what was tried across both attempts]
RECOMMENDATION: [what the user should do]
```

---

## Scope Escalation

Track files touched during implementation:

- **Quick tier touches >5 files:** Pause. Suggest upgrading to Standard.
- **Standard tier touches >15 files:** Pause. Suggest upgrading to Full.

On upgrade: stash changes, create worktree, apply stash, continue with higher tier.

---

## Checkpointing

After each task completes:

```bash
zstack-checkpoint write --plan <file> --task N --total T --completed "1,2,3"
```

On context compaction or session restart, the checkpoint enables resume from the last completed task.

---

## Verification Before Completion

**Iron Law:** No completion claims without fresh verification evidence.

- Run the verification command in THIS response before claiming it passes
- "Should work" is not evidence. Run it.
- Evidence before claims, always.

---

## Context Management

- Write subagent results to disk at `.zstack/reports/`
- Carry one-line summaries in context, not full outputs
- Reference files rather than keeping results in conversation memory

---

## Completion Status

Report exactly one of:

- **DONE:** All tasks complete, all tests pass, evidence provided
- **DONE_WITH_CONCERNS:** Complete but with issues listed (each issue described)
- **BLOCKED:** Cannot proceed. What was tried. What the user should do.
- **NEEDS_CONTEXT:** Missing information. Exactly what is needed.
