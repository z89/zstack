---
name: z:ship
description: Ship skill — handles PR creation, CI monitoring with bounded retry, and post-deploy verification across Quick/Standard/Full tiers
---

# Ship

Handles the full shipping pipeline: PR creation, CI monitoring, merge, and post-deploy verification.

## Tier Behavior

- **Quick**: commit only (no PR, no CI monitoring)
- **Standard**: create PR + monitor CI + bounded retry on failures
- **Full**: create PR + monitor CI + bounded retry + post-deploy verification

## Step 0: Pre-Ship Checks

1. Read `.zstack/project.json` for `testRunner`, `testCommand`, `type`.

2. Check for skipped steps (from `/z:build` skip flags):
   - If `/z:review` was skipped: `WARNING: Code review was skipped.`
   - If `/z:qa` was skipped: `WARNING: QA was not run.`
   - If `/z:secure` was skipped: `WARNING: Security audit was skipped.`
   - Ask: "Ship anyway, or run the skipped checks first?"

3. Run full test suite (not just colocated tests — this is the one time everything runs).

4. If tests fail: apply bounded retry (2 attempts, then escalate).

## Step 1: Base Branch Detection

```
GitHub: gh pr view --json baseRefName → gh repo view --json defaultBranchRef
Git fallback: git symbolic-ref refs/remotes/origin/HEAD → try main → try master
```

## Step 2: Sync with Base

```bash
git fetch origin <base>
git merge origin/<base>
```

If merge conflicts arise: resolve or escalate to the user.

## Step 3: Create PR (Standard + Full)

Structured PR description:

```markdown
## Summary
[1-3 bullet points from the plan/implementation]

## Changes
[List of files changed with brief description]

## Testing
[Test results: X tests passing, 0 failing]
[QA results if /z:qa was run]
[Security results if /z:secure was run]

## Skipped Checks
[List any skipped checks from /z:build flags]
```

Create PR:
```bash
gh pr create --title "..." --body "..."
```

## Step 4: CI Monitoring (Standard + Full)

1. Poll CI status: `gh run list --branch <branch> --limit 1`
2. Wait for completion (poll every 30 seconds, timeout after 15 minutes).
3. On CI failure:
   - Read failure logs: `gh run view <id> --log-failed`
   - Analyze failure
   - Create fix commit
   - Push (attempt 1)
   - If CI fails again: read logs, create fix, push (attempt 2)
   - If CI fails a third time: STOP and escalate:
   ```
   STATUS: BLOCKED
   REASON: CI failed after 2 fix attempts
   FAILURES: [list of failing checks]
   RECOMMENDATION: Review CI logs manually
   ```

## Step 5: Post-Deploy Verification (Full Tier Only)

If deploy URL is configured in `.zstack/project.json`:

1. Wait for deploy to complete (poll deploy status or wait 60 seconds).
2. Hit the deploy URL with curl, verify 200.
3. If the app is a web-app, run a quick Playwright smoke test:
   - Navigate to deploy URL
   - Check for console errors
   - Verify key pages load
4. Report: `Deploy verified at [URL]. No errors detected.` or `Deploy FAILED: [details]`

## Step 6: Cleanup

- Clear checkpoint: `zstack-checkpoint clear`
- If worktrees were used, list them for manual cleanup:
  `Worktrees at .worktrees/ can be removed: git worktree remove .worktrees/<name>`

## Quick Tier — Commit Only

Skip all PR/CI steps. Just:

1. Run pre-ship checks (lint + typecheck + colocated tests via hooks).
2. Commit with descriptive message.
3. Clear checkpoint if one exists.

## Ship Report

```
SHIP REPORT
══════════════════════════════════════
Branch:      [branch] → [base]
PR:          [URL or "commit only"]
CI:          [PASS | PASS_AFTER_RETRY | FAILED | SKIPPED]
Deploy:      [VERIFIED | NOT_CONFIGURED | FAILED | SKIPPED]
Tests:       [N passing, 0 failing]
Skipped:     [list of skipped checks, or "none"]

STATUS: SHIPPED | BLOCKED
══════════════════════════════════════
```
