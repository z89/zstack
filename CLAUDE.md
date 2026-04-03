# zstack — Development Guide

## What this is

zstack is a Claude Code skill system for building production-quality applications.
9 skills, app-type-agnostic, with deterministic quality gates.

All commands are namespaced: `/z:build`, `/z:plan`, `/z:implement`, etc.

## Project structure

```
skills/          — Skill markdown files (symlinked to ~/.claude/skills/zstack/)
  build/         — Router: scope detection + tier activation
  design/        — Brainstorming + spec (Full tier)
  plan/          — Task decomposition (Standard + Full)
  implement/     — TDD + subagent dispatch + quality gates
  review/        — Diff-based code review
  debug/         — Root cause debugging
  qa/            — Visual QA + a11y + app-type-specific testing
  secure/        — Security audit (14-phase)
  ship/          — PR + CI + merge + deploy
bin/             — Shell scripts (quality gates, detection, checkpoints)
lib/             — Reference docs loaded by skills on demand
settings/        — Claude Code hooks configuration
```

## Architecture principles

1. **Tiered activation**: Quick (minimal overhead) → Standard (plan + review) → Full (design through deploy)
2. **Deterministic gates**: Lint/typecheck/tests run via hooks, not LLM decisions
3. **Progressive loading**: Only the active skill consumes context
4. **App-type-agnostic**: Auto-detects web-app, API, CLI, library, desktop-app, infrastructure
5. **Bounded retry**: Max 2 fix attempts on failures, then escalate
6. **Baseline awareness**: Pre-existing failures don't block new work
7. **Checkpoint/recovery**: State written to disk at task boundaries

## Testing changes to skills

After editing a skill:
1. Create a test project with the relevant app type
2. Run the skill against it
3. Verify the methodology flows correctly
4. Check that hooks fire as expected

## Commit style

Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
