# zstack

A skill system for Claude Code that turns vague feature requests into production-quality, tested, and reviewed code.

zstack orchestrates the full software development lifecycle through 11 composable skills, deterministic quality gates, and a tiered activation model that scales from one-line fixes to greenfield applications. It is app-type-agnostic: the same workflow adapts to web apps, APIs, CLIs, libraries, desktop apps, and infrastructure.

## Motivation

This project draws from two sources:

**[gstack](https://github.com/iamgreggarcia/gstack)** demonstrated that Claude Code skills could be composed into a coherent development pipeline rather than used as isolated prompts. zstack builds on that foundation with tiered activation, baseline-aware quality gates, and parallel subagent execution.

**[Stripe's agent-driven development](https://www.youtube.com/watch?v=gLzJnVCBmKA)** showed how deterministic hooks (lint on save, typecheck before commit) could replace LLM judgment for quality control. zstack adopts this principle directly: quality gates run as shell scripts triggered by Claude Code hooks, not as suggestions the model might or might not follow. The bounded retry pattern (two fix attempts, then escalate) and the baseline awareness model (pre-existing failures never block new work) also originate from Stripe's approach.

## How it works

Every task enters through `/z:build`, which reads the project configuration, classifies the request into a tier, and runs the appropriate pipeline:

| Tier | When | Pipeline |
|------|------|----------|
| **Quick** | Single-file fixes, config changes, styling tweaks | implement &rarr; ship |
| **Standard** | Multi-file features, new components, scoped behavior changes | plan &rarr; implement &rarr; review &rarr; QA &rarr; ship |
| **Full** | New applications, multi-subsystem features, rewrites | design &rarr; plan &rarr; implement &rarr; review &rarr; QA &rarr; secure &rarr; ship |

Tier detection is automatic based on request signals, with manual overrides (`--quick`, `--standard`, `--full`) and confidence gating (asks for confirmation below 70% confidence). If a Quick task starts touching too many files, zstack pauses and suggests upgrading to Standard.

### Quality gates

Quality enforcement is deterministic, not probabilistic. Three layers run as shell hooks:

1. **Instant** (<5s) &mdash; Linter runs on each changed file after every write
2. **Fast** (<30s) &mdash; Typecheck and colocated tests run before every commit
3. **Thorough** &mdash; Full test suite runs before PR creation

All gates are baseline-aware: `zstack-baseline` captures pre-existing lint errors, type errors, and test failures when you set up a project. Gates only block on *new* failures introduced by the current work.

### Checkpoint recovery

State is written to disk at task boundaries. If a session is interrupted, `/z:build` detects the checkpoint and offers to resume from where it left off, including worktree paths, task progress, and plan state.

## Skills

### Entry points &mdash; run these directly

### `/z:create` &mdash; New project scaffold `user-invoked`

Walks through project creation from idea to runnable codebase. Researches current best practices via web search (not stale training data), presents tech stack options with concrete tradeoffs, scaffolds using framework CLIs, and bootstraps quality infrastructure. Decisions are made one at a time, not dumped as a wall of options.

### `/z:setup` &mdash; Project detection `user-invoked`

Auto-detects runtime, framework, app type, package manager, linter, type checker, test runner, and formatter. Writes `.zstack/project.json` so all other skills know how to lint, test, and build the project.

### `/z:build` &mdash; Pipeline router `user-invoked`

Entry point for all work. Reads project configuration, classifies task scope into Quick/Standard/Full, handles checkpoint resume, and orchestrates the selected pipeline. Monitors scope during execution and suggests tier upgrades if the task outgrows its classification.

### `/z:debug` &mdash; Root cause debugging `user-invoked`

Six-phase investigation: reproduce, pattern analysis, hypothesis testing, scope lock, fix, and verification. The iron law is that no fix happens without root cause investigation first. A 3-strike rule escalates to the user if three hypotheses fail (likely an architectural issue). Writes a regression test and produces a structured debug report.

### `/z:review` &mdash; Code review `user-invoked`

Diff-based review across 8 categories: SQL safety, trust boundary violations, conditional side effects, blast radius, error handling, performance, accessibility, and app-type-specific checks. Findings are severity-ranked (Critical/High/Medium/Low) with a deterministic verdict: any Critical or 3+ High findings fail the review. Offers to auto-fix Critical and High issues.

### `/z:secure` &mdash; Security audit `user-invoked`

Multi-phase analysis from attack surface census through OWASP Top 10 mapping and STRIDE threat modeling. Phases include secrets archaeology (scanning git history for credential patterns), dependency supply chain audit, CI/CD security review, and code-level analysis for injection, auth, and data exposure. Confidence gating adjusts sensitivity: daily mode surfaces only high-confidence findings, comprehensive mode catches anything plausible. Accepts flags for focused scans (`--deps`, `--secrets`, `--owasp`, `--diff`).

---

### Pipeline phases &mdash; executed automatically by `/z:build`

### `/z:design` &mdash; Specification authoring `automatic` `Full only`

Produces a formal spec through Socratic dialogue. Asks 3-6 clarifying questions (one at a time), presents 2-3 architectural approaches with tradeoffs, then writes a sectioned design document covering architecture, data flow, error handling, and testing strategy. App-type-specific sections are included (component trees for web apps, endpoint specs for APIs, command specs for CLIs). Requires explicit user approval before proceeding to planning.

### `/z:plan` &mdash; Task decomposition `automatic` `Standard + Full`

Decomposes a feature into atomic tasks, each 2-5 minutes of work, with a strict no-placeholder policy. Every task includes actual code (not skeletons), exact file paths, exact test commands, and a TDD sequence: write failing test, verify it fails, write implementation, verify it passes, commit. For Full tier, identifies which tasks can execute in parallel. Self-review scans for red flags like TODO, TBD, or "implement the rest similarly."

### `/z:implement` &mdash; TDD execution engine `automatic` `all tiers`

Executes the plan. Behavior varies by tier:

- **Quick**: Inline implementation, no subagents, flexible test ordering
- **Standard**: Sequential subagents (one per task), two-stage review (spec compliance + code quality), bounded retry
- **Full**: Parallel subagents (up to 5 in isolated git worktrees), strict TDD (RED &rarr; GREEN &rarr; REFACTOR), baseline-aware quality gates

Each subagent receives a focused prompt with its task, the TDD policy, and the scope lock. After completion, a spec reviewer checks that the implementation matches the plan exactly, and a code quality reviewer checks for clean code, security, and codebase consistency. Two fix attempts are allowed on failure before escalation.

### `/z:review` &mdash; Code review `automatic` `Standard + Full`

Also available as a standalone entry point (see above). When run inside a pipeline, reviews the full diff produced by `/z:implement`.

### `/z:qa` &mdash; QA testing `automatic` `Standard + Full`

Adapts to app type:

- **Web apps / Desktop**: Playwright visual testing, axe-core accessibility (WCAG 2.2 AA), responsive checks at mobile/tablet/desktop breakpoints
- **APIs**: Endpoint testing across all routes, error responses, auth, rate limiting, input validation
- **CLIs**: Command testing with flags, help text, error messages, exit codes
- **Libraries**: API surface testing for all exports, type contracts, edge cases

Produces a health score (pages tested, issues found/fixed, a11y violations) and a ship readiness verdict. Fixes bugs in a loop based on severity.

### `/z:secure` &mdash; Security audit `automatic` `Full only`

Also available as a standalone entry point (see above). When run inside a pipeline, audits the full changeset before shipping.

### `/z:ship` &mdash; Shipping pipeline `automatic` `all tiers`

- **Quick**: Commit only
- **Standard**: Create PR with structured description, monitor CI, bounded retry on failures (read logs, fix, retry up to 2 times)
- **Full**: PR + CI monitoring + post-deploy verification (health check, Playwright smoke test for web apps)

Warns if review, QA, or security phases were skipped. Cleans up checkpoints and lists worktrees for removal.

## Getting started

### 1. Install zstack

```bash
git clone https://github.com/z89/zstack.git
cd zstack
./install.sh
```

### 2. Set up your project

Open Claude Code in your project directory and run:

```
/z:setup
```

This detects your runtime, framework, linter, test runner, and package manager, then writes `.zstack/project.json`. All other skills read this file to know how to work with your project.

A baseline capture runs automatically at the start of every pipeline (regardless of tier), so quality gates always know which failures existed before your work began. No manual step needed.

### 3. Add a feature

The Standard tier is the most common workflow. Here is exactly what happens when you ask zstack to add a feature to an existing project.

Start by telling `/z:build` what you want:

```
/z:build Add a dark mode toggle to the settings page
```

zstack classifies this as a multi-file feature and activates the Standard pipeline. Five phases run in sequence:

**Plan** &mdash; `/z:plan` reads your codebase, locks down the architecture (which components change, what the data flow looks like, where the tests go), and writes a plan to `docs/plans/`. Each task in the plan is 2-5 minutes of work with exact file paths, real code (not skeletons), and a TDD sequence: write failing test, verify it fails, write implementation, verify it passes, commit. You review and approve the plan before anything gets built.

**Implement** &mdash; `/z:implement` executes the plan task by task. For Standard tier, each task runs in a subagent that receives the task spec and a scope lock (it can only touch the files listed in its task). After each task, two reviewers check the work: a spec reviewer confirms the implementation matches the plan exactly, and a code quality reviewer checks for clean code, security, and consistency with your codebase. If a task fails, two fix attempts are allowed before escalating to you.

Quality gates run automatically throughout: the linter fires after every file write, and typecheck + colocated tests run before every commit. These are shell hooks, not LLM suggestions, so they always run.

**Review** &mdash; `/z:review` diffs all changes against the base branch and reviews across 8 categories (SQL safety, trust boundaries, error handling, performance, accessibility, and more). Findings are ranked by severity. Critical and High issues get auto-fix offers.

**QA** &mdash; `/z:qa` runs app-type-appropriate tests. For a web app, that means Playwright visual testing, axe-core accessibility checks (WCAG 2.2 AA), and responsive testing at mobile, tablet, and desktop breakpoints. Bugs found are fixed in a loop based on severity. A health score is produced at the end.

**Ship** &mdash; `/z:ship` creates a PR with a structured description, monitors CI, and retries failures (reads logs, fixes the issue, re-pushes, up to two attempts). If you skipped any phases, the PR description notes what was skipped.

The entire pipeline runs from a single command. You approve the plan, review the PR, and merge.

### 4. Other entry points

You do not have to go through `/z:build` for everything. Skills can be invoked directly:

```
/z:build              # Auto-detect scope and run the appropriate pipeline
/z:build --full       # Force Full tier (adds design + security phases)
/z:build --quick      # Force Quick tier (implement + ship only)
/z:create             # Start a new project from scratch
/z:debug              # Investigate a bug with structured root cause analysis
/z:review             # Run a standalone code review on your current diff
/z:secure --deps      # Run a dependency audit only
/z:secure --secrets   # Scan git history for leaked credentials
```

Any phase can be skipped with flags on `/z:build`:

```
/z:build --skip-qa --skip-secure
```

Ship will note what was skipped so you can make an informed merge decision.

## Project structure

```
skills/
  build/        Pipeline router and tier activation
  create/       New project scaffolding
  setup/        Project detection and configuration
  design/       Specification authoring (Full tier)
  plan/         Task decomposition with TDD structure
  implement/    Execution engine with subagent prompts
  review/       Diff-based code review
  debug/        Root cause investigation
  qa/           App-type-adapted testing
  secure/       Multi-phase security audit
  ship/         PR creation, CI monitoring, deploy verification
bin/
  zstack-setup          Project detection script
  zstack-baseline       Pre-existing failure capture
  zstack-quality-gate   Pre-commit hook (lint + typecheck + colocated tests)
  zstack-checkpoint     Session state persistence
lib/
  detect-scope.md       Tier classification heuristics
  quality-gates.md      Gate architecture documentation
  tdd-anti-patterns.md  Test quality reference
settings/
  hooks.json            Claude Code hook configuration
```

## License

MIT
