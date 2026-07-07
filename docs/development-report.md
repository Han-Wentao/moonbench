# MoonBench 开发报告

## 一、项目概述

MoonBench 是一个用 MoonBit 原生实现的轻量级基准测试与性能报告工具包。项目面向 MoonBit 开源生态中的库作者和工具作者，提供从计时、采样、统计到报告输出、基线对比的一组基础能力。

本项目的参赛定位是“工程基础设施补位”：它不是一个只展示语法的 demo，而是一个可以发布到 mooncakes.io、被其他 MoonBit 项目引入、并在 CI 或文档中复用的工具包。

项目链接：

- GitHub：https://github.com/Han-Wentao/moonbench
- mooncakes.io：https://mooncakes.io/docs/Han-Wentao/moonbench
- 包名：`Han-Wentao/moonbench`
- 当前版本：`0.2.0`

## 二、需求分析

在 MoonBit 项目开发中，性能相关工作通常会遇到以下问题：

1. 临时计时代码难以复用。
2. 单次运行结果波动较大，需要多次采样和统计摘要。
3. 性能结果需要进入 README、PR 评论、CI artifact 或发布说明。
4. 当前结果需要与历史基线对比，判断是优化、稳定还是退化。
5. 输出格式需要兼顾人类阅读和机器处理。

MoonBench 围绕这些问题提供一个小型闭环：运行 benchmark，生成结果，组织 suite，输出报告，对比 baseline。

## 三、已实现功能

### 1. SampleStats

`SampleStats` 用于从微秒采样数组中计算统计指标：

- 样本数 `count`
- 最小值 `min_us`
- 最大值 `max_us`
- 平均值 `mean_us`
- 中位数 `median_us`
- p90 分位数 `p90_us`
- p95 分位数 `p95_us`
- 样本标准差 `stddev_us`

### 2. Stopwatch

`Stopwatch` 是纯状态秒表，所有操作都通过传入 `now_us` 完成。这种设计让秒表逻辑可以被确定性测试，不依赖真实系统时间。

### 3. BenchmarkRunner

`BenchmarkRunner` 负责组织 benchmark 运行，支持 warmup、iterations、手动采样和真实代码块计时。

### 4. BenchmarkResult

`BenchmarkResult` 保存单项 benchmark 结果，包括名称、warmup、iterations、原始 samples 和统计摘要，支持 Markdown、JSON、含 samples 的 JSON、CSV 行输出，以及单项基线对比。

### 5. BenchmarkSuite

`BenchmarkSuite` 用于把多个 benchmark 组织成一个统一报告。它可以统计 benchmark 数量、总迭代次数、平均 mean_us、fastest benchmark 和 slowest benchmark，并支持 Markdown、JSON、CSV 输出。

### 6. ReportMetadata

`ReportMetadata` 用于给报告添加上下文信息，例如标题、包名、版本、目标后端和备注。这让输出更适合提交给评审、放进 CI 或用于版本记录。

### 7. BaselineSet 与 ComparisonReport

`BaselineSet` 用于保存历史基线值，`ComparisonReport` 用于对比当前结果和基线。对比状态包括 `faster`、`stable`、`slower`、`missing_baseline`。

### 8. 名称校验与格式转义

MoonBench 对 JSON、Markdown、CSV 输出做了必要转义，并提供 benchmark 名称校验与规范化函数，减少报告格式被特殊字符破坏的风险。

### 9. 趋势分析与质量门禁

`SampleSeries`、`TrendAnalysis`、`ThresholdPolicy` 和 `GateReport` 用于分析样本波动、移动平均、稳定比例、噪声风险，并把结果转化为 CI 可读的质量门禁报告。

### 10. 快照与回归分析

`BenchmarkSnapshot` 和 `SnapshotDiffReport` 可以记录某次 benchmark 的指标快照，并比较两个版本之间的性能变化，识别 faster、stable、slower、added、removed。

### 11. 场景目录、提交产物和评分卡

`ScenarioCatalog` 提供标准 benchmark 场景目录；`ArtifactBundle` 和 `SubmissionChecklist` 描述提交材料；`ProjectScorecard` 按官方要求和优秀作品标准生成自检评分卡。

### 12. API 目录和文档模板

`ApiCatalog` 和 `DocTemplateSet` 用于生成公开 API 索引和文档模板，帮助维护 README、包文档和评审材料的一致性。

## 四、工程实现

项目采用 MoonBit 标准工程布局：

```text
moonbench/
  moon.mod
  moon.pkg
  moonbench.mbt
  moonbench_test.mbt
  moonbench_wbtest.mbt
  cmd/main/main.mbt
  examples/basic/main.mbt
  docs/
  .github/workflows/ci.yml
```

核心库逻辑集中在 `moonbench.mbt`，示例代码与测试代码分离，便于评审直接阅读和运行。

## 五、测试与验证

当前测试覆盖：

- 空样本与非空样本统计。
- 奇偶样本中位数。
- p90/p95 分位数。
- 秒表多次 start/stop 和 lap。
- runner 的 warmup 与 iterations 行为。
- 参数边界值修正。
- Markdown/JSON/CSV 输出。
- 基线对比状态。
- suite 汇总统计。
- 缺失基线处理。
- 名称校验与规范化。
- 趋势分析、移动平均、质量门禁。
- artifact bundle、submission checklist、release notes、reviewer summary。
- scenario catalog、snapshot diff、project scorecard、API catalog、doc template。

当前规模和测试：

- MoonBit 源码、测试和示例总计：4813 行。
- MoonBit 测试：55 个，全部通过。

复现命令：

```powershell
moon check
moon test
moon run cmd/main
moon run examples/basic
moon package
```

## 六、CI 与发布

项目配置了 GitHub Actions，自动执行 MoonBit 工具链安装、检查、测试和示例运行。

项目已发布到 mooncakes.io：

```text
https://mooncakes.io/docs/Han-Wentao/moonbench
```

## 七、项目亮点

1. 面向真实工程场景，而不是一次性演示。
2. 同时服务人类阅读和机器处理，支持 Markdown/JSON/CSV。
3. 支持多 benchmark 汇总和基线对比，适合 CI 和 PR 场景。
4. 提供 p90/p95 等比单纯平均值更有解释力的统计指标。
5. 支持趋势分析、质量门禁、快照对比和评审摘要。
6. 使用纯状态设计提升可测试性。
7. 已完成开源项目基础设施：README、License、CI、测试、发布包。

## 八、不足与后续计划

当前项目仍然有继续增强空间：

- 暂未提供基线文件自动读写。
- 暂未提供 HTML 报告。
- 示例 benchmark 仍以轻量演示为主，后续可增加更真实的算法场景。

计划后续补充：

- MAD、置信区间、异常值检测等统计指标。
- 基线 JSON 文件约定。
- GitHub Step Summary 报告输出。
- 更复杂的真实 benchmark 示例。
- 更细的性能退化策略。

## 九、总结

MoonBench 已经形成一个完整的 MoonBit 工具包闭环：可安装、可运行、可测试、可发布、可生成报告、可进行基线对比。它能够作为 MoonBit 生态中的小型工程基础设施，为其他项目提供性能结果记录和评估能力。
