#!/usr/bin/env bash
# Install AI framework templates into a project root (project-level only).
set -euo pipefail

TARGET_ROOT=""
TOOL=""
PROJECT_NAME=""
CSS_PREFIX="app"
CONFLICT="backup"
SKILL_ROOT=""

usage() {
  cat <<'EOF'
Usage:
  install.sh --target PATH --tool opencode|codex|claude|all|others
             [--project-name NAME] [--css-prefix PREFIX]
             [--conflict overwrite|skip|backup] [--skill-root PATH]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_ROOT="$2"; shift 2 ;;
    --tool) TOOL="$2"; shift 2 ;;
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --css-prefix) CSS_PREFIX="$2"; shift 2 ;;
    --conflict) CONFLICT="$2"; shift 2 ;;
    --skill-root) SKILL_ROOT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$TARGET_ROOT" || -z "$TOOL" ]]; then
  usage
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="${SKILL_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TEMPLATES="$SKILL_ROOT/templates"
TARGET_ROOT="$(cd "$TARGET_ROOT" && pwd)"

if [[ ! -d "$TEMPLATES" ]]; then
  echo "templates/ not found under $SKILL_ROOT" >&2
  exit 1
fi

if [[ -z "$PROJECT_NAME" ]]; then
  if [[ -f "$TARGET_ROOT/package.json" ]] && command -v node >/dev/null 2>&1; then
    PROJECT_NAME="$(node -pe "require('$TARGET_ROOT/package.json').name" 2>/dev/null || true)"
  fi
  PROJECT_NAME="${PROJECT_NAME:-$(basename "$TARGET_ROOT")}"
fi

log() { printf '%s\n' "$*"; }

ensure_dir() { mkdir -p "$1"; }

render_file() {
  local src="$1" dest="$2"
  ensure_dir "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    case "$CONFLICT" in
      skip) log "SKIP  $dest"; return ;;
      backup) cp "$dest" "$dest.bak"; log "BACKUP $dest -> $dest.bak" ;;
      overwrite) log "OVERWRITE $dest" ;;
    esac
  fi
  # portable-ish replace without requiring envsubst for custom delimiters
  sed -e "s/{{PROJECT_NAME}}/${PROJECT_NAME//\//\\/}/g" \
      -e "s/{{CSS_PREFIX}}/${CSS_PREFIX//\//\\/}/g" \
      "$src" > "$dest"
  log "WRITE $dest"
}

copy_file() {
  local src="$1" dest="$2"
  ensure_dir "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    case "$CONFLICT" in
      skip) log "SKIP  $dest"; return ;;
      backup) cp "$dest" "$dest.bak"; log "BACKUP $dest -> $dest.bak" ;;
      overwrite) log "OVERWRITE $dest" ;;
    esac
  fi
  cp "$src" "$dest"
  log "WRITE $dest"
}

copy_tree() {
  local src="$1" dest="$2" render="${3:-0}"
  [[ -d "$src" ]] || { log "MISSING $src"; return; }
  while IFS= read -r -d '' f; do
    rel="${f#$src/}"
    rel="${rel#$src\\}"
    out="$dest/$rel"
    if [[ "$render" == "1" && "$f" =~ \.(md|template|jsonc)$ ]]; then
      render_file "$f" "$out"
    else
      copy_file "$f" "$out"
    fi
  done < <(find "$src" -type f -print0)
}

install_opencode() {
  log "=== OpenCode ==="
  local src="$TEMPLATES/opencode"
  local dst="$TARGET_ROOT/.opencode"
  ensure_dir "$dst"
  copy_file "$src/opencode.jsonc" "$dst/opencode.jsonc"
  copy_tree "$src/agents" "$dst/agents" 1
  copy_tree "$src/commands" "$dst/commands" 1
  local common="$TEMPLATES/common"
  render_file "$common/AGENTS.md.template" "$TARGET_ROOT/AGENTS.md"
  copy_file "$common/CODE_REVIEW.md" "$TARGET_ROOT/CODE_REVIEW.md"
  render_file "$common/coding-standards.md.template" "$TARGET_ROOT/coding-standards.md"
  render_file "$common/architecture.md.template" "$TARGET_ROOT/architecture.md"
}

install_codex() {
  log "=== Codex ==="
  local src="$TEMPLATES/codex"
  copy_tree "$src/.codex-plugin" "$TARGET_ROOT/.codex-plugin" 0
  ensure_dir "$TARGET_ROOT/docs/ai-framework"
  [[ -f "$src/references/codex-tools.md" ]] && copy_file "$src/references/codex-tools.md" "$TARGET_ROOT/docs/ai-framework/codex-tools.md"
  copy_file "$src/INSTALL.md" "$TARGET_ROOT/docs/ai-framework/codex-INSTALL.md"
}

install_claude() {
  log "=== Claude ==="
  local src="$TEMPLATES/claude"
  copy_tree "$src/.claude-plugin" "$TARGET_ROOT/.claude-plugin" 0
  copy_tree "$src/hooks" "$TARGET_ROOT/.claude/hooks" 0
  render_file "$TEMPLATES/common/CLAUDE.md.template" "$TARGET_ROOT/CLAUDE.md"
  ensure_dir "$TARGET_ROOT/docs/ai-framework"
  copy_file "$src/INSTALL.md" "$TARGET_ROOT/docs/ai-framework/claude-INSTALL.md"
}

install_others() {
  log "=== Others ==="
  copy_tree "$TEMPLATES/others" "$TARGET_ROOT/docs/ai-framework/others" 0
}

log "SkillRoot=$SKILL_ROOT"
log "TargetRoot=$TARGET_ROOT"
log "Tool=$TOOL ProjectName=$PROJECT_NAME CssPrefix=$CSS_PREFIX Conflict=$CONFLICT"

case "$TOOL" in
  opencode) install_opencode ;;
  codex) install_codex ;;
  claude) install_claude ;;
  all) install_opencode; install_codex; install_claude ;;
  others) install_others ;;
  *) echo "bad tool: $TOOL" >&2; exit 1 ;;
esac

log "Done. Global harness dirs were NOT modified."
