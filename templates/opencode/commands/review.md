---
description: 提交前综合审查（代码风格+测试+依赖；非整阶段验收）
agent: build
---
执行**提交前**综合审查（单次 diff），先按 `AGENTS.md` 的规模门控判定档位：

1. **S 级（小改）**：直接输出「无需全量审查（S 级，目检即可）」，列出目检要点，不调用子代理。
2. **M 级（中改）**：仅审查本次 git diff 涉及的文件：
   - 调用 @code-stylespector 检查本次变更涉及的文件代码风格
   - 调用 @test-engineer 运行**与本次 diff 相关的测试**（明确限定文件范围，禁止全量、禁止编写新测试）
   - 如有 package.json 变更，调用 @dependencies-checker 检查依赖
3. **L 级（大改）**：全量风格 + 测试 + 依赖检查。
4. 汇总审查结果，给出是否可以提交的建议。

注意：
- 仅检查本次 git diff 中涉及的文件，避免全量扫描。
- S/M 级禁止触发全量测试；测试仅覆盖受影响范围。
- 若人类要做**整阶段**对照计划验收，改用 `/accept-phase`（见 `docs/ai-framework/phased-plan-driven.md`），不要与本命令混淆。

$ARGUMENTS