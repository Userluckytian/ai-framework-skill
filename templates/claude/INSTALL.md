# Claude Code — 项目级安装说明

本目录内容来自 [obra/superpowers](https://github.com/obra/superpowers) 的 Claude 适配切片（MIT）。

## 本 skill 会写入目标项目

- `.claude-plugin/`（plugin.json / marketplace 元数据）
- `hooks/`（SessionStart 等 hooks，相对项目或插件根使用）
- 可选：`CLAUDE.md`（由 common 模板渲染，偏项目规范；与 superpowers 贡献者 CLAUDE.md 不同）

## 推荐的完整用法（官方）

在 Claude Code 中安装 superpowers 插件以获得完整 skills + session bootstrap：

```text
# 按 Claude Code 当前插件安装方式操作，例如 marketplace / plugin install
# 详见 https://github.com/obra/superpowers 与 .claude-plugin/
```

本 skill **仅做项目级落盘**，不写入 `~/.claude`。
