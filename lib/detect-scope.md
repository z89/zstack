# Scope Detection Heuristics

Reference doc for `/z:build` scope auto-detection.

## Signal Analysis

Parse the user's prompt and check for these signals:

### Quick Tier Signals (high confidence if 2+ match)
- Mentions a single file or component by name
- Words: "fix", "tweak", "change", "update", "rename", "typo"
- Describes a visual/styling change: "color", "font", "padding", "margin", "alignment"
- Config change: "env", "config", "setting", "flag", "toggle"
- One-liner description: the entire request fits in one sentence
- No mention of new functionality or behavior change

### Standard Tier Signals (high confidence if 2+ match)
- Mentions a feature or component to build/add
- Words: "add", "create", "implement", "component", "feature", "endpoint"
- Implies multiple files: "and also", "along with", "including"
- Mentions testing: "with tests", "test coverage"
- Describes new behavior: "when the user clicks X, Y should happen"
- Scoped to one area of the app: "in the auth module", "on the settings page"

### Full Tier Signals (high confidence if 2+ match)
- Mentions building something new: "build", "new app", "from scratch"
- Describes multiple subsystems: "auth, billing, and notifications"
- Words: "redesign", "rewrite", "overhaul", "architecture", "system"
- Implies design decisions: "what's the best approach", "how should we"
- Production/deployment language: "ship to production", "deploy"
- Security/performance requirements mentioned
- Multiple user roles or permission levels described

## Confidence Scoring

Count matching signals for each tier. The tier with the most matches wins.

- 3+ signals for one tier → high confidence (proceed)
- 2 signals → medium confidence (proceed but note uncertainty)
- 1 signal or tie → low confidence (ask the user)

If low confidence:
"This could be a [tier1] or [tier2] task. A few questions:
- How many files do you expect this to touch?
- Is this modifying existing behavior or adding new functionality?
- Does this need design discussion first?"

## Override Signals

These always override auto-detection:
- `--quick` flag → Quick tier
- `--standard` flag → Standard tier
- `--full` flag → Full tier
- User explicitly says "just a quick fix" → Quick
- User explicitly says "this is a big feature" → Full

## Escalation Triggers (during implementation)

Monitor file count during `/z:implement`:

| Started as | Trigger | Action |
|------------|---------|--------|
| Quick | >5 files touched | Pause: "This grew beyond a quick fix. Upgrade to Standard?" |
| Standard | >15 files touched | Pause: "This is larger than expected. Upgrade to Full?" |

On upgrade:
1. Stash current changes
2. Create worktree (if not already in one)
3. Apply stash in worktree
4. Activate higher tier pipeline
5. If upgrading to Full from Quick/Standard, suggest running /z:plan first
