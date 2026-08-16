---
description: 运行测试或编写新测试（按规模门控限定范围）
agent: build
---
使用 @test-engineer 子代理处理以下任务。先按 `AGENTS.md` 的规模门控判定档位：S 级不运行测试；M 级只运行与本次 diff 相关的测试；L 级才运行全量测试。

$ARGUMENTS