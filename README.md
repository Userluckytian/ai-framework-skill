# ai-framework-skill

把 **OpenCode 自研 AI 能力**（子代理、命令、提交审查、**阶段化计划驱动**）以及 **obra/superpowers** 在其他 harness 上的项目级切片，安装进任意工程仓库。

> [!IMPORTANT]
> <font color="#008000"><strong>写代码想靠 AI 守住规范与交付节奏，却每个项目都要重新配置？</strong></font>  
> <font color="#008000"><strong>ai-framework-skill：一次集成，审查流 + 阶段计划/验收跟项目走。</strong></font>

> [!NOTE]
> **仅项目级** — 配置只写入目标业务项目根目录，不写入各 IDE 全局目录。

- GitHub: https://github.com/Userluckytian/ai-framework-skill

## 安装

```bash
# 全局（推荐，各项目可用）
npx skills add Userluckytian/ai-framework-skill@ai-framework -g -y

# 仅当前项目
npx skills add Userluckytian/ai-framework-skill@ai-framework -y
```

## 使用

在目标项目中对 AI 说：

```text
集成ai框架到当前项目
```

按提示选择工具（OpenCode / Codex / Claude / All 等）即可。

### 安装 OpenCode 后常用命令

| 命令 | 用途 |
|------|------|
| `/plan-phase` | 起草阶段计划（Task + 测试 + 验收表 + 交接提示词） |
| `/handoff` | 生成可粘贴给执行 AI 的提示词 |
| `/accept-phase` | 对照计划独立验收（基线 / 对照表 / 结论 / 下一步） |
| `/review` | **提交前**综合审查（风格 + 测试 + 依赖） |

元规范落在：`docs/ai-framework/phased-plan-driven.md`（单阶段内：计划→交接→验收 + **验证不通过项下放机制**）。  
多阶段/多执行者编排（总览 + 执行计划 + 并行派工）另见：`docs/ai-framework/plan-layering.md`。  
计划实例：`docs/ai-framework/plans/`（也可继续用已有的 `docs/superpowers/plans/`）。  

**原则**：边界先于功能 → 计划可交接 → 任务可验证 → 验收认证据。

---

## 内容来源

| 分区 | 来源 |
|------|------|
| `templates/opencode` | 自研 OpenCode agents / commands（审查四件套 + **phase-planner / phase-acceptor**） |
| `templates/common/docs` | **阶段化计划驱动**元规范与计划模板 |
| `templates/codex`、`claude`、`others` | [obra/superpowers](https://github.com/obra/superpowers)（MIT） |
| `templates/common` | AGENTS、提交/审查清单、可参数化编码与架构说明 |

更多说明见 [docs/](docs/)、[SKILL.md](SKILL.md)、[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## Persona / Role templates

项目级 persona（角色设定）模板存放在 `templates/common/prompts/`。若安装脚本或交互时启用 persona，安装程序会列出该目录下的可用模板供用户选择并把所选 persona 写入目标项目（默认不安装）。

在添加新的角色设定时，请在 README 中注明来源并保留原始作者信息。例如：

- 海鸥.md — 来源: https://github.com/yynxxxxx/Codex-X/blob/main/examples/%E6%B5%B8%E9%B8%A53.0%E7%A0%B4%E7%94%B2.md

请确保在将外部模板原样复制到本仓库或分发前已确认其许可与授权兼容性。

## License

本仓库自有文件见 [LICENSE](LICENSE)。从 superpowers 复制的切片遵循其 MIT 许可。