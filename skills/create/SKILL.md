---
name: z:create
description: Create a new project from scratch — researches tech stacks, recommends architecture, scaffolds with framework CLIs, and bootstraps quality infrastructure
---

# Create Project

Walk the user through creating a new project from idea to scaffolded, runnable codebase. Researches best practices, recommends stacks, makes design decisions collaboratively, then scaffolds everything.

## Phase 1: Understand the Project

Ask these questions **one at a time**. Adapt follow-ups based on answers.

### 1.1 What are you building?

Get a clear picture of the project:
- What does it do? (one sentence)
- Who is it for? (target users)
- What problem does it solve?

### 1.2 Classify the app type

Based on the description, classify and confirm with the user:

| Type | Signals |
|------|---------|
| `web-app` | Users interact through a browser, has pages/routes/UI |
| `api` | Serves data to other apps, no direct UI |
| `cli` | Command-line tool, terminal interaction |
| `library` | Reusable package consumed by other projects |
| `desktop-app` | Native desktop application (Electron, Tauri) |
| `mobile-app` | iOS/Android application |
| `fullstack` | Web app with its own API backend |
| `infrastructure` | IaC, platform tooling, DevOps automation |

"Based on your description, this sounds like a **[type]**. Correct?"

### 1.3 Scale and constraints

Ask about scope to calibrate recommendations:
- Is this a side project, MVP, or production system?
- Expected user count? (tens, thousands, millions)
- Solo developer or team?
- Any hard constraints? (must use specific language, specific cloud, specific database, budget, timeline)
- Any existing systems this needs to integrate with?

---

## Phase 2: Research and Recommend Tech Stack

This is the core differentiator of `/z:create`. Do not skip or rush this phase.

### 2.1 Research current best practices

Use WebSearch to research the current landscape for the app type:

**Search queries (adapt to app type):**
- `"best [app-type] stack 2025 2026 production"`
- `"[app-type] framework comparison [current year]"`
- `"[app-type] architecture best practices [current year]"`
- `"[specific-requirement] [app-type] recommended stack"`

For each major decision (framework, database, auth, hosting), gather:
- What the industry is converging on
- What's battle-tested vs cutting-edge
- Known tradeoffs and pitfalls
- What companies at the user's scale are using

### 2.2 Present 2-3 stack options

For each technology decision, present options with tradeoffs. Format:

```
## [Decision: e.g., "Framework"]

A) [Option 1] — [one-line summary]
   Pros: [concrete benefits]
   Cons: [concrete drawbacks]
   Best for: [when to pick this]
   Used by: [notable companies/projects]

B) [Option 2] — [one-line summary]
   Pros: ...
   Cons: ...
   Best for: ...
   Used by: ...

C) [Option 3] — [one-line summary] (if applicable)
   ...

RECOMMENDATION: [which and why, based on the user's specific constraints]
```

### 2.3 Technology decisions to cover

Adapt this list to the app type. Not all apply to every project.

**All app types:**
- Language / runtime
- Package manager
- Linter + formatter
- Test framework
- CI/CD platform

**Web apps / fullstack:**
- Frontend framework (React/Next.js, Svelte/SvelteKit, Vue/Nuxt, etc.)
- Styling approach (Tailwind, CSS Modules, Styled Components, etc.)
- Component library / design system
- State management (if needed)
- API layer (REST, GraphQL, tRPC, etc.)
- Backend framework (if fullstack)
- Database + ORM
- Auth provider
- Hosting / deployment platform
- Analytics / monitoring

**APIs:**
- Framework (Express, Fastify, Hono, Gin, FastAPI, etc.)
- Database + ORM
- Auth strategy (JWT, OAuth, API keys)
- API documentation (OpenAPI, etc.)
- Rate limiting approach
- Hosting platform

**CLIs:**
- Argument parser (Commander, clap, cobra, etc.)
- Output formatting (chalk, colored, etc.)
- Config file format
- Distribution strategy (npm, homebrew, cargo, binary releases)

**Libraries:**
- Build tool (tsup, esbuild, Rollup, etc.)
- Documentation generator
- Publishing registry (npm, PyPI, crates.io, etc.)
- Versioning strategy (semver, calver)

**Desktop apps:**
- Framework (Electron, Tauri, etc.)
- IPC architecture
- Auto-update strategy
- Distribution / signing

**Mobile apps:**
- Framework (React Native, Flutter, Swift/Kotlin native, etc.)
- Navigation library
- State management
- Push notification service
- App store requirements

### 2.4 Get user approval on each decision

Present each decision, get approval, move to the next. Don't dump all decisions at once.

After all decisions are made, summarize the complete stack:

```
## Final Stack

[App Name] — [app type]

| Layer | Choice | Why |
|-------|--------|-----|
| Runtime | Node.js 22 | LTS, largest ecosystem for web |
| Framework | Next.js 15 | App router, RSC, Vercel deploy |
| Styling | Tailwind CSS 4 | Utility-first, design system ready |
| Components | shadcn/ui | Composable, accessible, customizable |
| Database | PostgreSQL + Drizzle | Type-safe ORM, SQL-first |
| Auth | Clerk | Drop-in, handles edge cases |
| Testing | Vitest + Playwright | Fast unit tests + real browser e2e |
| Linter | ESLint + Prettier | Industry standard |
| CI/CD | GitHub Actions | Free tier, native integration |
| Deploy | Vercel | Zero-config Next.js deploy |

Confirm this stack?
```

---

## Phase 3: Architecture Design

### 3.1 Project structure

Design the directory layout based on the chosen stack. Follow the framework's conventions, then layer on project-specific organization.

Present the structure:
```
project-name/
├── src/
│   ├── app/              # Routes / pages
│   ├── components/       # Shared UI components
│   │   ├── ui/           # Base design system components
│   │   └── features/     # Feature-specific components
│   ├── lib/              # Shared utilities and helpers
│   ├── server/           # Server-side code (API routes, actions)
│   │   ├── db/           # Database schema, migrations, queries
│   │   └── services/     # Business logic
│   └── types/            # Shared TypeScript types
├── tests/                # Test files mirroring src/ structure
├── public/               # Static assets
├── docs/                 # Project documentation
│   └── plans/            # zstack plan documents
└── [config files]
```

Adapt to the app type and framework. Ask: "Does this structure work for your project?"

### 3.2 Key architectural decisions

Based on the app type, discuss and document:

- **Data model**: what are the core entities and relationships?
- **API design**: what endpoints/routes exist? What data do they serve?
- **Auth flow**: who can access what? What roles exist?
- **Error handling strategy**: how are errors surfaced to users?
- **Environment management**: what env vars are needed? How are secrets managed?

Keep this high-level. Details are for `/z:design` and `/z:plan` later.

---

## Phase 4: Scaffold

### 4.1 Create the project

Use the framework's official CLI to scaffold:

| Framework | Command |
|-----------|---------|
| Next.js | `pnpm create next-app@latest <name> --ts --tailwind --eslint --app --src-dir` |
| SvelteKit | `pnpm create svelte@latest <name>` |
| Nuxt | `pnpm dlx nuxi init <name>` |
| Express | `mkdir <name> && cd <name> && pnpm init` |
| Fastify | `pnpm dlx fastify-cli generate <name> --lang=ts` |
| Go | `mkdir <name> && cd <name> && go mod init <module>` |
| Rust | `cargo init <name>` |
| Python | `mkdir <name> && cd <name> && uv init` |

After scaffold, `cd` into the project directory.

### 4.2 Install additional dependencies

Based on the stack decisions from Phase 2, install the chosen tools:
- Component library
- ORM / database driver
- Auth library
- Test framework
- Any other dependencies the user chose

### 4.3 Configure tooling

Set up configuration files for the chosen tools:
- Linter config (eslint, biome, ruff, etc.)
- Formatter config (prettier, biome, etc.)
- Test config (vitest, jest, pytest, etc.)
- TypeScript config adjustments (if applicable)
- Environment file template (`.env.example` with documented variables)

### 4.4 Create directory structure

Create the directories designed in Phase 3 that the scaffold didn't create.

---

## Phase 5: Quality Infrastructure

### 5.1 Ask before installing

Present what zstack wants to set up:

```
zstack quality infrastructure:

- [linter]: [config file] with [ruleset]
- [formatter]: [config file]
- [test runner]: [config file] with [N] example tests
- [type checker]: [config]
- .zstack/project.json (zstack project detection)
- .gitignore (with .zstack/, node_modules/, etc.)

Install all of these? Or pick individually?
```

### 5.2 Run zstack-setup

After setup, run project detection:
```bash
ZSTACK_DIR=$(dirname $(dirname $(readlink -f ~/.claude/skills/z:build))) && bash "$ZSTACK_DIR/bin/zstack-setup"
```

### 5.3 Capture baseline

```bash
ZSTACK_DIR=$(dirname $(dirname $(readlink -f ~/.claude/skills/z:build))) && bash "$ZSTACK_DIR/bin/zstack-baseline"
```

---

## Phase 6: Git & Remote

### 6.1 Initialize git

```bash
git init
git add -A
git commit -m "feat: initial project scaffold"
```

### 6.2 Ask about GitHub

"Want me to create a GitHub repository for this project?"

If yes:
- Ask: public or private?
- Create: `gh repo create <name> --private --source=. --push` (or `--public`)
- Confirm: "Repository created at https://github.com/<user>/<name>"

If no: skip. The local repo is ready.

---

## Phase 7: Documentation

### 7.1 Ask about documentation level

"What level of documentation do you want?"

- A) **Full**: README + CLAUDE.md + CONTRIBUTING.md
- B) **Standard**: README + CLAUDE.md
- C) **Minimal**: README only
- D) **None**: skip docs for now

### 7.2 Generate chosen docs

**README.md:**
- Project name and one-line description
- Tech stack summary table
- Setup instructions (clone, install, run)
- Environment variables reference
- Available scripts (dev, build, test, lint)

**CLAUDE.md (if chosen):**
- Project overview for AI context
- Directory structure explanation
- Key commands (build, test, lint, dev server)
- Architecture notes from Phase 3
- Stack decisions and rationale

**CONTRIBUTING.md (if chosen):**
- Setup instructions
- Development workflow
- Code style guidelines (linked to linter config)
- Testing requirements
- PR process

---

## Phase 8: Summary & Next Steps

Present the completed project:

```
PROJECT CREATED
══════════════════════════════════════
Name:        [name]
Type:        [app type]
Stack:       [key technologies]
Location:    [path]
Git:         [initialized | pushed to github.com/user/name]
Docs:        [README | README + CLAUDE.md | ...]

Quality gates:
  Linter:    [name] ✓
  Types:     [name] ✓
  Tests:     [name] ✓
  Baseline:  captured ✓

Next steps:
  1. cd [path]
  2. [start dev server command]
  3. Start building with /z:build
══════════════════════════════════════
```

---

## Principles

- **Research before recommending.** Every stack suggestion should be backed by current best practices, not stale training data. Use WebSearch.
- **One question at a time.** Don't overwhelm with 10 decisions at once. Walk through them sequentially.
- **Explain tradeoffs concretely.** Not "X is faster" but "X handles 10K concurrent connections on a single core, Y needs a worker pool for the same load."
- **Respect constraints.** If the user says "must use Python," don't recommend Node.js.
- **Framework CLIs first.** Use official scaffolding tools. They encode the framework team's best practices. Customize after.
- **No premature architecture.** Project structure and tooling, not business logic. Features come later via `/z:build`.
