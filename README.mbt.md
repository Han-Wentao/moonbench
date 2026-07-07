# MoonBench

MoonBench 是一个面向 MoonBit 项目的轻量级基准测试与性能报告工具包。它提供可复用的计时、采样统计、多项 benchmark 汇总、Markdown/JSON/CSV 报告输出，以及与历史基线进行对比的能力。

这个包的设计目标是帮助 MoonBit 开发者把性能数据变成稳定、可读、可自动化处理的工程产物：可以放进 README，可以作为 CI artifact，也可以用于版本发布时说明某个优化是否真的带来了收益。

## 安装

```powershell
moon add Han-Wentao/moonbench
```

包页面：

```text
https://mooncakes.io/docs/Han-Wentao/moonbench
```

## 适用场景

- 为 MoonBit 库或应用编写小型 micro-benchmark。
- 在 CI 中生成 Markdown、JSON 或 CSV 性能报告。
- 在 PR 或版本发布中比较当前性能与历史基线。
- 对多项 benchmark 做统一汇总，快速看到最快、最慢和总体趋势。
- 在测试中使用纯状态 `Stopwatch` 验证计时逻辑。

## 核心类型

MoonBench 0.2.0 已从单项 benchmark 工具扩展为完整报告工具链，核心能力包括：

- `SampleStats`、`Stopwatch`、`BenchmarkRunner`：基础采样和计时。
- `BenchmarkSuite`、`ReportMetadata`：多 benchmark 汇总报告。
- `BaselineSet`、`ComparisonReport`：历史基线对比。
- `SampleSeries`、`TrendAnalysis`：趋势、波动、移动平均和噪声分析。
- `ThresholdPolicy`、`GateReport`：CI 性能质量门禁。
- `BenchmarkSnapshot`、`SnapshotDiffReport`：版本快照与回归分析。
- `ScenarioCatalog`、`WorkloadScenario`：标准 benchmark 场景目录。
- `ArtifactBundle`、`SubmissionChecklist`、`ProjectScorecard`：比赛提交和自检辅助。
- `ApiCatalog`、`DocTemplateSet`：公开 API 目录和文档模板。

### SampleStats

`SampleStats` 从微秒采样数组中计算基础统计量：

- `count`
- `min_us`
- `max_us`
- `mean_us`
- `median_us`
- `stddev_us`

示例：

```moonbit
let stats = @moonbench.SampleStats::from_samples([10.0, 4.0, 8.0, 6.0])
println(stats.mean_us)
println(stats.median_us)
```

### Stopwatch

`Stopwatch` 是纯状态秒表，不直接依赖系统时间，因此很适合测试：

```moonbit
let watch = @moonbench.Stopwatch::new().start(100).stop(160).start(200)
println(watch.elapsed(250))
```

支持能力：

- `new`
- `start`
- `stop`
- `reset`
- `elapsed`
- `lap`

### BenchmarkRunner

`BenchmarkRunner` 负责 warmup 和多次迭代采样。

手动提供测量值：

```moonbit
let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=3).run(
  "manual-sample",
  () => 42.0,
)
println(result.to_markdown())
```

直接计时代码块：

```moonbit
let mut value = 0
let result = @moonbench.BenchmarkRunner::new(warmup=1, iterations=4).run_timed(
  "increment",
  () => {
    value = value + 1
    ignore(value)
  },
)
println(result.to_json_with_samples())
```

### BenchmarkSuite

`BenchmarkSuite` 用于汇总多个 benchmark，并生成统一报告：

```moonbit
let runner = @moonbench.BenchmarkRunner::new(warmup=1, iterations=4)
let mut current = 0
let increment = runner.run_timed("increment-example", () => {
  current = current + 1
  ignore(current)
})
let arithmetic = runner.run("manual-sample-example", () => 42.0)

let suite = @moonbench.BenchmarkSuite::new(
  title="Basic MoonBench example",
  package_name="Han-Wentao/moonbench",
  package_version="0.2.0",
  target="wasm-gc",
).add(increment).add(arithmetic)

println(suite.to_markdown())
println(suite.to_csv())
println(suite.to_json())
```

汇总指标包括：

- benchmark 数量
- 总迭代次数
- 平均 mean_us
- fastest benchmark 名称
- slowest benchmark 名称

### BaselineSet 和 ComparisonReport

`BaselineSet` 用于保存历史基线，`ComparisonReport` 用于输出对比结果：

```moonbit
let report = @moonbench.BaselineSet::new()
  .add("increment-example", increment.stats.mean_us)
  .add("manual-sample-example", 40.0)
  .compare_suite(suite, tolerance_pct=5.0)

println(report.to_markdown())
println(report.to_json())
```

状态说明：

- `faster`：当前结果比基线更快，且超过阈值。
- `stable`：当前结果仍在阈值范围内。
- `slower`：当前结果比基线更慢，且超过阈值。
- `missing_baseline`：没有找到同名基线。

### ReportMetadata

报告元信息可以帮助 CI 或评审材料说明报告来源：

```moonbit
let metadata = @moonbench.ReportMetadata::new(
  title="MoonBench CI Report",
  package_name="Han-Wentao/moonbench",
  package_version="0.2.0",
  target="wasm-gc",
  note="Generated in CI",
)
println(metadata.to_markdown())
```

### 名称校验

MoonBench 提供简单的名称校验与规范化工具，避免报告输出被空名称、多行名称或 Markdown 分隔符污染：

```moonbit
let issue = @moonbench.validate_benchmark_name("case-1")
println(issue.ok)
println(@moonbench.normalize_benchmark_name("a|b\nc"))
```

## 输出格式

MoonBench 支持三类常见输出：

- Markdown：适合 README、PR 评论、GitHub Summary 和比赛文档。
- JSON：适合机器读取、后续分析或作为 CI artifact。
- CSV：适合表格软件、脚本处理或横向比较。

单项结果可以使用：

```moonbit
result.to_markdown()
result.to_json()
result.to_json_with_samples()
result.to_csv_row()
```

多项结果可以使用：

```moonbit
suite.to_markdown()
suite.to_json()
suite.to_csv()
```

基线对比可以使用：

```moonbit
comparison_report.to_markdown()
comparison_report.to_json()
```

## 本仓库验证命令

```powershell
moon check
moon test
moon run cmd/main
moon run examples/basic
moon package
```

当前仓库自检结果：

- MoonBit 源码、测试和示例：4813 行。
- 测试数量：55 个。
- demo 输出：suite 报告、baseline comparison、quality gate、scenario catalog、scorecard、reviewer summary、CSV、JSON。

## 设计取舍

MoonBench 不是为了替代大型专业 benchmark 框架，而是优先服务 MoonBit 生态中最常见的轻量级需求：

- API 足够小，学习成本低。
- 输出格式稳定，适合自动化。
- 不强绑定外部服务，易于在本地和 CI 中运行。
- 测试覆盖核心边界，便于后续维护。
- 与 mooncakes.io 发布流程兼容，便于生态复用。

## 参赛说明

MoonBench 是 MoonBit 原生实现，围绕工程基础设施场景提供可复用能力。项目包含可运行示例、自动化测试、CI、MIT License、中文说明文档和 mooncakes.io 发布版本。它可以作为 MoonBit 项目性能评估的基础组件，也可以作为后续更完整 benchmark 工具链的起点。

## License

MIT
