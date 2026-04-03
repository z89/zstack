---
name: z:plan
description: Decompose a feature into atomic TDD tasks with architecture review, file mapping, and parallel execution analysis. Produces a complete implementation plan with real code in every step.
---

# z:plan — Task Decomposition

## When to Use

Run `/z:plan` when starting any feature, refactor, or bugfix that touches more than one file. Produces a plan document that `/z:implement` consumes.

Runs on Standard and Full tiers.

### Input

- **Full tier:** `/z:design` produces a spec at `docs/plans/YYYY-MM-DD-<topic>-spec.md` and passes the path to `/z:plan`. Read the spec and extract requirements, architecture decisions, and constraints before starting Phase 1.
- **Standard tier:** No spec exists. Gather requirements from the user's prompt and codebase context directly.

---

## Phase 1: Architecture Review

Before writing any tasks, lock the architecture.

1. **Data flow:** Trace how data enters, transforms, and exits the system. Draw ASCII diagrams when the flow is non-obvious.
2. **Component boundaries:** Define what each module owns. No shared mutable state across boundaries.
3. **API contracts:** Pin function signatures, request/response shapes, event names. These are immutable once the plan is approved.
4. **Edge cases and failure modes:** List them explicitly. Each one becomes a test in a task.
5. **Security concerns:** Auth, injection, secrets, permissions. Flag anything that needs attention.

Adapt the review to the app type (read from `.zstack/project.json`):
- **Web app:** Component tree, state management, data fetching boundaries
- **API:** Endpoint spec, middleware chain, error response format
- **CLI:** Command tree, argument parsing, exit codes
- **Library:** Public API surface, breaking change analysis

---

## Phase 2: File Structure

Map every file before defining tasks.

- List all files to create and all files to modify (with line ranges if modifying)
- One responsibility per file
- Split by responsibility, not by technical layer
- Follow existing codebase patterns for naming, directory structure, and exports

---

## Phase 3: Plan Document

Every plan starts with this header:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies]
**App Type:** [from .zstack/project.json]

---
```

### Task Structure

Each task is a self-contained unit of work, 2-5 minutes to complete.

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing:123-145`
- Test: `tests/exact/path/to/test`

- [ ] **Step 1: Write the failing test**
```language
// actual test code — no placeholders
```

- [ ] **Step 2: Run test to verify it fails**
Run: `exact command`
Expected: FAIL with "specific message"

- [ ] **Step 3: Write minimal implementation**
```language
// actual implementation code — no placeholders
```

- [ ] **Step 4: Run test to verify it passes**
Run: `exact command`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add specific/files
git commit -m "feat: description"
```
````

### Rules for Task Content

- **NO placeholders.** No "TBD", "TODO", "implement later", "similar to Task N", "add appropriate error handling". Every step has actual code.
- **Exact file paths.** Relative to project root.
- **Exact test commands.** With expected output.
- **Complete code.** If a function has 20 lines, write 20 lines. Not "implement the rest similarly".

---

## Phase 4: Parallel Execution Analysis (Full tier only)

After all tasks are defined:

1. List the files each task reads and writes
2. If two tasks write to the same file, they are sequential
3. Group independent tasks for parallel execution
4. Output the grouping:

```
Parallel groups: [1,3,5] [2,4] [6,7] (sequential: 6 before 7)
```

---

## Phase 5: Self-Review

Before finalizing, check:

- **Spec coverage:** Every requirement in the original request maps to at least one task
- **Placeholder scan:** Search the plan for red flag patterns (TBD, TODO, similar, etc.)
- **Type consistency:** Function names, property names, and types match across tasks that reference each other
- **Dependency order:** No task references code that a later task creates

Fix issues inline. Do not list them as notes.

---

## Phase 6: Handoff

1. Save the plan to `docs/plans/YYYY-MM-DD-<feature>-plan.md`
2. Offer execution mode:
   - **Subagent-driven** (recommended for Standard/Full): each task dispatched to a fresh subagent
   - **Inline** (for Quick or simple plans): execute in the current conversation
3. Invoke `/z:implement` to begin execution
