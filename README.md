# ai-framework-skill

把 **OpenCode 自研 AI 能力**（子代理、命令、提交审查）以及 **obra/superpowers** 在其他 harness 上的项目级切片，安装进任意前端/工程仓库。

> **仅项目级** — 配置只写入**目标业务项目根目录**，不写入 `~/.config/opencode`、`~/.codex`、`~/.claude` 等全局目录。

## 仓库

- GitHub: https://github.com/Userluckytian/ai-framework-skill

## 使用前先分清两层

| 步骤 | 做什么 | 装到哪里 |
|------|--------|----------|
| **① 安装本 skill**（本机一次即可） | 让 Grok / OpenCode / Copilot 等「认识」`ai-framework` | 用户 skill 目录（如 `~/.agents/skills/ai-framework`） |
| **② 在业务项目中执行安装** | 把 agents、命令、规范写入该仓库 | **当前业务项目根目录**（`.opencode/` 等） |

很多人只做了 ① 或只 clone 了仓库，却没有在业务项目里执行 ②，会以为「没装上」。

---

## ① 安装 skill（推荐：Skills CLI）

### 推荐命令（直接指定 GitHub，不要依赖搜索）

```bash
# 全局安装（各项目都能用）
npx skills add Userluckytian/ai-framework-skill@ai-framework -g -y

# 或：只装到当前项目的 agent 目录
npx skills add Userluckytian/ai-framework-skill@ai-framework -y
```

等价写法：

```bash
npx skills add Userluckytian/ai-framework-skill -y
npx skills add https://github.com/Userluckytian/ai-framework-skill -y
```

### 验证是否装上

```bash
npx skills list
# 或
npx skills ls -g
```

列表中应出现 **`ai-framework`**，Source 类似 `Userluckytian/ai-framework-skill`。

### 列出仓库里有哪些 skill（不安装）

```bash
npx skills add Userluckytian/ai-framework-skill -l -y
```

应看到：`ai-framework`。

### 关于 `find-skills` / `npx skills find`

| 方式 | 能否找到本 skill |
|------|------------------|
| `npx skills find ai-framework` | ❌ 通常**不能**（查的是 [skills.sh](https://skills.sh/) 公开索引，本仓尚未收录） |
| `npx skills find --owner Userluckytian` | ❌ 通常**不能** |
| `npx skills add Userluckytian/ai-framework-skill@...` | ✅ **可以**（按 GitHub 直链安装） |

**请同事使用时，请直接发安装命令，不要只说「用 find-skills 搜一下」。**

### 手动安装（不用 CLI 时）

```bash
git clone https://github.com/Userluckytian/ai-framework-skill.git
# 按你使用的 agent，把 skill 放到对应目录，例如：
#   ~/.agents/skills/ai-framework/
#   或 ~/.grok/skills/ai-framework/
# 至少需要：SKILL.md + templates/ + scripts/
```

---

## ② 在业务项目里落地配置

### 方式 A：对 AI 说（装好 skill 之后）

在**目标业务仓库**的对话里说：

```text
安装 AI 框架
```

或：

```text
/ai-framework
```

Agent 会按 `SKILL.md` 询问工具类型，然后写入**当前项目根目录**。

可选工具：

| 选项 | 含义 |
|------|------|
| **a** OpenCode | 自研 `.opencode` agents/commands + 公共规范（推荐） |
| **b** Codex | superpowers 相关项目级切片 |
| **c** Claude Code | superpowers 相关项目级切片 |
| **d** All | a + b + c |
| **e** Others | Cursor / Gemini / Kimi 参考文件 |

安装时还会询问（或自动推断）：

- **PROJECT_NAME** — 默认读 `package.json` 的 `name`
- **CSS_PREFIX** — CSS 变量前缀，默认 `app`（生成 `--app-*`）
- **冲突策略** — `overwrite` / `skip` / `backup`

### 方式 B：命令行脚本（不依赖 agent）

先 clone 本仓库（或使用已 clone 的路径），再对目标项目执行：

**Windows (PowerShell)：**

```powershell
pwsh -File "D:\path\to\ai-framework-skill\scripts\install.ps1" `
  -TargetRoot "D:\path\to\your-business-project" `
  -Tool opencode `
  -ProjectName "my-app" `
  -CssPrefix "app" `
  -Conflict backup
```

**macOS / Linux：**

```bash
bash /path/to/ai-framework-skill/scripts/install.sh \
  --target /path/to/your-business-project \
  --tool opencode \
  --project-name my-app \
  --css-prefix app \
  --conflict backup
```

`Tool` 可选：`opencode` | `codex` | `claude` | `all` | `others`。

### 安装后你会在业务项目里看到什么（以 OpenCode 为例）

```text
your-project/
├── .opencode/
│   ├── opencode.jsonc
│   ├── agents/          # test-engineer、code-stylespector 等
│   └── commands/        # /test、/review、/audit 等
├── AGENTS.md
├── CODE_REVIEW.md
├── coding-standards.md
└── architecture.md
```

Codex / Claude 等会写入对应项目级目录，详见 [docs/project-paths.md](docs/project-paths.md)。

装完后**重启或重载**对应 IDE / agent 会话，配置才会被加载。

---

## 模板变量

写入业务项目时会替换：

| 变量 | 含义 | 示例 |
|------|------|------|
| `{{PROJECT_NAME}}` | 项目显示名 | `my-app` |
| `{{CSS_PREFIX}}` | CSS 变量前缀 | `app` → `--app-color-primary` |

避免把业务名（如旧项目里的 CDPS）硬编码进通用模板。

---

## 内容来源

| 分区 | 来源 |
|------|------|
| `templates/opencode` | 自研 OpenCode agents / commands |
| `templates/codex`、`claude`、`others` | [obra/superpowers](https://github.com/obra/superpowers)（MIT） |
| `templates/common` | 提交规范、审查清单、可参数化编码/架构说明 |

详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

---

## 常见问题

**Q: 用 find-skills 搜不到？**  
A: 正常。请用 `npx skills add Userluckytian/ai-framework-skill@ai-framework -g -y`。

**Q: skill 装上了，业务项目里还是没有 `.opencode`？**  
A: 还需要在业务项目里执行 ②（对 agent 说「安装 AI 框架」或跑 `install.ps1` / `install.sh`）。

**Q: 会不会改我电脑上的全局 OpenCode/Claude 配置？**  
A: 不会。本工具只写目标项目根目录。

**Q: Codex/Claude 装完就能用完整 superpowers 工作流吗？**  
A: 本 skill 只落**项目级切片与说明**。完整 skills/bootstrap 仍建议按 [obra/superpowers](https://github.com/obra/superpowers) 官方方式安装对应插件。OpenCode 自研 agents/commands 可直接使用。

**Q: 如何更新 skill？**  
A: `npx skills update ai-framework`（或 `npx skills update -g`），然后再按需对业务项目重新执行安装（注意冲突策略）。

---

## 文档

- [项目级路径对照](docs/project-paths.md)
- [设计说明](docs/design.md)
- [SKILL.md](SKILL.md) — agent 执行安装时的完整流程

## License

本仓库自有文件见 [LICENSE](LICENSE)。从 superpowers 复制的切片遵循其 MIT 许可。
