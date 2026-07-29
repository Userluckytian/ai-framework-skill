# ai-framework-skill

把 **OpenCode 自研 AI 能力**（子代理、命令、提交审查）以及 **obra/superpowers** 在其他 harness 上的项目级切片，安装进任意前端/工程仓库。

> **仅项目级安装** — 不写入 `~/.config/opencode`、`~/.codex`、`~/.claude` 等全局目录。

## 仓库

- GitHub: https://github.com/Userluckytian/ai-framework-skill

## 内容来源

| 分区 | 来源 |
|------|------|
| `templates/opencode` | jiejian-frontend-framework 实践（agents / commands） |
| `templates/codex` `claude` `others` | [obra/superpowers](https://github.com/obra/superpowers)（MIT） |
| `templates/common` | 提交规范、审查清单、可参数化编码/架构说明 |

详见 `THIRD_PARTY_NOTICES.md`。

## 快速使用

### 1）作为 Grok / Agent Skill

将本仓库放到 skill 搜索路径，或：

```text
~/.grok/skills/ai-framework/   # 可 clone 本仓或复制 SKILL.md + templates + scripts
```

在目标项目中对 agent 说：

```text
安装 AI 框架
```

或按 `SKILL.md` 流程选择：

- **a** OpenCode  
- **b** Codex  
- **c** Claude Code  
- **d** All  
- **e** Others（Cursor / Gemini / Kimi 参考）

### 2）命令行（推荐脚本）

```powershell
pwsh -File .\scripts\install.ps1 `
  -TargetRoot "D:\path\to\your-project" `
  -Tool opencode `
  -ProjectName "my-app" `
  -CssPrefix "app" `
  -Conflict backup
```

```bash
bash ./scripts/install.sh \
  --target /path/to/your-project \
  --tool opencode \
  --project-name my-app \
  --css-prefix app \
  --conflict backup
```

`Tool` 可选：`opencode` | `codex` | `claude` | `all` | `others`。

## 模板变量

安装时替换：

- `{{PROJECT_NAME}}` — 项目显示名  
- `{{CSS_PREFIX}}` — CSS 变量前缀（生成 `--app-color-primary` 这类形式）

## 文档

- [项目级路径](docs/project-paths.md)
- [设计说明](docs/design.md)

## License

本仓库自有文件见 `LICENSE`。从 superpowers 复制的切片遵循其 MIT 许可。
