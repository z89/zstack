---
name: z:debug
description: Systematic root cause debugging — six-phase investigation with bounded retries, scope lock, and escalation rules
---

# z:debug — Root Cause Debugging

## Iron Law

**No fixes without root cause investigation first.**

Fixing symptoms creates whack-a-mole debugging. Every fix that skips root cause analysis makes the next bug harder to find.

Runs on all tiers (Quick, Standard, Full).

---

## Phase 1: Root Cause Investigation

Gather context before forming any hypothesis.

1. **Read error messages carefully.** Stack traces completely. Note line numbers, file paths, error codes.
2. **Read the code.** Trace the code path from symptom to potential causes. Use Grep for references, Read for logic.
3. **Check recent changes:**
   ```bash
   git log --oneline -20 -- <affected-files>
   ```
   If the bug is a regression, root cause is in the diff.
4. **Reproduce.** Can you trigger it deterministically? If not, gather more evidence. Do not guess.
5. **Trace data flow.** Where does the bad value originate? What called this with bad input? Keep tracing upstream until you find the source.

For multi-component systems (API, service, database, etc.):
- Add diagnostic instrumentation at each boundary BEFORE proposing fixes
- Log what enters and exits each component
- Run once to gather evidence showing WHERE it breaks
- THEN investigate the specific failing component

**Output:** "Root cause hypothesis: ..." — a specific, testable claim.

---

## Phase 2: Pattern Analysis

Check if the bug matches a known pattern:

| Pattern | Signature | Where to look |
|---------|-----------|---------------|
| Race condition | Intermittent, timing-dependent | Concurrent access to shared state |
| Nil/null propagation | TypeError, undefined is not | Missing guards on optional values |
| State corruption | Inconsistent data, partial updates | Transactions, callbacks, hooks |
| Integration failure | Timeout, unexpected response | External API calls, service boundaries |
| Configuration drift | Works locally, fails in prod | Env vars, feature flags, DB state |
| Stale cache | Shows old data, fixes on clear | Redis, CDN, browser cache |

Also check:
- `git log` for prior fixes in the same area. Recurring bugs in one area = architectural smell.
- Web search for `{framework} {error type}`. Sanitize first: strip hostnames, IPs, paths, customer data.

---

## Phase 3: Hypothesis Testing

Before writing ANY fix:

1. **Form a single hypothesis:** "I think X is the root cause because Y"
2. **Test minimally:** smallest possible change to verify. One variable at a time.
3. **Verify:** did it work? Yes = proceed to Phase 4. No = new hypothesis.

### 3-Strike Rule

If 3 hypotheses fail, STOP. This is likely architectural, not a simple bug.

Present the escalation:
```
3 hypotheses tested, none match. This may be architectural.
A) Continue — I have a new hypothesis: [describe]
B) Escalate — needs someone who knows the system
C) Add logging — instrument the area, catch it next time
```

---

## Phase 4: Scope Lock

After forming root cause hypothesis, restrict edits to the affected module.

Identify the narrowest directory containing the affected files. Report to the user:

> Edits restricted to `<dir>/` for this debug session. Prevents accidental changes to unrelated code.

Do not touch files outside the locked scope without explicit user approval.

---

## Phase 5: Implementation

1. **Fix the root cause, not the symptom.** Smallest change that eliminates the actual problem.
2. **Minimal diff.** Fewest files, fewest lines. Do not refactor adjacent code.
3. **Write a regression test** that:
   - FAILS without the fix
   - PASSES with the fix
4. **Run the full test suite.** No regressions.
5. **Blast radius check:** if the fix touches >5 files, flag it.

### Bounded Retry

- After implementing a fix, run tests.
- If tests still fail: analyze the failure, fix (attempt 1).
- If still failing: one more attempt (attempt 2).
- If still failing: STOP and escalate. Do NOT attempt fix #3 without discussing architecture.

---

## Phase 6: Verification & Report

Fresh verification: reproduce the original bug and confirm it is fixed. This step is NOT optional.

### Debug Report

```
DEBUG REPORT
══════════════════════════════════════
Symptom:         [what the user observed]
Root cause:      [what was actually wrong]
Fix:             [what was changed, with file:line references]
Evidence:        [test output showing fix works]
Regression test: [file:line of the new test]
Status:          DONE | DONE_WITH_CONCERNS | BLOCKED
══════════════════════════════════════
```

---

## Red Flags — STOP and Return to Phase 1

- "Quick fix for now" — there is no "for now"
- Proposing a fix before tracing data flow — that is guessing
- Each fix reveals a new problem — wrong layer, not wrong code
- "Should work now" without running verification
- "One more fix attempt" after 2+ failures

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to investigate" | Simple bugs have root causes too |
| "Emergency, no time" | Systematic is faster than thrashing |
| "Just try this first" | First fix sets the pattern. Do it right. |
| "I see the problem" | Seeing symptoms is not understanding root cause |
| "One more fix" (after 2+) | 3+ failures = architectural problem |
