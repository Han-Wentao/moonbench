# MoonBench 项目申报书

## 1. 项目名称和 GitHub 仓库地址

项目名称：MoonBench

GitHub 仓库地址：https://github.com/Han-Wentao/moonbench

## 2. 项目简介

MoonBench 是一个面向 MoonBit 项目的基准测试和性能报告工具包。项目主要解决 MoonBit 开发中“如何稳定记录性能数据、如何生成可读报告、如何和历史结果对比”的问题。

它不是大型测试框架，而是一个可以直接发布和复用的小型基础工具包。开发者可以用它运行 micro-benchmark，收集多次采样结果，生成 Markdown、JSON、CSV 报告，并在 CI 或版本发布前判断性能是否出现明显退化。

## 3. 项目方向与适用场景

项目方向：MoonBit 工程基础设施 / 性能基准测试工具。

适用场景：

- MoonBit 库作者需要在 README 或发布说明里展示性能结果。
- 项目维护者需要在 PR 或 CI 中检查性能是否退化。
- 开发者需要对多个实现方案做简单、可复现的 micro-benchmark。
- 参赛项目或教学示例需要展示 MoonBit 工程化实践，包括测试、CI、报告和开源发布。

## 4. 拟实现的核心功能

- 提供 `Stopwatch`，支持可测试的 start、stop、lap、elapsed 计时状态。
- 提供 `SampleStats`，统计 count、min、max、mean、median、p90、p95、stddev。
- 提供 `BenchmarkRunner`，支持 warmup、iterations 和真实代码块计时。
- 提供 `BenchmarkSuite`，把多个 benchmark 汇总成一份报告。
- 支持 Markdown、JSON、CSV 三种输出格式。
- 支持历史基线对比，标记 faster、stable、slower、missing_baseline。
- 支持趋势分析、质量门禁和快照对比，用于 CI 或发布前检查。
- 提供可运行示例、测试、CI、中文 README，并发布到 mooncakes.io。

## 5. 项目来源说明

本项目为原创 MoonBit 项目，不是对已有开源 benchmark 库的直接移植。

项目实现会参考常见 benchmark 工具的设计思路，例如多次采样、预热、统计摘要、基线对比和报告输出，但核心代码、API 设计、文档和示例均围绕 MoonBit 重新实现。

开源协议：MIT。
