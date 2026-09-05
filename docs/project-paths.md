# 项目级路径对照

本框架 **只安装到目标项目根目录**，不写入全局配置。

| 选项 | 工具 | 项目根落点 |
|------|------|------------|
| a | OpenCode | 见下方「OpenCode 落点明细」 |
| b | Codex | `.codex-plugin/`、`docs/ai-framework/codex-tools.md` |
| c | Claude Code | `.claude-plugin/`、`.claude/hooks/`、`CLAUDE.md` |
| d | All | a + b + c |
| e | others | Cursor / Gemini / Kimi 参考文件（见 `templates/others`） |

## OpenCode 落点明细（选项 a）

| 路径 | 来源模板 | 说明 |
|------|----------|------|
| `.opencode/opencode.jsonc` | `templates/opencode/` | OpenCode 项目配置 |
| `.opencode/agents/*.md` | 同上 | 含审查四件套 + **phase-planner / phase-acceptor** |
| `.opencode/commands/*.md` | 同上 | 含 `/review` 等 + **`/plan-phase` `/accept-phase` `/handoff`** |
| `AGENTS.md` | `templates/common/AGENTS.md.template` | 代理入口（阶段流 + 审查流） |
| `CODE_REVIEW.md` | `templates/common/` | 提交审查清单 |
| `coding-standards.md` | 模板渲染 | 编码规范 |
| `docs/ai-framework/phased-plan-driven.md` | `common/docs/*.template` | **阶段化元规范** |
| `docs/ai-framework/phase-plan.template.md` | 同上 | 单阶段空白计划 |
| `docs/ai-framework/plans/` | 安装时创建 | 阶段计划实例目录 |

## 与 Grok skill 路径的区别

| 路径 | 用途 |
|------|------|
| `~/.grok/skills/ai-framework/` 或 `~/.agents/skills/ai-framework/` | 仅「安装器 skill」本体 |
| 目标项目 `.opencode` 等 | 业务仓库的 AI 配置（本安装器写入这里） |

不要把 harness 配置写到 `~/.grok`。

## 业务项目已有 superpowers plans 时

若目标仓库已使用 `docs/superpowers/plans/`（常见于 superpowers 工作流）：

- **不必迁移**历史计划  
- 新计划可继续写在 `docs/superpowers/plans/`  
- 在 `AGENTS.md` 或元规范中注明「主计划目录」即可  
- 安装仍会创建 `docs/ai-framework/plans/` 作为默认推荐目录  
