# MoonBench

MoonBench 是一个面向 MoonBit 项目的轻量级基准测试与性能报告工具包。它提供可复用的计时、采样统计、批量 benchmark 汇总、Markdown/JSON/CSV 报告输出，以及与历史基线进行对比的能力，目标是让 MoonBit 库作者可以在 README、CI、Pull Request 或版本发布说明中稳定呈现性能变化。

本项目用于参加 2026 MoonBit 开源生态相关比赛，定位不是迁移已有 benchmark 框架，而是用 MoonBit 原生实现一个小而完整、可测试、可发布、可在生态中复用的工程基础设施包。

## 项目链接

- GitHub 仓库：https://github.com/Han-Wentao/moonbench
- mooncakes.io 包：https://mooncakes.io/docs/Han-Wentao/moonbench
- 发布包名：`Han-Wentao/moonbench`
- 当前版本：`0.3.0`
- License：MIT

## 为什么需要 MoonBench

MoonBit 项目在演进过程中经常需要回答这些问题：

- 某个实现是否真的比旧实现快？
- 多次采样后的平均值、极值、中位数、p90、p95 和标准差是多少？
- PR 中的性能变化是稳定波动，还是明显退化？
- 如何把 benchmark 结果输出成 Markdown 表格，直接放进文档或评审材料？
- 如何把 benchmark 结果输出成 JSON/CSV，作为 CI artifact 或后续分析输入？

MoonBench 的目标是把这些常用步骤做成一个小型工具包，让使用者不必每次重复写计时、采样、统计和报告代码。

## 核心功能

- `Stopwatch`：纯状态秒表，可用于确定性测试，支持 start/stop/lap/reset/elapsed。
- `SampleStats`：从微秒采样中计算 count、min、max、mean、median、p90、p95、stddev。
- `BenchmarkRunner`：支持 warmup 与 iterations，既可接收手动测量值，也可用单调时钟直接计时代码块。
- `BenchmarkResult`：单项 benchmark 结果，可输出 JSON、含 samples 的 JSON、Markdown、CSV 行。
- `BenchmarkSuite`：多项 benchmark 汇总，可生成统一 Markdown/JSON/CSV 报告。
- `ReportMetadata`：为报告附加包名、版本、目标后端和说明。
- `BaselineSet`：按 benchmark 名称维护历史基线，支持 `name=mean_us` 文本导入、导出与重复项覆盖。
- `BaselineParseReport`：跳过无效基线行并返回行号、原文和错误原因，便于在 CI 中定位配置问题。
- `ComparisonReport`：对比当前结果和基线，统计 faster/stable/slower/missing_baseline。
- `SampleSeries` / `TrendAnalysis`：分析样本趋势、波动、移动平均、噪声和回归风险。
- `ThresholdPolicy` / `GateReport`：为 CI 或发布流程提供性能质量门禁。
- `BenchmarkSnapshot` / `SnapshotDiffReport`：记录历史快照并比较版本间性能变化。
- `ScenarioCatalog`：提供标准 benchmark 场景目录，辅助选择测试范围。
- `ArtifactBundle` / `SubmissionChecklist`：描述比赛提交材料和交付物。
- `StatusBadge` / `ReleaseNotes` / `ReviewerSummary`：生成 README、发布说明和评审摘要。
- `ProjectScorecard`：按官方要求和优秀作品标准生成自检评分卡。
- `ApiCatalog` / `DocTemplateSet`：生成公开 API 索引和文档模板。
- 名称校验与转义：减少 Markdown、JSON、CSV 输出时的格式污染。

## 快速开始

安装已发布包：

```powershell
moon add Han-Wentao/moonbench
```

运行本仓库 demo：

```powershell
moon check
moon test
moon run cmd/main
moon run examples/basic
```

## 最小示例

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
  package_version="0.3.0",
).add(increment).add(arithmetic)
println(suite.to_markdown())
```

## 基线对比示例

```moonbit
let report = @moonbench.BaselineSet::new()
  .add("increment-example", increment.stats.mean_us)
  .add("manual-sample-example", 40.0)
  .compare_suite(suite, tolerance_pct=5.0)
println(report.to_markdown())
```

## 基线文件

MoonBench `0.3.0` 支持可提交到仓库的轻量基线格式：

```text
# moonbench.baseline
increment-example=12.5
manual-sample-example=40.0
```

```moonbit
let parsed = @moonbench.BaselineSet::parse_text(baseline_text)
if parsed.is_valid() {
  println(parsed.baselines.compare_suite(suite).to_markdown())
} else {
  println(parsed.issues_to_markdown())
}
```

空行和 `#` 注释会被忽略，名称和值两侧空格会被清理；无效、负数、NaN 和无穷大数值会形成诊断项。同名条目重复出现时，最后一个有效值生效。

状态含义：

- `faster`：当前均值比基线快，且超过容忍阈值。
- `stable`：当前均值在容忍阈值内，可视为稳定波动。
- `slower`：当前均值比基线慢，且超过容忍阈值。
- `missing_baseline`：当前 benchmark 没有找到同名基线。

## 工程质量

项目目前包含：

- 6415 行 MoonBit 源码、测试和示例，处于赛事建议的 4k~10k 规模范围内。
- 59 个 MoonBit 测试，覆盖统计、计时、报告输出、基线读写与诊断、趋势分析、质量门禁、快照、场景目录、评分卡和文档目录。
- GitHub Actions CI，自动执行 `moon check`、`moon test`、demo 和 basic example。
- MIT License。
- 可在 mooncakes.io 安装的正式发布版本。
- 中文 README、包文档、开发报告、项目方案、验收矩阵和提交检查清单。

## 参赛说明

MoonBench 的参赛价值主要体现在 MoonBit 工程基础设施补位：它不是一个一次性 demo，而是一个可以被其他 MoonBit 项目复用的性能报告小工具。项目优先保证 API 简洁、测试可验证、输出格式稳定，再逐步扩展更多报告和 CI 集成能力。

后续可继续增强：

- 继续增加 MAD、置信区间、异常值检测等统计能力。
- 增加 HTML 报告或 GitHub Summary 输出。
- 增加更复杂的真实 MoonBit 算法 benchmark 示例。

## License

MIT
