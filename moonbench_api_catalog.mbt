///|
/// Public API symbol metadata for generated documentation.
pub(all) struct ApiSymbol {
  name : String
  kind : String
  package_name : String
  summary : String
  since : String
  stable : Bool
  example : String
} derive(Eq, Debug)

///|
/// Create API symbol metadata.
pub fn ApiSymbol::new(
  name : String,
  kind : String,
  package_name? : String = "moonbench",
  summary? : String = "",
  since? : String = "0.2.0",
  stable? : Bool = true,
  example? : String = "",
) -> ApiSymbol {
  { name, kind, package_name, summary, since, stable, example }
}

///|
/// Render API symbol as Markdown row.
pub fn ApiSymbol::to_markdown_row(self : ApiSymbol) -> String {
  "| `\{escape_markdown(self.name)}` | \{escape_markdown(self.kind)} | \{escape_markdown(self.package_name)} | \{escape_markdown(self.since)} | \{self.stable} | \{escape_markdown(self.summary)} |\n"
}

///|
/// Render API symbol as JSON.
pub fn ApiSymbol::to_json(self : ApiSymbol) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"kind\":\"\{escape_json(self.kind)}\"," +
  "\"package_name\":\"\{escape_json(self.package_name)}\"," +
  "\"summary\":\"\{escape_json(self.summary)}\"," +
  "\"since\":\"\{escape_json(self.since)}\"," +
  "\"stable\":\{self.stable}," +
  "\"example\":\"\{escape_json(self.example)}\"" +
  "}"
}

///|
/// A searchable public API catalog.
pub(all) struct ApiCatalog {
  title : String
  symbols : Array[ApiSymbol]
} derive(Eq, Debug)

///|
/// Create an empty API catalog.
pub fn ApiCatalog::new(
  title? : String = "MoonBench Public API Catalog",
) -> ApiCatalog {
  { title, symbols: [] }
}

///|
/// Append one API symbol.
pub fn ApiCatalog::add(self : ApiCatalog, symbol : ApiSymbol) -> ApiCatalog {
  let symbols = self.symbols.copy()
  symbols.push(symbol)
  { ..self, symbols, }
}

///|
/// Number of symbols.
pub fn ApiCatalog::count(self : ApiCatalog) -> Int {
  self.symbols.length()
}

///|
/// Count symbols by kind.
pub fn ApiCatalog::count_kind(self : ApiCatalog, kind : String) -> Int {
  for symbol in self.symbols; acc = 0 {
    if symbol.kind == kind {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Count stable symbols.
pub fn ApiCatalog::stable_count(self : ApiCatalog) -> Int {
  for symbol in self.symbols; acc = 0 {
    if symbol.stable {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Find a symbol by name.
pub fn ApiCatalog::find(self : ApiCatalog, name : String) -> ApiSymbol {
  for symbol in self.symbols {
    if symbol.name == name {
      return symbol
    }
  }
  ApiSymbol::new("", "")
}

///|
/// Whether a symbol exists.
pub fn ApiCatalog::contains(self : ApiCatalog, name : String) -> Bool {
  self.find(name).name != ""
}

///|
/// Filter symbols by kind.
pub fn ApiCatalog::filter_kind(self : ApiCatalog, kind : String) -> ApiCatalog {
  let mut catalog = ApiCatalog::new(title=self.title + " / " + kind)
  for symbol in self.symbols {
    if symbol.kind == kind {
      catalog = catalog.add(symbol)
    }
  }
  catalog
}

///|
/// Filter symbols introduced since a version string.
pub fn ApiCatalog::filter_since(
  self : ApiCatalog,
  since : String,
) -> ApiCatalog {
  let mut catalog = ApiCatalog::new(title=self.title + " / since " + since)
  for symbol in self.symbols {
    if symbol.since == since {
      catalog = catalog.add(symbol)
    }
  }
  catalog
}

///|
/// Render catalog as Markdown.
pub fn ApiCatalog::to_markdown(self : ApiCatalog) -> String {
  let struct_count = self.count_kind("struct")
  let function_count = self.count_kind("function")
  let mut body = "## \{escape_markdown(self.title)}\n\n"
  body = body + "- Symbols: \{self.count()}\n"
  body = body + "- Stable: \{self.stable_count()}\n"
  body = body + "- Structs: \{struct_count}\n"
  body = body + "- Functions: \{function_count}\n\n"
  body = body + "| name | kind | module | since | stable | summary |\n"
  body = body + "| --- | --- | --- | --- | --- | --- |\n"
  for symbol in self.symbols {
    body = body + symbol.to_markdown_row()
  }
  body
}

///|
/// Render catalog as JSON.
pub fn ApiCatalog::to_json(self : ApiCatalog) -> String {
  let mut body = "{"
  body = body + "\"title\":\"\{escape_json(self.title)}\","
  body = body + "\"count\":\{self.count()},"
  body = body + "\"stable\":\{self.stable_count()},"
  body = body + "\"symbols\":["
  for i in 0..<self.symbols.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.symbols[i].to_json()
  }
  body + "]}"
}

///|
/// Standard public API catalog for MoonBench.
pub fn ApiCatalog::moonbench_standard() -> ApiCatalog {
  ApiCatalog::new()
  .add(
    ApiSymbol::new(
      "SampleStats",
      "struct",
      summary="Statistical summary of benchmark samples",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SampleStats::from_samples",
      "function",
      summary="Build stats from microsecond samples",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SampleStats::to_json",
      "function",
      summary="Render stats as compact JSON",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "Stopwatch",
      "struct",
      summary="Pure stopwatch state",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "Stopwatch::new",
      "function",
      summary="Create a stopped stopwatch",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "Stopwatch::start",
      "function",
      summary="Start stopwatch at timestamp",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "Stopwatch::stop",
      "function",
      summary="Stop stopwatch at timestamp",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "Stopwatch::lap",
      "function",
      summary="Record lap and keep running",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkRunner",
      "struct",
      summary="Warmup and iteration runner",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkRunner::run",
      "function",
      summary="Run manual measurement callback",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkRunner::run_timed",
      "function",
      summary="Measure a code body with monotonic clock",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkResult",
      "struct",
      summary="Single benchmark result",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkResult::to_markdown",
      "function",
      summary="Render result as Markdown table",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkResult::to_json",
      "function",
      summary="Render result as JSON",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkResult::to_csv_row",
      "function",
      summary="Render result as CSV row",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkSuite",
      "struct",
      summary="Multiple benchmark results",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkSuite::to_markdown",
      "function",
      summary="Render suite as Markdown",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkSuite::to_json",
      "function",
      summary="Render suite as JSON",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkSuite::to_csv",
      "function",
      summary="Render suite as CSV",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BaselineSet",
      "struct",
      summary="Named baseline database",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ComparisonReport",
      "struct",
      summary="Suite baseline comparison report",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SampleSeries",
      "struct",
      summary="Named numeric series for trend analysis",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SampleSeries::analyze",
      "function",
      summary="Analyze direction, noise, and risk",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ThresholdPolicy",
      "struct",
      summary="CI threshold policy",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "GateReport",
      "struct",
      summary="Quality gate decisions",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ArtifactBundle",
      "struct",
      summary="Submission artifact metadata",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SubmissionChecklist",
      "struct",
      summary="Contest submission checklist",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ScenarioCatalog",
      "struct",
      summary="Benchmark scenario catalog",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "WorkloadScenario",
      "struct",
      summary="Benchmark workload descriptor",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "StatusBadge",
      "struct",
      summary="README and CI badge metadata",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ReleaseNotes",
      "struct",
      summary="Release note renderer",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ReviewerSummary",
      "struct",
      summary="Contest reviewer summary",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkSnapshot",
      "struct",
      summary="Point-in-time benchmark snapshot",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SnapshotDiffReport",
      "struct",
      summary="Snapshot regression report",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ProjectScorecard",
      "struct",
      summary="Contest readiness rubric",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ApiCatalog",
      "struct",
      summary="Public API documentation catalog",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ReportMetadata",
      "struct",
      summary="Metadata attached to benchmark reports",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ReportMetadata::to_markdown",
      "function",
      summary="Render report metadata as Markdown",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BaselineComparison",
      "struct",
      summary="Single-result baseline comparison",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BaselineComparison::to_markdown",
      "function",
      summary="Render single comparison as Markdown",
      since="0.1.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "NamedComparison",
      "struct",
      summary="Named suite comparison row",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "TrendSummary",
      "struct",
      summary="Aggregated comparison status counts",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ValidationIssue",
      "struct",
      summary="Benchmark name validation result",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "validate_benchmark_name",
      "function",
      summary="Validate benchmark name safety",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "normalize_benchmark_name",
      "function",
      summary="Normalize names for compact reports",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SampleSeries::moving_average",
      "function",
      summary="Compute moving average series",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SampleSeries::normalize_to_first",
      "function",
      summary="Normalize values by first sample",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SampleSeries::stable_ratio",
      "function",
      summary="Measure ratio of stable samples",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ThresholdPolicy::strict",
      "function",
      summary="Build strict CI policy",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ThresholdPolicy::balanced",
      "function",
      summary="Build balanced CI policy",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ThresholdPolicy::relaxed",
      "function",
      summary="Build relaxed local policy",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "GateReport::from_comparison_report",
      "function",
      summary="Build gate report from baselines",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "GateReport::from_suite_samples",
      "function",
      summary="Build gate report from sample quality",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "Artifact",
      "struct",
      summary="Generated artifact descriptor",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ArtifactBundle::moonbench_standard",
      "function",
      summary="Build standard submission artifacts",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "MarkdownDocument",
      "struct",
      summary="Composable Markdown document",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "MarkdownDocument::with_suite",
      "function",
      summary="Append benchmark suite section",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ChecklistItem",
      "struct",
      summary="Submission checklist item",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SubmissionChecklist::moonbench_standard",
      "function",
      summary="Build standard contest checklist",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ScenarioCatalog::moonbench_standard",
      "function",
      summary="Build standard scenario catalog",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "WorkloadScenario::estimated_cost_us",
      "function",
      summary="Estimate scenario cost from metadata",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BadgeSet",
      "struct",
      summary="Collection of status badges",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BadgeSet::moonbench_standard",
      "function",
      summary="Build standard README badges",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ReleaseNotes::moonbench_0_2_0",
      "function",
      summary="Build release notes for 0.2.0",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "GitHubStepSummary",
      "struct",
      summary="GitHub Actions summary document",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "MetricSnapshot",
      "struct",
      summary="Captured metric summary",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkSnapshot::from_suite",
      "function",
      summary="Capture suite metrics as snapshot",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BenchmarkSnapshot::diff",
      "function",
      summary="Compare two benchmark snapshots",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SnapshotDiff",
      "struct",
      summary="Single snapshot diff row",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "SnapshotDiffReport::to_gate_report",
      "function",
      summary="Convert snapshot diff into quality gate",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ScoreItem",
      "struct",
      summary="Rubric score item",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ScoreSection",
      "struct",
      summary="Rubric score section",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ProjectScorecard::moonbench_standard",
      "function",
      summary="Build standard contest scorecard",
      since="0.2.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BaselineSet::set",
      "function",
      summary="Insert or replace a named baseline",
      since="0.3.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BaselineSet::to_text",
      "function",
      summary="Export portable name=mean_us baseline text",
      since="0.3.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BaselineSet::parse_text",
      "function",
      summary="Parse baseline text with diagnostics",
      since="0.3.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "BaselineParseReport",
      "struct",
      summary="Accepted baselines and line-level diagnostics",
      since="0.3.0",
    ),
  )
  .add(
    ApiSymbol::new(
      "ReleaseNotes::moonbench_0_3_0",
      "function",
      summary="Build release notes for 0.3.0",
      since="0.3.0",
    ),
  )
}
