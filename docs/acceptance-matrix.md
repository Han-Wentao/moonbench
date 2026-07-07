# MoonBench 优秀作品级验收矩阵

本清单依据赛事官网页面源码中的要求整理，并叠加本项目采用的“优秀作品级”自检标准。最终提交前必须逐项核对证据，不能只凭主观判断。

## 官方关键要求

| 要求 | 官方描述摘要 | 本项目证据 |
| --- | --- | --- |
| 参赛对象 | 面向所有对 MoonBit、AI 编程、开源生态和基础软件感兴趣的开发者 | 个人账号 Han-Wentao 已报名 |
| 项目规模 | 4~10k LOC 为参考有效 MoonBit 代码行数，重质量、边界和可维护性 | 已达到 4813 行 MoonBit 源码、测试和示例 |
| 有效工作量 | 统计 2026-04-29 后新增 commits、功能、测试、文档、发布改进 | Git 提交记录与本仓库新增内容 |
| 验收底线 | MoonBit 为主要实现语言，仓库公开可访问 | `moon.mod` 与公开 GitHub 仓库 |
| README | 提供清晰 README | 中文 `README.md` 与 `README.mbt.md` |
| 可运行示例 | 提供 runnable example | `cmd/main` 与 `examples/basic` |
| CI | 提供 CI | `.github/workflows/ci.yml` |
| 测试 | 提供可运行测试 | `moon test` |
| mooncakes 发布 | 发布到 mooncakes.io | `https://mooncakes.io/docs/Han-Wentao/moonbench` |
| 开源合规 | 采用 OSI 认可许可证，不包含未授权代码 | MIT License，原创实现 |

## 本项目优秀作品级目标

| 目标 | 量化标准 | 当前策略 |
| --- | --- | --- |
| MoonBit 代码规模 | 有效 MoonBit 代码行数 >= 4800 | 已达到 4813 行 |
| 中文文档 | README、包文档、开发报告、项目方案均为中文长文档 | 保持中文主文档并补充 API 与验收说明 |
| 功能完整度 | 从单项 benchmark 扩展为报告工具链 | 覆盖 suite、baseline、trend、gate、artifact、format |
| 测试完整度 | 覆盖核心路径和边界路径 | 单元测试、白盒测试、示例运行、CI |
| 提交记录 | commit 信息细致表达功能边界 | 按功能模块分批提交，不使用笼统提交 |
| 发布闭环 | GitHub、mooncakes、GitLink/比赛提交材料齐备 | 重新发布增强版本，整理最终提交链接和上传文件 |

## 最终核对命令

```powershell
moon check
moon test
moon run cmd/main
moon run examples/basic
moon package
```

## 最终交付链接和文件

| 类型 | 内容 |
| --- | --- |
| GitHub | https://github.com/Han-Wentao/moonbench |
| mooncakes.io | https://mooncakes.io/docs/Han-Wentao/moonbench |
| GitLink | 待同步或创建后填写 |
| 源码包 | `_build/submission/moonbench-source-submission.zip` |
| 发布包 | `_build/publish/Han-Wentao-moonbench-0.2.0.zip` |
| 开发报告 | `docs/development-report.md`，最终可导出 PDF |
