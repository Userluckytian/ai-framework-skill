# 设计说明

## 动机

把前端框架中的 AI 能力（OpenCode 子代理/命令 + 提交审查流程 + 规范文档）抽成独立仓库，通过 skill 按需装入任意新项目。

## 原则

1. **仅项目级**：配置随仓库走，不碰各 IDE 全局目录。
2. **OpenCode 用自研**：agents / commands / 审查流来自 jiejian 实践。
3. **其他 harness 用 superpowers**：Codex / Claude / Cursor / Gemini / Kimi 适配层来自 obra/superpowers。
4. **可参数化**：`{{PROJECT_NAME}}`、`{{CSS_PREFIX}}`，避免 CDPS 硬编码。
5. **复制不移动**：源业务仓库文件保持不动。

## 安装交互

用户选择 a/b/c/d/e → 渲染模板 → 写入项目根 → 冲突策略 → 清单。
