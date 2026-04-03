#!/usr/bin/env bash
set -euo pipefail

ZSTACK_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS_SRC="$ZSTACK_DIR/settings/hooks.json"
SKILL_PREFIX="z:"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[zstack]${NC} $1"; }
warn()  { echo -e "${YELLOW}[zstack]${NC} $1"; }
error() { echo -e "${RED}[zstack]${NC} $1"; }

# ── Check for conflicting installations ──────────────────────────────────────

check_conflicts() {
  local conflicts=()

  if [ -d "$HOME/.claude/skills/gstack" ]; then
    conflicts+=("gstack ($HOME/.claude/skills/gstack)")
  fi

  # Check for superpowers plugin
  if [ -d "$HOME/.claude/plugins/cache/claude-plugins-official/superpowers" ]; then
    conflicts+=("superpowers (Claude Code plugin)")
  fi

  if [ ${#conflicts[@]} -gt 0 ]; then
    warn "Detected existing skill systems that may conflict with zstack:"
    for c in "${conflicts[@]}"; do
      echo "  - $c"
    done
    echo ""
    warn "zstack replaces both gstack and superpowers."
    warn "Having multiple active skill systems causes:"
    warn "  - Duplicate/conflicting skill triggers"
    warn "  - Context window bloat from multiple skill definitions"
    warn "  - Ambiguous routing (agent doesn't know which debug skill to use)"
    echo ""
    read -rp "Continue anyway? (y/N) " confirm
    if [[ "$confirm" != [yY] ]]; then
      error "Aborted. Remove conflicting systems first, then re-run install."
      exit 1
    fi
  fi
}

# ── Symlink skills ───────────────────────────────────────────────────────────

install_skills() {
  mkdir -p "$SKILLS_DIR"

  # Remove old-style single symlink if it exists
  if [ -L "$SKILLS_DIR/zstack" ]; then
    rm "$SKILLS_DIR/zstack"
    info "Removed old-style zstack symlink."
  fi

  local installed=0
  local skipped=0

  for skill_dir in "$ZSTACK_DIR/skills"/*/; do
    local skill_name
    skill_name=$(basename "$skill_dir")
    local link_name="${SKILL_PREFIX}${skill_name}"
    local link_path="$SKILLS_DIR/$link_name"

    if [ -L "$link_path" ]; then
      local existing
      existing=$(readlink "$link_path")
      if [ "$existing" = "$skill_dir" ]; then
        skipped=$((skipped + 1))
        continue
      fi
      # Different target, replace
      rm "$link_path"
    fi

    ln -s "$skill_dir" "$link_path"
    installed=$((installed + 1))
  done

  if [ "$installed" -gt 0 ]; then
    info "Linked $installed skills to $SKILLS_DIR/${SKILL_PREFIX}*"
  fi
  if [ "$skipped" -gt 0 ]; then
    info "$skipped skills already linked. Skipped."
  fi
}

# ── Install hooks ────────────────────────────────────────────────────────────

install_hooks() {
  local settings_dir="$HOME/.claude"
  local settings_file="$settings_dir/settings.json"

  if [ ! -f "$SETTINGS_SRC" ]; then
    warn "No hooks.json found. Skipping hook installation."
    return
  fi

  mkdir -p "$settings_dir"

  if [ -f "$settings_file" ]; then
    # Check if hooks already configured
    if grep -q "zstack" "$settings_file" 2>/dev/null; then
      info "Hooks already configured. Skipping."
      return
    fi

    # Backup existing settings
    local backup="$settings_file.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$settings_file" "$backup"
    info "Backed up existing settings to: $backup"

    # Merge zstack hooks into existing settings
    if command -v jq &>/dev/null; then
      # jq available: proper JSON merge
      local merged
      merged=$(jq -s '
        # Start with existing settings
        .[0] as $existing |
        .[1] as $zstack |
        # Deep merge: preserve everything in existing, add zstack hooks
        $existing * {
          hooks: (
            ($existing.hooks // {}) as $eh |
            ($zstack.hooks // {}) as $zh |
            # For each hook type in zstack, append entries to existing array
            reduce ($zh | keys[]) as $key (
              $eh;
              . + { ($key): ((.[$key] // []) + $zh[$key]) }
            )
          )
        }
      ' "$settings_file" "$SETTINGS_SRC" 2>/dev/null)

      if [ $? -eq 0 ] && [ -n "$merged" ]; then
        echo "$merged" > "$settings_file"
        info "Hooks merged into existing settings.json"
      else
        error "Failed to merge hooks. Your backup is at: $backup"
        error "Merge manually from: $SETTINGS_SRC"
      fi
    else
      # No jq: fall back to python for JSON merge
      if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$settings_file') as f: existing = json.load(f)
with open('$SETTINGS_SRC') as f: zstack = json.load(f)
hooks = existing.get('hooks', {})
for key, entries in zstack.get('hooks', {}).items():
    hooks[key] = hooks.get(key, []) + entries
existing['hooks'] = hooks
with open('$settings_file', 'w') as f: json.dump(existing, f, indent=2)
" 2>/dev/null
        if [ $? -eq 0 ]; then
          info "Hooks merged into existing settings.json"
        else
          error "Failed to merge hooks. Your backup is at: $backup"
          error "Merge manually from: $SETTINGS_SRC"
        fi
      else
        warn "Neither jq nor python3 found. Cannot auto-merge."
        warn "Your backup is at: $backup"
        warn "Merge manually: add the hooks from $SETTINGS_SRC into $settings_file"
      fi
    fi
  else
    cp "$SETTINGS_SRC" "$settings_file"
    info "Hooks installed to $settings_file"
  fi
}

# ── Install bin scripts ──────────────────────────────────────────────────────

install_bin() {
  chmod +x "$ZSTACK_DIR/bin/"* 2>/dev/null || true
  info "Bin scripts ready at $ZSTACK_DIR/bin/"
}

# ── Detect project environment (run in a project directory) ──────────────────

detect_project() {
  info ""
  info "To set up zstack for a specific project, run from that project's root:"
  info "  zstack-setup"
  info ""
  info "This will detect your linter, test runner, and type checker"
  info "and write the config to .zstack/project.json"
}

# ── Package manager warning ──────────────────────────────────────────────────

check_package_manager() {
  # Check if pnpm is available
  if ! command -v pnpm &>/dev/null; then
    warn "pnpm not detected."
    warn "zstack's worktree isolation works best with pnpm because its"
    warn "content-addressable store shares dependencies across worktrees."
    warn "With npm/yarn, each worktree runs a full install (~800MB+ per worktree)."
    warn "With 5 parallel agents on Full tier, that's 4GB+ of node_modules."
    warn ""
    warn "Install pnpm: https://pnpm.io/installation"
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo ""
  echo "  ╔══════════════════════════════╗"
  echo "  ║  zstack installer            ║"
  echo "  ║  Code quality skill system   ║"
  echo "  ╚══════════════════════════════╝"
  echo ""

  check_conflicts
  install_skills
  install_hooks
  install_bin
  check_package_manager
  detect_project

  echo ""
  info "Installation complete."
  info ""
  info "Available commands (use in Claude Code):"
  info "  /z:build    - Start here. Routes to the right pipeline."
  info "  /z:design   - Brainstorm and spec (Full tier)"
  info "  /z:plan     - Task decomposition (Standard + Full)"
  info "  /z:implement - TDD implementation with subagents"
  info "  /z:review   - Diff-based code review"
  info "  /z:debug    - Root cause debugging"
  info "  /z:qa       - Visual QA + accessibility audit"
  info "  /z:secure   - Security audit"
  info "  /z:ship     - PR, CI, merge, deploy"
  echo ""
}

main "$@"
