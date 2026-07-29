# Codex — 项目级安装说明

本目录内容来自 [obra/superpowers](https://github.com/obra/superpowers) 的 Codex 适配切片（MIT）。

## 本 skill 会写入目标项目

- `.codex-plugin/plugin.json`（插件清单元数据，便于对照官方形态）
- `docs/ai-framework/codex-tools.md`（Codex 工具映射参考，来自 superpowers）

## 推荐的完整用法（官方）

Superpowers 在 Codex 上主要通过 **Codex 插件机制** 分发完整 skills。项目级文件不足以替代官方插件安装。

请在 Codex 中按官方文档安装 superpowers 插件，或参考：

- 仓库：https://github.com/obra/superpowers
- 脚本：`scripts/package-codex-plugin.sh`、`scripts/sync-to-codex-plugin.sh`

本 skill **仅做项目级落盘**，不写入 `~/.codex`。
