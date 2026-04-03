---
name: z:qa
description: QA testing skill — adapts to app type, runs visual QA + a11y + endpoint/command/API surface testing, produces health scores and fixes bugs in a loop
---

# QA Testing

App-type-agnostic quality assurance. Runs on Standard and Full tiers.

## 0. Project Context

Read `.zstack/project.json` for `type`, `framework`, `testRunner`, `packageManager`. The QA approach changes based on app type:

- **web-app / desktop-app**: Playwright visual QA + axe-core a11y + form testing + responsive checks
- **api**: Endpoint testing (all routes, error responses, auth, rate limiting, input validation)
- **cli**: Command testing (all commands, flags, help text, error messages, edge cases, exit codes)
- **library**: API surface testing (all exports, type contracts, edge cases, error behavior)
- **infrastructure**: Plan/apply dry-run, state verification, drift detection

## 1. Web App / Desktop App — Playwright Visual QA

### Setup

1. Check if Playwright is installed. If not, offer to install:
   ```bash
   pnpm add -D @playwright/test && npx playwright install chromium
   ```
2. Detect if a dev server is needed. Check for `dev` script in `package.json`.
3. Start dev server if needed, wait for it to be ready.

### Testing Flow

1. Navigate to all discoverable routes/pages.
2. For each page:
   - Screenshot for evidence
   - Check for console errors
   - Check for broken images/links
   - Check responsive layout (mobile 375px, tablet 768px, desktop 1440px) — web-app only
   - Test all interactive elements (buttons, forms, links)
   - Fill forms with valid and invalid data

### Accessibility Audit (web-app and desktop-app only)

A11y is NOT optional. It runs every time.

1. Install if needed: `pnpm add -D @axe-core/playwright`
2. For each page, inject axe-core and run WCAG 2.2 AA checks.
3. Severity mapping:
   - **CRITICAL**: missing interactive element labels, no focus management
   - **HIGH**: color contrast failures, missing alt text on meaningful images
   - **MEDIUM**: heading order violations, missing landmarks
   - **LOW**: best practice suggestions
4. Feed violations back to agent for correction.

## 2. API — Endpoint Testing

1. Discover all routes (read route files, framework-specific).
2. For each endpoint:
   - Test happy path with valid input
   - Test with missing required fields
   - Test with invalid types
   - Test auth (with and without valid credentials)
   - Verify error response format is consistent
   - Check response time (flag >500ms)

## 3. CLI — Command Testing

1. Discover all commands (read command definitions, help output).
2. For each command:
   - Run with `--help`, verify output
   - Run with valid arguments
   - Run with missing required arguments (verify error message)
   - Run with invalid arguments (verify error message and exit code)
   - Test piping (stdin/stdout) if applicable

## 4. Library — API Surface Testing

1. Discover all exports from the package entry point.
2. For each export:
   - Verify type contract matches documentation
   - Test with valid input
   - Test with edge cases (empty, null, undefined, boundary values)
   - Test error behavior (does it throw? Return error? What message?)

## 5. Infrastructure — Dry-Run Verification

1. Run plan/apply in dry-run mode.
2. Verify state matches expected resources.
3. Check for drift between declared and actual state.

## 6. Bug Fix Loop (All App Types)

When bugs are found:

1. Assess severity: CRITICAL > HIGH > MEDIUM > LOW
2. Tier determines fix scope:
   - **Standard tier QA**: fix CRITICAL + HIGH + MEDIUM
   - **Full tier QA**: fix CRITICAL + HIGH + MEDIUM + LOW/cosmetic
3. For each bug:
   - Fix in source code
   - Commit atomically: `git commit -m "fix: description of specific fix"`
   - Re-verify the fix
   - Write regression test if applicable

## 7. Health Score

Produce before and after QA:

```
QA HEALTH SCORE
══════════════════════════════════════
App type:           [type]
Pages/Routes tested: N
Issues found:       N (C critical, H high, M medium, L low)
Issues fixed:       N
A11y violations:    N (web-app only)
A11y fixed:         N

Before: [score]/100
After:  [score]/100

Ship readiness: READY | NEEDS_WORK | NOT_READY
══════════════════════════════════════
```
