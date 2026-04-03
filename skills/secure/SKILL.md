---
name: z:secure
description: Security audit skill — multi-phase security analysis adapted to app type, with confidence gating and false positive suppression
---

# Security Audit

Multi-phase security analysis. Runs automatically on Full tier, available on-demand for all tiers.

## Arguments

- `/z:secure` — full daily audit (8/10 confidence gate)
- `/z:secure --comprehensive` — monthly deep scan (2/10 bar)
- `/z:secure --diff` — branch changes only (combinable with any flag)
- `/z:secure --deps` — dependency audit only
- `/z:secure --owasp` — OWASP Top 10 only
- `/z:secure --secrets` — secrets scan only

## Phase 0: Architecture Mental Model + Stack Detection

- Read `.zstack/project.json` for `type`, `language`, `framework`, `runtime`.
- Read CLAUDE.md, README, key config files.
- Map application architecture: components, connections, trust boundaries.
- Identify data flow: where does user input enter? Exit? What transformations?
- This is a reasoning phase. Output is understanding, not findings.

## Phase 1: Attack Surface Census

Using Grep tool (not bash grep), find:

- Public endpoints (unauthenticated)
- Authenticated endpoints
- Admin endpoints
- File upload points
- External integrations
- Webhook handlers
- Background jobs
- WebSocket channels (web-app)
- CLI subcommands (cli)

Output: Attack Surface Map with counts for each category.

## Phase 2: Secrets Archaeology

- Git history scan for leaked credentials: `AKIA`, `sk-`, `ghp_`, `gho_`, `xoxb-`, `xoxp-`
- `.env` files tracked by git (not `.example`/`.sample`/`.template`)
- CI configs with inline secrets (not using secret stores)
- Severity: CRITICAL for active secret patterns in git. HIGH for `.env` tracked.
- FP rules: placeholders excluded, test fixtures excluded, `.env.local` in `.gitignore` is expected.

## Phase 3: Dependency Supply Chain

- Run the package manager's audit tool (`npm audit`, `pip audit`, `cargo audit`, etc.)
- Check for install scripts in production deps (supply chain vector)
- Check lockfile exists and is tracked
- Severity: CRITICAL for known CVEs in direct deps. HIGH for missing lockfile.
- FP rules: devDependency CVEs are MEDIUM max. `node-gyp` install scripts expected.

## Phase 4: CI/CD Pipeline Security

- Unpinned third-party actions (not SHA-pinned)
- `pull_request_target` (dangerous: fork PRs get write access)
- Script injection via `${{ github.event.* }}` in run steps
- Secrets as env vars (could leak in logs)
- CODEOWNERS on workflow files

## Phase 5: Infrastructure Shadow Surface

- Dockerfiles: missing `USER` (runs as root), secrets as `ARG`, `.env` copied in
- Config files with prod credentials (`postgres://`, `mysql://`, `mongodb://`, `redis://`)
- IaC: `"*"` in IAM actions, hardcoded secrets in `.tf`/`.tfvars`
- K8s: privileged containers, `hostNetwork`, `hostPID`

## Phase 6-8: Code-Level Security (Adapted to App Type)

Scan for:

- Input validation at all entry points
- Output encoding (XSS prevention for web-app)
- Authentication/authorization checks
- SQL injection / NoSQL injection
- Command injection
- Path traversal
- SSRF
- Insecure deserialization
- Logging sensitive data

## Phase 9: OWASP Top 10 Mapping

Map all findings to OWASP Top 10 2021 categories:

1. A01 Broken Access Control
2. A02 Cryptographic Failures
3. A03 Injection
4. A04 Insecure Design
5. A05 Security Misconfiguration
6. A06 Vulnerable and Outdated Components
7. A07 Identification and Authentication Failures
8. A08 Software and Data Integrity Failures
9. A09 Security Logging and Monitoring Failures
10. A10 Server-Side Request Forgery

## Phase 10: STRIDE Threat Model

For each component identified in Phase 0:

- **S**poofing — can an attacker impersonate a user or component?
- **T**ampering — can data be modified in transit or at rest?
- **R**epudiation — can actions be denied without evidence?
- **I**nformation Disclosure — can sensitive data leak?
- **D**enial of Service — can the service be overwhelmed?
- **E**levation of Privilege — can a user gain unauthorized access?

## Confidence Gating

- **Daily mode** (default): only report findings with 8/10+ confidence.
- **Comprehensive mode**: report findings with 2/10+ confidence (surfaces more, noisier).
- Each finding includes a confidence score and concrete exploit scenario.

## False Positive Rules

These are critical for preventing alert fatigue:

- Placeholders (`"your_"`, `"changeme"`, `"TODO"`) excluded from secrets
- Test fixtures excluded unless same value appears in non-test code
- devDependency CVEs are MEDIUM max
- `node-gyp`/`cmake` install scripts expected (MEDIUM not HIGH)
- `.env.local` in `.gitignore` is expected
- First-party actions unpinned = MEDIUM not HIGH

## Report Format

```
SECURITY POSTURE REPORT
══════════════════════════════════════
App type:    [type]
Mode:        [daily | comprehensive]
Scope:       [full | diff | deps | owasp | secrets]

ATTACK SURFACE: [N] entry points
FINDINGS: [N] total
  CRITICAL: [N]
  HIGH:     [N]
  MEDIUM:   [N]

[For each finding:]
[SEVERITY] [confidence/10] — Title
  Location: file:line
  What: [description]
  Exploit: [concrete exploit scenario]
  Fix: [remediation steps]
  OWASP: [category]

VERDICT: SECURE | NEEDS_REMEDIATION | CRITICAL_RISK
══════════════════════════════════════
```
