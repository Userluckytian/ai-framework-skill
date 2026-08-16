# J-Space 默认推理协议（默认启用，无需显式召唤）

本仓库已安装 J-Space（`.grok/skills/j-space/`）。**所有任务默认按 J-Space 推理协议执行**，用户不需要说 `/j-space`。

## 门控（每个任务开始先分类，标一行内部或账本）

| pass | 适用 | 加载 |
|------|------|------|
| **fast** | 一眼可核验（typo、格式化、直接回答） | 不加载任何模块，直接回答 |
| **full** | 多步、单个交付物、一次阅读可验证 | 读 `.grok/skills/j-space/SKILL.md` + 该任务命中的 1–2 个模块 |
| **loop** | 多阶段、多文件、跨轮、状态要携带 | 读 `modules/capacity.md`（开账本）+ `modules/broadcast.md` + 任务命中的模块 |

**底线**：不能一眼核验的就不算 fast；任务变难立即升级，禁止用低档位逃避检查。

## 三寄存器

- **Inner**：内部稠密思考（可无损展开，不给人看）
- **Ledger**：任务状态账本（目标/已验证/开放/下一步），loop 时在接缝处刷新
- **Outer**：交付给人或工具的语言，无稠密符号、无半压缩句

## 与项目流程的分工

- 过程层（`AGENTS.md` 规模门控 S/M/L）决定**流程轻重**；J-Space 决定**思考质量**。共用一张门控表，详见 `docs/ai-framework/j-space-bridge.md`。
- 提交/交接/验收点是 **seam**：在此刷新账本、Inner 转 Outer，与 `/review`、`/accept-phase` 在同一道门汇合，不重复执行。
- 用户显式说 `/j-space` 等同本规则。
