---
name: ai-framework
description: >
  将可复用 AI 工程能力安装到当前项目（仅项目级）。支持 OpenCode 自研 agents/commands
  （提交审查 + 阶段化计划驱动），以及 Codex / Claude / Cursor 等基于 obra/superpowers 的项目级切片。
  在用户说「集成ai框架到当前项目」「安装 AI 框架」「/ai-framework」时使用。
---

# AI Framework（仅项目级安装）

## 目标

把本仓库 `templates/` 中的配置 **写入目标项目根目录**。  
**不写入** `~/.config/opencode`、`~/.codex`、`~/.claude`、`~/.grok` 等任何全局路径。

安装后目标项目具备两层能力：

1. **阶段化计划驱动**：`/plan-phase` → 执行（交接提示词）→ `/accept-phase`  
2. **提交前审查**：`/style` `/test` `/deps` `/review`

## 何时使用

- 用户要在新仓库启用 OpenCode 子代理、审查流与**阶段计划/验收**流程  
- 用户运行 `/ai-framework` 或说「安装 AI 框架」「集成ai框架到当前项目」  
- 用户要为 Codex / Claude 等落 superpowers 相关项目级文件  

## 源仓库

- 本 skill 内容源：https://github.com/Userluckytian/ai-framework-skill  
- 本地开发路径示例：`D:\AI_Projects\ai-framework-skill`  
- superpowers 上游：https://github.com/obra/superpowers（MIT）

若当前环境尚未持有本仓库副本：先 `git clone` 到临时目录或使用已配置的 skill 根目录，以该副本的 `templates/` 为源。

## 交互流程（必须逐步执行）

### 1. 确认目标项目根

- 默认：当前工作区 git 根或用户指定路径  
- 向用户确认后再写入  

### 2. 询问要安装的工具（单选）

| 选项 | 含义 |
|------|------|
| **a** OpenCode（Recommended） | `.opencode` agents/commands（**含阶段流**）+ 公共规范 + `docs/ai-framework/phased-plan-driven.md` |
| **b** Codex | superpowers Codex 项目级切片 |
| **c** Claude Code | superpowers Claude 项目级切片 |
| **d** All | a + b + c |
| **e** Others | Cursor / Gemini / Kimi 参考切片 |

**不要**询问 global / project 作用域——固定为项目级。

### 3. 询问模板变量

- `PROJECT_NAME`：默认读目标项目 `package.json` 的 `name`，否则用目录名  
- `CSS_PREFIX`：默认 `app`（用于 `--{{CSS_PREFIX}}-*` CSS 变量）  
- 是否写入 `architecture.md` / `coding-standards.md`（默认是）  

### 4. 冲突策略

若目标已存在同名文件：询问 **overwrite / skip / backup**（backup 为复制为 `*.bak`）。

### 5. 执行安装

```powershell
pwsh -File "<SKILL_ROOT>/scripts/install.ps1" -TargetRoot "<PROJECT_ROOT>" -Tool <opencode|codex|claude|all|others> -ProjectName "<NAME>" -CssPrefix "<PREFIX>" -Conflict <overwrite|skip|backup>
```

```bash
bash "<SKILL_ROOT>/scripts/install.sh" --target "<PROJECT_ROOT>" --tool <opencode|codex|claude|all|others> --project-name "<NAME>" --css-prefix "<PREFIX>" --conflict <overwrite|skip|backup>
```

若无法跑脚本，则按下方「手动映射」复制并做 `{{PROJECT_NAME}}` / `{{CSS_PREFIX}}` 替换。

### 6. 汇报

列出写入/跳过/备份的路径；提示重载 IDE。  
若安装了 OpenCode，额外提示：

- 读 `docs/ai-framework/phased-plan-driven.md`  
- 试 `/plan-phase`、`/handoff`、`/accept-phase`  
- 与 `/review`（提交前）区分  

## 手动映射（脚本不可用时）

设 `SRC = <ai-framework-skill 根>/templates`，`DST = <目标项目根>`。

### a — OpenCode

1. 复制 `SRC/opencode/*` → `DST/.opencode/`（agents、commands、opencode.jsonc）  
2. 渲染 `SRC/common/AGENTS.md.template` → `DST/AGENTS.md`  
3. 复制 `SRC/common/CODE_REVIEW.md` → `DST/CODE_REVIEW.md`  
4. 渲染 `SRC/common/coding-standards.md.template` → `DST/coding-standards.md`  
5. 渲染 `SRC/common/architecture.md.template` → `DST/architecture.md`（若用户需要）  
6. 渲染 `SRC/common/docs/phased-plan-driven.md.template` → `DST/docs/ai-framework/phased-plan-driven.md`  
7. 渲染 `SRC/common/docs/phase-plan.template.md` → `DST/docs/ai-framework/phase-plan.template.md`  
8. 渲染 `SRC/common/docs/plans-README.md.template` → `DST/docs/ai-framework/plans/README.md`  

替换规则：全文 `{{PROJECT_NAME}}`、`{{CSS_PREFIX}}`。

### b — Codex / c — Claude / e — Others

同原说明：见历史映射；Claude 渲染 `CLAUDE.md.template`（已含阶段协作短指引）。

### d — All

依次 a、b、c。

## 禁止事项

- 禁止写入用户主目录下的全局 harness 配置  
- 禁止从业务源仓库 **移动/删除** 文件（只读复制 templates）  
- 禁止把未替换的 `{{PROJECT_NAME}}` 留在已渲染的目标文件中  

## 参考

- `docs/project-paths.md`  
- `docs/design.md`  
- `THIRD_PARTY_NOTICES.md`  
