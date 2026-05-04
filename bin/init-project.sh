#!/usr/bin/env bash
# agent-core: bootstrap a project's Claude harness
#
# Sets up:
#   <project>/.claude/settings.local.json    (with detected-stack hints)
#   ~/.claude/projects/<encoded>/memory/     (with seeded MEMORY.md)
#
# Usage:
#   init-project.sh [<project-path>]   # defaults to $PWD
#   init-project.sh --dry-run [<path>]
#   init-project.sh --force   [<path>] # overwrite existing files
#   init-project.sh --help

set -euo pipefail

CLAUDE_CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
FORCE=0
TARGET=""

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's|^# \?||'
  exit 0
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    --help|-h) usage ;;
    -*)        echo "unknown flag: $arg" >&2; exit 1 ;;
    *)         TARGET="$arg" ;;
  esac
done

TARGET="${TARGET:-$PWD}"
TARGET="$(cd "$TARGET" && pwd)"  # canonicalize

say()  { echo "[init] $*"; }
warn() { echo "[init] WARN: $*" >&2; }
do_or_print() {
  if [[ $DRY_RUN -eq 1 ]]; then echo "  would: $*"; else eval "$@"; fi
}

# --- detect stack ----------------------------------------------------------
detect_stack() {
  local found=()
  [[ -f "$TARGET/package.json" ]]      && found+=("node")
  [[ -f "$TARGET/Cargo.toml" ]]        && found+=("rust")
  [[ -f "$TARGET/go.mod" ]]            && found+=("go")
  [[ -f "$TARGET/pubspec.yaml" ]]      && found+=("flutter")
  [[ -f "$TARGET/pyproject.toml" ]] || [[ -f "$TARGET/requirements.txt" ]] && found+=("python")
  [[ -f "$TARGET/Gemfile" ]]           && found+=("ruby")
  [[ -f "$TARGET/composer.json" ]]     && found+=("php")
  [[ -f "$TARGET/pom.xml" ]] || [[ -f "$TARGET/build.gradle" ]] || [[ -f "$TARGET/build.gradle.kts" ]] && found+=("jvm")
  [[ -f "$TARGET/Package.swift" ]]     && found+=("swift")
  [[ -f "$TARGET/src-tauri/tauri.conf.json" ]] || [[ -f "$TARGET/tauri.conf.json" ]] && found+=("tauri")
  [[ -f "$TARGET/Dockerfile" ]]        && found+=("docker")

  if [[ ${#found[@]} -eq 0 ]]; then echo "unknown"; else echo "${found[*]}"; fi
}

STACK="$(detect_stack)"
say "target:  $TARGET"
say "stack:   $STACK"
say "dry-run: $([[ $DRY_RUN -eq 1 ]] && echo yes || echo no)"

# --- 1. project-level .claude/settings.local.json -------------------------
PROJECT_SETTINGS_DIR="$TARGET/.claude"
PROJECT_SETTINGS="$PROJECT_SETTINGS_DIR/settings.local.json"

write_settings_local() {
  local hint=""
  case "$STACK" in
    *node*)    hint='"// Bash(npm test:*)", "// Bash(npm run build:*)", "// Bash(pnpm test:*)"' ;;
    *rust*)    hint='"// Bash(cargo check:*)", "// Bash(cargo test:*)", "// Bash(cargo clippy:*)"' ;;
    *go*)      hint='"// Bash(go test:*)", "// Bash(go build:*)", "// Bash(go vet:*)"' ;;
    *python*)  hint='"// Bash(pytest:*)", "// Bash(ruff check:*)", "// Bash(mypy:*)"' ;;
    *flutter*) hint='"// Bash(flutter test:*)", "// Bash(flutter analyze:*)"' ;;
    *)         hint='"// Bash(your-test-command:*)"' ;;
  esac

  cat <<EOF
{
  "_comment": "Project-local overrides for Claude Code. Detected stack: ${STACK}. Uncomment / edit the lines below to add safe stack-specific commands to the allowlist.",
  "permissions": {
    "allow": [
      ${hint}
    ]
  }
}
EOF
}

if [[ -f "$PROJECT_SETTINGS" && $FORCE -eq 0 ]]; then
  warn "skipping $PROJECT_SETTINGS (exists; use --force to overwrite)"
else
  do_or_print "mkdir -p '$PROJECT_SETTINGS_DIR'"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  would write: $PROJECT_SETTINGS"
    echo "  --- content ---"
    write_settings_local | sed 's/^/  /'
    echo "  ---"
  else
    write_settings_local > "$PROJECT_SETTINGS"
    say "wrote $PROJECT_SETTINGS"
  fi
fi

# --- 2. per-project memory dir + seed all .md files (except README) -------
PROJECT_ID="${TARGET//\//-}"
MEMORY_DIR="$HOME/.claude/projects/${PROJECT_ID}/memory"
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"

if [[ -f "$MEMORY_INDEX" && $FORCE -eq 0 ]]; then
  warn "skipping memory seed at $MEMORY_DIR (MEMORY.md exists; use --force to overwrite)"
else
  do_or_print "mkdir -p '$MEMORY_DIR'"
  for seed in "$CLAUDE_CORE_DIR"/memory-template/*.md; do
    [[ "$(basename "$seed")" == "README.md" ]] && continue
    do_or_print "cp '$seed' '$MEMORY_DIR/'"
  done
  [[ $DRY_RUN -eq 0 ]] && say "seeded $MEMORY_DIR/ ($(ls "$CLAUDE_CORE_DIR"/memory-template/*.md | grep -v README | wc -l | tr -d ' ') files)"
fi

# --- summary ---------------------------------------------------------------
echo ""
say "done. next steps:"
echo "  - Edit $PROJECT_SETTINGS to enable stack-specific test/build commands"
echo "  - Add a project-level AGENTS.md (per agents.md convention) describing this project's setup / tests / conventions"
echo "  - Add a project-level CLAUDE.md if this project needs behavioral rules beyond the global baseline"
echo "  - Memory entries go under $MEMORY_DIR/ (one file per entry, indexed in MEMORY.md)"
