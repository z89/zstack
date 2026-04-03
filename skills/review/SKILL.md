---
name: z:review
description: Diff-based code review with severity-ranked findings, app-type-aware checks, and optional auto-fix for critical issues
---

# z:review — Code Review

## When to Use

Run `/z:review` after implementation, before shipping. Scans the diff between the current branch and base for security issues, logic errors, and quality problems.

Runs on Standard and Full tiers.

---

## Setup

1. **Detect base branch:**
   ```bash
   gh pr view --json baseRefName -q '.baseRefName' 2>/dev/null || git rev-parse --abbrev-ref HEAD@{upstream} 2>/dev/null | sed 's|origin/||'
   ```
   If both fail, ask the user for the base branch.

2. **Get the diff:**
   ```bash
   git diff <base>...HEAD
   ```

3. **Read project context:**
   Read `.zstack/project.json` from the project root. Extract `type`, `language`, `framework`.

4. **Enable UI checks:**
   If `type` is `web-app` or `desktop-app`, include accessibility and UI-specific review criteria (sections 7 and relevant parts of 6 and 8).

---

## Review Checklist

Scan the diff for each category. Only report findings that appear in the actual diff.

### 1. SQL Safety

| Finding | Severity |
|---------|----------|
| Raw SQL with string interpolation | CRITICAL |
| Missing parameterized queries | CRITICAL |
| Unvalidated user input in queries | CRITICAL |

### 2. Trust Boundary Violations

| Finding | Severity |
|---------|----------|
| User input used without validation | HIGH |
| API responses used without validation | HIGH |
| LLM output used in security-sensitive context | CRITICAL |
| Environment variables used without fallback | MEDIUM |

### 3. Conditional Side Effects

| Finding | Severity |
|---------|----------|
| State mutations inside conditionals that could be skipped | HIGH |
| Missing error handling on network/IO operations | HIGH |
| Partial updates without transactions | HIGH |

### 4. Blast Radius

| Finding | Severity |
|---------|----------|
| Bug fix touching >10 files | Flag for discussion |
| Changes to shared utilities/helpers | Review all consumers |
| Database migration changes | Review carefully |
| Breaking API contract changes | Review carefully |

### 5. Error Handling

| Finding | Severity |
|---------|----------|
| Empty catch blocks | MEDIUM |
| Swallowed errors (catch and continue silently) | HIGH |
| Missing error boundaries in UI code | MEDIUM (web-app only) |

### 6. Performance

| Finding | Severity |
|---------|----------|
| N+1 query patterns | HIGH |
| Missing pagination on list endpoints | MEDIUM |
| Large synchronous operations | MEDIUM |
| Missing loading/error states in UI | MEDIUM (web-app only) |

### 7. Accessibility (web-app and desktop-app only)

| Finding | Severity |
|---------|----------|
| Images without alt text | MEDIUM |
| Interactive elements without labels | HIGH |
| Missing keyboard navigation | MEDIUM |
| Color-only indicators | MEDIUM |

### 8. App-Type-Specific Checks

**API:**
- Missing input validation on endpoints
- Missing rate limiting
- Inconsistent error response format

**CLI:**
- Missing help text
- Missing error messages for invalid input
- Hardcoded paths

**Library:**
- Breaking public API changes
- Missing type exports

**Infrastructure:**
- Hardcoded values that should be variables
- Missing outputs

---

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| CRITICAL | Security vulnerability, data loss risk | Must fix before merge |
| HIGH | Bug, logic error, missing error handling | Should fix before merge |
| MEDIUM | Code quality, maintainability, performance | Fix if time allows |
| LOW | Style, naming, minor improvements | Note for future |

---

## Report Format

```
CODE REVIEW REPORT
══════════════════════════════════════
Branch:    [current] → [base]
Files:     N changed
App type:  [from project.json]

FINDINGS:
  CRITICAL: N
  HIGH:     N
  MEDIUM:   N
  LOW:      N

[SEVERITY] file.ts:42 — description
  What: [what's wrong]
  Why:  [why it matters — connect to user impact]
  Fix:  [concrete fix suggestion]

VERDICT: PASS | PASS_WITH_WARNINGS | FAIL
══════════════════════════════════════
```

### Verdict Rules

- **FAIL**: any CRITICAL finding, or more than 3 HIGH findings. List all blockers.
- **PASS_WITH_WARNINGS**: any HIGH or MEDIUM findings below the FAIL threshold. List what should be addressed.
- **PASS**: no CRITICAL or HIGH findings, few or no MEDIUM/LOW.

---

## Auto-Fix

For CRITICAL and HIGH findings, offer to fix them:

```
Found N CRITICAL and N HIGH. Fix automatically? (y/n)
```

If accepted, apply fixes using the Edit tool. Re-run the relevant checks on the modified files to confirm the fix resolves the finding without introducing new issues.
