# ai-framework-skill

把 **OpenCode 自研 AI 能力**（子代理、命令、提交审查）以及 **obra/superpowers** 在其他 harness 上的项目级切片，安装进任意工程仓库。

> [!IMPORTANT]
> **写代码想靠 AI 守住代码规范、测试和 Git 提交约定，却每个项目都要重新配置？**  
> **ai-framework-skill：一次集成，规范跟项目走。**

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

---

## 内容来源

| 分区 | 来源 |
|------|------|
| `templates/opencode` | 自研 OpenCode agents / commands |
| `templates/codex`、`claude`、`others` | [obra/superpowers](https://github.com/obra/superpowers)（MIT） |
| `templates/common` | 提交规范、审查清单、可参数化编码/架构说明 |

更多说明见 [docs/](docs/)、[SKILL.md](SKILL.md)、[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## License

本仓库自有文件见 [LICENSE](LICENSE)。从 superpowers 复制的切片遵循其 MIT 许可。
