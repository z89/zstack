# Deterministic Quality Gates

Quality gates are infrastructure, not suggestions. They run via Claude Code hooks
and cannot be rationalized away by the agent.

## Gate Architecture (Stripe-inspired)

```
Code Generation → PostToolUse Hook → Lint Changed File (instant)
                                          ↓ (if fail: error fed back to agent)
Commit Attempt → PreToolUse Hook (git commit) → Typecheck + Colocated Tests
                                          ↓ (if fail: commit blocked)
Ship (/z:ship) → Full Test Suite → PR → CI Monitor
                                          ↓ (if fail: bounded retry, 2 attempts)
```

## Layer 1: Instant (PostToolUse, <5 seconds)

Triggers on every `Edit` or `Write` tool use.
Runs the project's linter on the changed file only.
Configured in `settings/hooks.json`.

If the linter fails:
- The error is shown to the agent
- The agent must fix the issue before proceeding
- This catches syntax errors, import mistakes, and style violations immediately

## Layer 2: Fast (PreToolUse on git commit, <30 seconds)

Triggers on every commit attempt.
Runs typecheck + colocated tests (tests in the same directory as changed files).

Baseline-aware:
- On first run, `zstack-baseline` captures pre-existing errors
- The hook compares current errors against baseline
- Only BLOCKS on NEW failures (errors the agent introduced)
- Pre-existing failures are logged but don't block

If the gate fails:
- The commit is blocked
- The error output is shown to the agent
- The agent gets 2 attempts to fix (bounded retry)
- After 2 failures: escalate to user

## Layer 3: Thorough (/z:ship only)

Full test suite runs before PR creation.
This is the only time the complete suite runs.
No shortcuts: every test must pass (or be a known pre-existing failure).

If CI fails after PR:
- Read failure logs automatically
- Create fix commit, push (attempt 1)
- If still failing: one more fix + push (attempt 2)
- If still failing: STOP and escalate

## Baseline Awareness

The `zstack-baseline` script captures:
```json
{
  "lint_errors": 47,
  "typecheck_errors": 3,
  "test_failures": 2,
  "captured_at": "2026-04-01T12:00:00Z",
  "branch": "main"
}
```

This prevents the agent from being blocked by pre-existing issues.
The hook math: if `current_errors > baseline_errors`, block. Otherwise, pass.

## Incremental Testing Strategy

| Trigger | What runs | Time budget |
|---------|-----------|-------------|
| File edited | Lint that file | <5s |
| Commit | Typecheck + colocated tests | <30s |
| /z:ship | Full test suite | No limit |

Colocated test detection:
- `src/auth.ts` → look for `src/auth.test.ts`, `src/auth.spec.ts`, `tests/auth.test.ts`
- Changed test files are always included
- If no colocated test exists, skip (don't fail)

## When Gates Are Missing

If `.zstack/project.json` doesn't exist or has `"none"` for linter/test/typecheck:
- Hooks run in passthrough mode (warn but don't block)
- `/z:build` will suggest running `zstack-setup` to set up gates
- The system degrades gracefully, not catastrophically
