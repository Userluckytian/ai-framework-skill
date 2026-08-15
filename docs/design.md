# 设计说明

## 动机

把「AI 工程能力」抽成独立 skill 仓库，按需装入任意业务项目：

1. **提交级**：OpenCode 子代理/命令 + 代码审查清单 + 可参数化规范文档  
2. **阶段级**：**阶段化计划驱动交付**（计划 → 交接提示词 → 执行 → 独立验收）  
3. **多 harness**：obra/superpowers 在 Codex / Claude / Cursor 等上的项目级切片  

## 原则

1. **仅项目级**：配置随仓库走，不碰各 IDE 全局目录。  
2. **OpenCode 用自研**：agents / commands 来自实践沉淀（审查流 + 阶段流）。  
3. **其他 harness 用 superpowers**：Codex / Claude / Cursor / Gemini / Kimi 适配层来自 obra/superpowers。  
4. **可参数化**：`{{PROJECT_NAME}}`、`{{CSS_PREFIX}}`，避免业务名硬编码。  
5. **复制不移动**：只从 `templates/` 复制到目标项目。  
6. **两层不混用**：`/review` = 单次 diff；`/accept-phase` = 整阶段对照验收表。
7. **三原则**：任务定义落盘（不丢）→ 进度靠 commit+验收表判定（可恢复）→ 子代理任务幂等（可重放）。

## 能力分层

```text
┌─────────────────────────────────────────────┐
│  阶段化计划驱动（Phased Plan-Driven）         │
│  phased-plan-driven.md + phase-planner/    │
│  acceptor + /plan-phase /accept-phase /handoff│
└─────────────────────────────────────────────┘
                      ↑ 产出多 Task 计划
┌─────────────────────────────────────────────┐
│  提交前审查（Commit Review）                  │
│  CODE_REVIEW + style/test/deps + /review    │
└─────────────────────────────────────────────┘
                      ↑ 单次 commit
┌─────────────────────────────────────────────┐
│  项目规范文档                                 │
│  AGENTS / coding-standards / architecture   │
└─────────────────────────────────────────────┘
```

## 安装交互

用户选择 a/b/c/d/e → 渲染模板 → 写入项目根 → 冲突策略 → 清单。

选择 **a（OpenCode）** 时额外写入：

- `.opencode/agents/phase-planner.md`、`phase-acceptor.md`  
- `.opencode/commands/plan-phase.md`、`accept-phase.md`、`handoff.md`  
- `docs/ai-framework/phased-plan-driven.md`  
- `docs/ai-framework/phase-plan.template.md`  
- `docs/ai-framework/plan-layering.md`（多阶段编排：总览/执行分层 + 并行派工表）
- `docs/ai-framework/plans/README.md`  

## 实践来源

阶段化工作流提炼自多阶段产品交付（规划与执行分离、验收表、可粘贴交接提示词、有条件通过）。  
提交审查流来自既有 jiejian/OpenCode 实践。
