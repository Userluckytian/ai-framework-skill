#!/usr/bin/env bash
# Install AI framework templates into a project root (project-level only).
set -euo pipefail

TARGET_ROOT=""
TOOL=""
PROJECT_NAME=""
CSS_PREFIX="app"
VISION_MODEL="oc-local/mimo-v2.5"
CONFLICT="backup"
SKILL_ROOT=""
PERSONA=""
NO_PERSONA=false

usage() {
  cat <<'EOF'
Usage:
  install.sh --target PATH --tool opencode|codex|claude|all|others
             [--project-name NAME] [--css-prefix PREFIX]
             [--vision-model PROVIDER/MODEL] [--conflict overwrite|skip|backup] [--skill-root PATH]
             [--persona FILENAME] [--no-persona]

Notes:
  --persona specifies a persona (from templates/common/prompts/*.md) to write into the target CLAUDE.md (opt-in).
  --no-persona skips persona installation (default behavior if neither provided nor accepted interactively).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_ROOT="$2"; shift 2 ;;
    --tool) TOOL="$2"; shift 2 ;;
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --css-prefix) CSS_PREFIX="$2"; shift 2 ;;
    --vision-model) VISION_MODEL="$2"; shift 2 ;;
    --conflict) CONFLICT="$2"; shift 2 ;;
    --skill-root) SKILL_ROOT="$2"; shift 2 ;;
    --persona) PERSONA="$2"; shift 2 ;;
    --no-persona) NO_PERSONA=true; shift ;;
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
  PROJECT_NAME="${PROJECT_NAME:-$(basename "$TARGET_ROOT") }"
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
  sed -e "s/{{PROJECT_NAME}}/${PROJECT_NAME//\//\\\/}/g" \
      -e "s/{{CSS_PREFIX}}/${CSS_PREFIX//\//\\\/}/g" \
      -e "s/{{VISION_MODEL}}/${VISION_MODEL//\//\\\/}/g" \
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
    case "$f" in
      *__pycache__*|*.pyc) continue ;;
    esac
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

# More portable list_personas + interactive selection (avoid GNU-find -printf and bash mapfile)
list_personas() {
  local dir="$TEMPLATES/common/prompts"
  if [[ ! -d "$dir" ]]; then
    return
  fi

  local files
  files=("$dir"/*.md)

  # If glob didn't match, files[0] will be literal pattern; ensure it exists
  if [[ ! -e "${files[0]}" ]]; then
    return
  fi

  for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
      printf '%s\n' "${f##*/}"
    fi
  done | sort
}

select_persona_interactive() {
  # return selected filename in PERSONA or empty
  local files=()
  local line

  while IFS= read -r line; do
    files+=("$line")
  done < <(list_personas)

  if [[ ${#files[@]} -eq 0 ]]; then
    log "没有可用的 persona 模板，跳过。"
    PERSONA=""
    return
  fi

  log "请选择要安装的 persona："
  local i=1
  for f in "${files[@]}"; do
    printf '  %d) %s\n' "$i" "$f"
    i=$((i+1))
  done
  printf '  0) 取消\n'
  read -p "输入序号并回车: " sel
  if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -gt 0 ] && [ "$sel" -le ${#files[@]} ]; then
    PERSONA="${files[$((sel-1))]}"
  else
    log "取消 persona 安装，继续默认流程。"
    PERSONA=""
  fi
}

install_opencode() {
  log "=== OpenCode ==="
  local src="$TEMPLATES/opencode"
  local dst="$TARGET_ROOT/.opencode"
  ensure_dir "$dst"
  copy_file "$src/opencode.jsonc" "$dst/opencode.jsonc"
  copy_tree "$src/agents" "$dst/agents" 1
  copy_tree "$src/commands" "$dst/commands" 1
  # 视觉子代理配套桥脚本（python，不渲染）
  [[ -d "$src/scripts" ]] && copy_tree "$src/scripts" "$dst/scripts" 0
  local common="$TEMPLATES/common"
  render_file "$common/AGENTS.md.template" "$TARGET_ROOT/AGENTS.md"
  copy_file "$common/CODE_REVIEW.md" "$TARGET_ROOT/CODE_REVIEW.md"
  render_file "$common/coding-standards.md.template" "$TARGET_ROOT/coding-standards.md"
  render_file "$common/architecture.md.template" "$TARGET_ROOT/architecture.md"

  # Phased plan-driven delivery
  local af_docs="$TARGET_ROOT/docs/ai-framework"
  local af_plans="$af_docs/plans"
  ensure_dir "$af_plans"
  render_file "$common/docs/phased-plan-driven.md.template" "$af_docs/phased-plan-driven.md"
  render_file "$common/docs/phase-plan.template.md" "$af_docs/phase-plan.template.md"
  render_file "$common/docs/plan-layering.md.template" "$af_docs/plan-layering.md"
  render_file "$common/docs/plans-README.md.template" "$af_plans/README.md"
  # 子代理脚手架（配 /new-agent 命令生成项目专属 agent）
  render_file "$common/docs/agent.template.md" "$af_docs/agent.template.md"
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

  # persona handling: if PERSONA set, copy it over (opt-in)
  if [[ -n "$PERSONA" ]]; then
    local psrc="$TEMPLATES/common/prompts/$PERSONA"
    if [[ -f "$psrc" ]]; then
      copy_file "$psrc" "$TARGET_ROOT/CLAUDE.md"
      log "Installed persona: $PERSONA -> $TARGET_ROOT/CLAUDE.md"
    else
      log "Persona file not found: $psrc"
    fi
  fi

  ensure_dir "$TARGET_ROOT/docs/ai-framework"
  copy_file "$src/INSTALL.md" "$TARGET_ROOT/docs/ai-framework/claude-INSTALL.md"
}

install_others() {
  log "=== Others ==="
  copy_tree "$TEMPLATES/others" "$TARGET_ROOT/docs/ai-framework/others" 0
}

# Interactive persona selection when not provided nor explicitly disabled
if [[ -z "$PERSONA" && "$NO_PERSONA" = false && -t 0 ]]; then
  read -p "是否采用特定角色设定（persona）？ (y/N): " yn
  case "$yn" in
    [Yy]*)
      select_persona_interactive
      ;;
    *)
      log "不安装 persona，继续默认流程."
      ;;
  esac
fi

log "SkillRoot=$SKILL_ROOT"
log "TargetRoot=$TARGET_ROOT"
log "Tool=$TOOL ProjectName=$PROJECT_NAME CssPrefix=$CSS_PREFIX Conflict=$CONFLICT Persona=${PERSONA:-<none>}"

case "$TOOL" in
  opencode) install_opencode ;;
  codex) install_codex ;;
  claude) install_claude ;;
  all) install_opencode; install_codex; install_claude ;;
  others) install_others ;;
  *) echo "bad tool: $TOOL" >&2; exit 1 ;;
esac

log "Done. Global harness dirs were NOT modified." 
