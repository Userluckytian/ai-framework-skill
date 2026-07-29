# 项目级路径对照

本框架 **只安装到目标项目根目录**，不写入全局配置。

| 选项 | 工具 | 项目根落点 |
|------|------|------------|
| a | OpenCode | `.opencode/`、`AGENTS.md`、`CODE_REVIEW.md`、`coding-standards.md`、`architecture.md`（可选） |
| b | Codex | `.codex-plugin/`、`docs/ai-framework/codex-tools.md` |
| c | Claude Code | `.claude-plugin/`、`hooks/`、`CLAUDE.md`（来自 common 模板） |
| d | All | a + b + c |
| e | others | Cursor / Gemini / Kimi 参考文件（见 `templates/others`） |

## 与 Grok skill 路径的区别

| 路径 | 用途 |
|------|------|
| `~/.grok/skills/ai-framework/` | 仅 Grok 侧「安装器 skill」本体（可选全局装 skill） |
| 目标项目 `.opencode` 等 | 业务仓库的 AI 配置（本安装器写入这里） |

不要把 harness 配置写到 `~/.grok`。
