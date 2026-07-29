---
description: 提交前综合审查（代码风格+测试+依赖）
agent: build
---
执行提交前综合审查，按以下步骤进行：

1. 首先调用 @code-stylespector 检查本次变更涉及的文件代码风格
2. 然后调用 @test-engineer 运行相关测试
3. 如有 package.json 变更，调用 @dependencies-checker 检查依赖
4. 汇总审查结果，给出是否可以提交的建议

注意：仅检查本次 git diff 中涉及的文件，避免全量扫描。
$ARGUMENTS