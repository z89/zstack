---
name: z:design
description: Brainstorm and produce a formal spec document through Socratic dialogue, approach comparison, and structured design review
argument-hint: [feature or topic to design]
allowed-tools: Bash, Read, Glob, Grep, Write, Edit, Agent
---

# Design

Full-tier only. Produces a formal spec document through structured exploration and dialogue.

## Design Principles

Apply these throughout the entire design process:

- **YAGNI ruthlessly.** Do not design for hypothetical future needs. Solve the stated problem.
- **Design for isolation and clear boundaries.** Each module, component, or service owns its domain. Coupling between units is a design smell.
- **Smaller units with one clear purpose.** If a unit does two things, split it. If the name needs "and" in it, split it.
- **Follow existing codebase patterns.** Match the conventions already in use for naming, structure, error handling, and testing. Consistency beats cleverness.
- **Each unit should be independently testable.** If testing a unit requires spinning up unrelated infrastructure, the boundaries are wrong.

## Phase 1: Context Gathering

Read these sources silently (do not dump them back to the user):
- `CLAUDE.md` and any project-level instructions
- `README.md` or equivalent
- `.zstack/project.json` (app type, framework, language)
- Recent commits (`git log --oneline -20`)
- Top-level file structure (`ls` the root and key directories)

Build a mental model of the project's architecture, conventions, and current state.

## Phase 2: Clarifying Questions

Ask questions one at a time. Socratic style.

Rules:
- Prefer multiple choice over open-ended when possible
- Focus on: purpose, constraints, success criteria, edge cases, non-goals
- Do not ask questions whose answers are already clear from the codebase
- Stop when you have enough to propose approaches (usually 3-6 questions)

For large scopes, suggest decomposition first:

> This touches multiple subsystems. Should we design [X] and [Y] as separate specs, or one unified design?

## Phase 3: Approach Proposals

Present 2-3 approaches. Structure each as:

```
### Approach [N]: [Name]

**How it works:** [2-3 sentences]

**Tradeoffs:**
- Pro: ...
- Pro: ...
- Con: ...

**Best when:** [one sentence on when to pick this]
```

Lead with the recommended approach. State clearly which one you recommend and why.

Wait for user to select or modify an approach before continuing.

## Phase 4: Sectioned Design

Present the design in sections, scaled to complexity. Get user approval after each section before moving to the next.

### Core Sections (always included)

1. **Architecture Overview** — high-level structure, major components, how they connect
2. **Data Flow** — how data moves through the system, key transformations
3. **Error Handling** — failure modes, recovery strategies, user-facing errors
4. **Testing Strategy** — what to test, how, coverage targets

### App-Type Specific Sections

| App Type         | Additional Sections                                    |
|------------------|--------------------------------------------------------|
| `web-app`        | Component tree, routing, state management, a11y        |
| `api`            | Endpoint spec (method, path, request/response shapes)  |
| `cli`            | Command spec (args, flags, subcommands, exit codes)    |
| `library`        | Public API surface, versioning, breaking change policy |
| `desktop-app`    | IPC contract, platform considerations, update flow     |
| `infrastructure` | Resource graph, state management, rollback plan        |

Skip sections that add no value for the given scope. A small feature does not need every section.

## Phase 5: Write Spec

Save the approved design to:

```
docs/plans/YYYY-MM-DD-<topic>-spec.md
```

Create the `docs/plans/` directory if it does not exist.

Spec format:

```markdown
# <Topic> Spec

**Date:** YYYY-MM-DD
**App Type:** <type>
**Tier:** Full

## Overview
[1 paragraph summary]

## Architecture
[from Phase 4]

## Data Flow
[from Phase 4]

## Error Handling
[from Phase 4]

## Testing Strategy
[from Phase 4]

## [App-type specific sections]
[from Phase 4]

## Open Questions
[anything unresolved, flagged for /z:plan to address]
```

## Phase 6: Spec Self-Review

Before presenting the spec to the user, review it for:
- **Placeholders**: any TODO, TBD, or "[fill in]" markers must be resolved or explicitly moved to Open Questions
- **Contradictions**: cross-reference sections for conflicting statements
- **Ambiguity**: any statement that could be interpreted two ways gets clarified
- **Scope creep**: remove anything not required by the original request

Fix issues inline. Do not present a spec with known problems.

## Phase 7: User Review Gate

Present the written spec file path to the user. Ask:

> Spec written to `docs/plans/YYYY-MM-DD-<topic>-spec.md`. Review it and let me know if anything needs changes, or approve to move to planning.

Do not proceed until the user explicitly approves. If they request changes, update the spec file, re-run the self-review, and ask again.

## Phase 8: Transition

Once approved, invoke `/z:plan` with the spec path as input to create the implementation plan.
