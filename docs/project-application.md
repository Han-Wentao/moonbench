# MoonBench 项目申报书

## 基本信息

- 项目名称：MoonBench：MoonBit 基准测试与性能报告工具包
- 参赛者：hanwt
- 联系方式：13656230375
- GitHub 仓库链接：https://github.com/Han-Wentao/moonbench
- 项目方向：MoonBit 工程基础设施 / 性能基准测试工具
- 是否为移植项目：否，原创项目

## 项目简介

MoonBench 计划实现一个面向 MoonBit 项目的轻量级基准测试与性能报告工具包，帮助 MoonBit 开发者在项目开发、PR 检查、版本发布和文档展示中稳定记录性能数据。项目重点解决 micro-benchmark 编写分散、统计结果不统一、报告格式不稳定、历史基线对比不方便等问题。

项目会提供计时、采样、统计、报告输出、历史基线对比、趋势分析和质量门禁等能力。使用者可以通过 MoonBit API 运行 benchmark，生成 Markdown、JSON、CSV 报告，并在 CI 或发布前判断性能变化是否属于正常波动或明显退化。

## 核心功能范围

- 提供 `Stopwatch` 秒表状态，支持 start、stop、lap、reset、elapsed 等基础计时操作；
- 提供 `SampleStats` 采样统计，支持 count、min、max、mean、median、p90、p95、stddev 等指标；
- 提供 `BenchmarkRunner`，支持 warmup、iterations 和真实代码块计时；
- 提供 `BenchmarkResult` 和 `BenchmarkSuite`，支持单项结果和多项 benchmark 汇总；
- 支持 Markdown、JSON、CSV 三种报告输出格式，便于接入 README、CI artifact 和发布说明；
- 支持历史基线对比，标记 faster、stable、slower、missing_baseline 等状态；
- 提供 `SampleSeries`、`TrendAnalysis` 和 `GateReport`，用于趋势分析、噪声判断和性能质量门禁；
- 提供 `BenchmarkSnapshot` 和 `SnapshotDiffReport`，用于记录历史快照并比较不同版本之间的性能变化；
- 提供标准 benchmark 场景目录、提交材料清单、评审摘要和自检评分卡，方便参赛验收和后续维护；
- 提供中文 README、可运行示例、MoonBit 测试、GitHub Actions CI，并发布到 mooncakes.io。

## 移植或参考说明

- 原项目名称：无
- 原项目链接：无
- 原项目许可证：无
- 本项目许可证：MIT

本项目为 MoonBit 原创项目，不是对某个已有 benchmark 库的直接移植。项目会参考常见性能测试工具中的通用工程思路，例如预热、多次采样、统计摘要、报告输出和基线对比，但核心代码、API 结构、文档和示例均围绕 MoonBit 生态重新设计和实现。
