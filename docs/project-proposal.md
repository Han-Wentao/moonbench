# MoonBench 项目方案

## 基本信息

- 项目名称：MoonBench
- 参赛账号：Han-Wentao
- GitHub 仓库：https://github.com/Han-Wentao/moonbench
- mooncakes.io 包：https://mooncakes.io/docs/Han-Wentao/moonbench
- 项目方向：MoonBit 工程基础设施 / 性能基准测试工具
- 项目类型：MoonBit 原生原创项目
- 开源协议：MIT

## 项目定位

MoonBench 是一个面向 MoonBit 项目的轻量级基准测试与性能报告工具包。它围绕“采样、统计、报告、基线对比”这条常见工程链路提供可复用 API，帮助 MoonBit 开发者把零散的性能测量结果整理成结构化、可阅读、可在 CI 中留存的工程产物。

项目不追求做成庞大的 benchmark 框架，而是优先解决 MoonBit 生态项目当前更常见的问题：如何快速写出可重复的 micro-benchmark，如何生成 Markdown/JSON/CSV 报告，如何与历史基线对比并识别性能退化。

## 背景与价值

MoonBit 生态在扩展过程中会出现越来越多的库、工具和应用。随着项目规模增长，维护者需要用更工程化的方式描述性能变化，而不是只凭主观感受判断“变快了”或“变慢了”。

MoonBench 的价值体现在：

- 为 MoonBit 项目提供可复用的 benchmark 基础组件。
- 将性能数据转成 Markdown，便于放入 README、PR 评论或比赛材料。
- 将性能数据转成 JSON/CSV，便于作为 CI artifact 或后续分析输入。
- 支持历史基线对比，帮助识别优化、稳定波动和性能退化。
- 保持 API 小而清晰，便于生态项目直接引入。

## 核心范围

MoonBench 当前实现以下能力：

- 纯状态秒表 `Stopwatch`，支持 start/stop/lap/reset/elapsed。
- 采样统计 `SampleStats`，计算 count、min、max、mean、median、p90、p95、stddev。
- 基准运行器 `BenchmarkRunner`，支持 warmup 和 iterations。
- 真实代码块计时 `BenchmarkRunner::run_timed`。
- 单项结果 `BenchmarkResult`，支持 Markdown、JSON、含 samples 的 JSON、CSV 行输出。
- 多项汇总 `BenchmarkSuite`，支持统一 Markdown、JSON、CSV 报告。
- 报告元信息 `ReportMetadata`，记录包名、版本、目标后端和说明。
- 基线集合 `BaselineSet`，按 benchmark 名称匹配历史数据。
- 对比报告 `ComparisonReport`，统计 faster/stable/slower/missing_baseline。
- 趋势分析 `SampleSeries` / `TrendAnalysis`，识别样本波动、噪声和回归风险。
- 质量门禁 `ThresholdPolicy` / `GateReport`，支持 CI 和发布前性能守门。
- 快照对比 `BenchmarkSnapshot` / `SnapshotDiffReport`，记录版本间性能变化。
- 场景目录 `ScenarioCatalog` / `WorkloadScenario`，提供标准 benchmark 场景。
- 提交产物 `ArtifactBundle` / `SubmissionChecklist`，管理比赛交付材料。
- 发布与评审辅助 `StatusBadge` / `ReleaseNotes` / `ReviewerSummary`。
- 自检评分卡 `ProjectScorecard`，按官方要求和优秀作品目标核对。
- API 与文档目录 `ApiCatalog` / `DocTemplateSet`，保持公开文档可维护。
- benchmark 名称校验与规范化，降低报告格式污染风险。

## 技术路线

项目采用 MoonBit 标准包结构，核心逻辑集中在库包中，示例和命令行 demo 分离：

- 根包：提供可复用 API。
- `cmd/main`：展示完整报告输出。
- `examples/basic`：提供最小使用示例。
- 测试文件：覆盖公开 API 与关键内部函数。
- GitHub Actions：自动执行检查、测试和示例运行。

实现上优先使用纯数据结构和函数组合，尽量降低外部依赖，使工具可以稳定运行在本地开发和 CI 环境中。

## 交付物

- 公开 GitHub 仓库。
- mooncakes.io 正式发布包。
- 中文 README 和 mooncakes 文档。
- 中文开发报告、项目方案、验收矩阵与提交检查清单。
- 可运行 demo 和 basic example。
- 自动化测试与 CI。
- 4813 行 MoonBit 源码、测试和示例。
- 55 个 MoonBit 测试。
- MIT License。

## 后续规划

- 增加基线文件读写规范。
- 继续增加 MAD、置信区间、异常值检测等统计能力。
- 增加 HTML 或 GitHub Step Summary 报告输出。
- 提供更贴近真实应用的算法 benchmark 示例。
- 支持更细粒度的回归阈值策略和报告过滤。
