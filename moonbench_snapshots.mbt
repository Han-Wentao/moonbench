///|
/// One named metric captured from a benchmark run.
pub(all) struct MetricSnapshot {
  name : String
  mean_us : Double
  median_us : Double
  p90_us : Double
  p95_us : Double
  stddev_us : Double
  samples : Int
} derive(Eq, Debug)

///|
/// Create a metric snapshot.
pub fn MetricSnapshot::new(
  name : String,
  mean_us : Double,
  median_us? : Double = 0.0,
  p90_us? : Double = 0.0,
  p95_us? : Double = 0.0,
  stddev_us? : Double = 0.0,
  samples? : Int = 0,
) -> MetricSnapshot {
  {
    name,
    mean_us,
    median_us,
    p90_us,
    p95_us,
    stddev_us,
    samples: clamp_non_negative(samples),
  }
}

///|
/// Create a metric snapshot from a benchmark result.
pub fn MetricSnapshot::from_result(result : BenchmarkResult) -> MetricSnapshot {
  MetricSnapshot::new(
    result.name,
    result.stats.mean_us,
    median_us=result.stats.median_us,
    p90_us=result.stats.p90_us,
    p95_us=result.stats.p95_us,
    stddev_us=result.stats.stddev_us,
    samples=result.stats.count,
  )
}

///|
/// Render a metric snapshot as baseline entry text.
pub fn MetricSnapshot::to_baseline_line(self : MetricSnapshot) -> String {
  self.name + "=" + "\{self.mean_us}"
}

///|
/// Render a metric snapshot as Markdown row.
pub fn MetricSnapshot::to_markdown_row(self : MetricSnapshot) -> String {
  "| \{escape_markdown(self.name)} | \{self.samples} | \{self.mean_us} | \{self.median_us} | \{self.p90_us} | \{self.p95_us} | \{self.stddev_us} |\n"
}

///|
/// Render a metric snapshot as JSON.
pub fn MetricSnapshot::to_json(self : MetricSnapshot) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"mean_us\":\{self.mean_us}," +
  "\"median_us\":\{self.median_us}," +
  "\"p90_us\":\{self.p90_us}," +
  "\"p95_us\":\{self.p95_us}," +
  "\"stddev_us\":\{self.stddev_us}," +
  "\"samples\":\{self.samples}" +
  "}"
}

///|
/// A benchmark snapshot captured at a point in time.
pub(all) struct BenchmarkSnapshot {
  label : String
  commit : String
  target : String
  created_at : String
  metrics : Array[MetricSnapshot]
} derive(Eq, Debug)

///|
/// Create an empty benchmark snapshot.
pub fn BenchmarkSnapshot::new(
  label? : String = "snapshot",
  commit? : String = "",
  target? : String = "wasm-gc",
  created_at? : String = "",
) -> BenchmarkSnapshot {
  { label, commit, target, created_at, metrics: [] }
}

///|
/// Create a snapshot from a benchmark suite.
pub fn BenchmarkSnapshot::from_suite(
  suite : BenchmarkSuite,
  label? : String = "suite",
  commit? : String = "",
  target? : String = "wasm-gc",
  created_at? : String = "",
) -> BenchmarkSnapshot {
  let mut snapshot = BenchmarkSnapshot::new(
    label~,
    commit~,
    target~,
    created_at~,
  )
  for result in suite.results {
    snapshot = snapshot.add(MetricSnapshot::from_result(result))
  }
  snapshot
}

///|
/// Append one metric snapshot.
pub fn BenchmarkSnapshot::add(
  self : BenchmarkSnapshot,
  metric : MetricSnapshot,
) -> BenchmarkSnapshot {
  let metrics = self.metrics.copy()
  metrics.push(metric)
  { ..self, metrics, }
}

///|
/// Number of metrics.
pub fn BenchmarkSnapshot::count(self : BenchmarkSnapshot) -> Int {
  self.metrics.length()
}

///|
/// Find a metric by name.
pub fn BenchmarkSnapshot::find(
  self : BenchmarkSnapshot,
  name : String,
) -> MetricSnapshot {
  for metric in self.metrics {
    if metric.name == name {
      return metric
    }
  }
  MetricSnapshot::new("", 0.0)
}

///|
/// Whether a metric exists.
pub fn BenchmarkSnapshot::contains(
  self : BenchmarkSnapshot,
  name : String,
) -> Bool {
  self.find(name).name != ""
}

///|
/// Average mean across metrics.
pub fn BenchmarkSnapshot::average_mean_us(self : BenchmarkSnapshot) -> Double {
  if self.metrics.length() == 0 {
    return 0.0
  }
  let total = for metric in self.metrics; acc = 0.0 {
    continue acc + metric.mean_us
  } nobreak {
    acc
  }
  total / self.metrics.length().to_double()
}

///|
/// Convert snapshot to baseline set using mean values.
pub fn BenchmarkSnapshot::to_baseline_set(
  self : BenchmarkSnapshot,
) -> BaselineSet {
  let mut baselines = BaselineSet::new()
  for metric in self.metrics {
    baselines = baselines.add(metric.name, metric.mean_us)
  }
  baselines
}

///|
/// Render snapshot as a simple baseline text document.
pub fn BenchmarkSnapshot::to_baseline_text(self : BenchmarkSnapshot) -> String {
  let mut body = "# MoonBench baseline: " + self.label + "\n"
  if self.commit != "" {
    body = body + "# commit=" + self.commit + "\n"
  }
  if self.target != "" {
    body = body + "# target=" + self.target + "\n"
  }
  for metric in self.metrics {
    body = body + metric.to_baseline_line() + "\n"
  }
  body
}

///|
/// Render snapshot as Markdown.
pub fn BenchmarkSnapshot::to_markdown(self : BenchmarkSnapshot) -> String {
  let mut body = "## Snapshot \{escape_markdown(self.label)}\n\n"
  body = body + "- Commit: `\{escape_markdown(self.commit)}`\n"
  body = body + "- Target: `\{escape_markdown(self.target)}`\n"
  body = body + "- Created at: \{escape_markdown(self.created_at)}\n"
  body = body + "- Metrics: \{self.count()}\n"
  body = body + "- Average mean us: \{self.average_mean_us()}\n\n"
  body = body +
    "| name | samples | mean_us | median_us | p90_us | p95_us | stddev_us |\n"
  body = body + "| --- | ---: | ---: | ---: | ---: | ---: | ---: |\n"
  for metric in self.metrics {
    body = body + metric.to_markdown_row()
  }
  body
}

///|
/// Render snapshot as JSON.
pub fn BenchmarkSnapshot::to_json(self : BenchmarkSnapshot) -> String {
  let mut body = "{"
  body = body + "\"label\":\"\{escape_json(self.label)}\","
  body = body + "\"commit\":\"\{escape_json(self.commit)}\","
  body = body + "\"target\":\"\{escape_json(self.target)}\","
  body = body + "\"created_at\":\"\{escape_json(self.created_at)}\","
  body = body + "\"count\":\{self.count()},"
  body = body + "\"average_mean_us\":\{self.average_mean_us()},"
  body = body + "\"metrics\":["
  for i in 0..<self.metrics.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.metrics[i].to_json()
  }
  body + "]}"
}

///|
/// One comparison between two metric snapshots.
pub(all) struct SnapshotDiff {
  name : String
  before_found : Bool
  after_found : Bool
  before_mean_us : Double
  after_mean_us : Double
  delta_us : Double
  delta_pct : Double
  status : String
} derive(Eq, Debug)

///|
/// Create a snapshot diff row.
pub fn SnapshotDiff::new(
  name : String,
  before_found : Bool,
  after_found : Bool,
  before_mean_us : Double,
  after_mean_us : Double,
  tolerance_pct? : Double = 5.0,
) -> SnapshotDiff {
  let delta_us = after_mean_us - before_mean_us
  let delta_pct = if before_mean_us == 0.0 {
    0.0
  } else {
    delta_us / before_mean_us * 100.0
  }
  let status = if !before_found {
    "added"
  } else if !after_found {
    "removed"
  } else if delta_pct > tolerance_pct.abs() {
    "slower"
  } else if delta_pct < 0.0 - tolerance_pct.abs() {
    "faster"
  } else {
    "stable"
  }
  {
    name,
    before_found,
    after_found,
    before_mean_us,
    after_mean_us,
    delta_us,
    delta_pct,
    status,
  }
}

///|
/// Render diff row as Markdown.
pub fn SnapshotDiff::to_markdown_row(self : SnapshotDiff) -> String {
  "| \{escape_markdown(self.name)} | \{self.before_found} | \{self.after_found} | \{self.before_mean_us} | \{self.after_mean_us} | \{self.delta_us} | \{self.delta_pct} | \{self.status} |\n"
}

///|
/// Render diff row as JSON.
pub fn SnapshotDiff::to_json(self : SnapshotDiff) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"before_found\":\{self.before_found}," +
  "\"after_found\":\{self.after_found}," +
  "\"before_mean_us\":\{self.before_mean_us}," +
  "\"after_mean_us\":\{self.after_mean_us}," +
  "\"delta_us\":\{self.delta_us}," +
  "\"delta_pct\":\{self.delta_pct}," +
  "\"status\":\"\{escape_json(self.status)}\"" +
  "}"
}

///|
/// Full diff between two snapshots.
pub(all) struct SnapshotDiffReport {
  before_label : String
  after_label : String
  diffs : Array[SnapshotDiff]
} derive(Eq, Debug)

///|
/// Compare two snapshots.
pub fn BenchmarkSnapshot::diff(
  self : BenchmarkSnapshot,
  after : BenchmarkSnapshot,
  tolerance_pct? : Double = 5.0,
) -> SnapshotDiffReport {
  let diffs : Array[SnapshotDiff] = []
  for before_metric in self.metrics {
    let after_metric = after.find(before_metric.name)
    diffs.push(
      SnapshotDiff::new(
        before_metric.name,
        true,
        after_metric.name != "",
        before_metric.mean_us,
        after_metric.mean_us,
        tolerance_pct~,
      ),
    )
  }
  for after_metric in after.metrics {
    if !self.contains(after_metric.name) {
      diffs.push(
        SnapshotDiff::new(
          after_metric.name,
          false,
          true,
          0.0,
          after_metric.mean_us,
          tolerance_pct~,
        ),
      )
    }
  }
  { before_label: self.label, after_label: after.label, diffs }
}

///|
/// Number of diff rows.
pub fn SnapshotDiffReport::count(self : SnapshotDiffReport) -> Int {
  self.diffs.length()
}

///|
/// Count rows by status.
pub fn SnapshotDiffReport::count_status(
  self : SnapshotDiffReport,
  status : String,
) -> Int {
  for diff in self.diffs; acc = 0 {
    if diff.status == status {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Whether the diff has any slower rows.
pub fn SnapshotDiffReport::has_regression(self : SnapshotDiffReport) -> Bool {
  self.count_status("slower") > 0
}

///|
/// Whether the diff only contains stable or faster matched rows.
pub fn SnapshotDiffReport::is_clean(self : SnapshotDiffReport) -> Bool {
  for diff in self.diffs {
    if diff.status == "slower" || diff.status == "removed" {
      return false
    }
  }
  true
}

///|
/// Render snapshot diff as Markdown.
pub fn SnapshotDiffReport::to_markdown(self : SnapshotDiffReport) -> String {
  let faster_count = self.count_status("faster")
  let stable_count = self.count_status("stable")
  let slower_count = self.count_status("slower")
  let added_count = self.count_status("added")
  let removed_count = self.count_status("removed")
  let mut body = "## Snapshot Diff\n\n"
  body = body + "- Before: `\{escape_markdown(self.before_label)}`\n"
  body = body + "- After: `\{escape_markdown(self.after_label)}`\n"
  body = body + "- Rows: \{self.count()}\n"
  body = body + "- Faster: \{faster_count}\n"
  body = body + "- Stable: \{stable_count}\n"
  body = body + "- Slower: \{slower_count}\n"
  body = body + "- Added: \{added_count}\n"
  body = body + "- Removed: \{removed_count}\n\n"
  body = body +
    "| name | before_found | after_found | before_mean_us | after_mean_us | delta_us | delta_pct | status |\n"
  body = body + "| --- | --- | --- | ---: | ---: | ---: | ---: | --- |\n"
  for diff in self.diffs {
    body = body + diff.to_markdown_row()
  }
  body
}

///|
/// Render snapshot diff as JSON.
pub fn SnapshotDiffReport::to_json(self : SnapshotDiffReport) -> String {
  let mut body = "{"
  body = body + "\"before_label\":\"\{escape_json(self.before_label)}\","
  body = body + "\"after_label\":\"\{escape_json(self.after_label)}\","
  body = body + "\"count\":\{self.count()},"
  body = body + "\"has_regression\":\{self.has_regression()},"
  body = body + "\"clean\":\{self.is_clean()},"
  body = body + "\"diffs\":["
  for i in 0..<self.diffs.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.diffs[i].to_json()
  }
  body + "]}"
}

///|
/// Convert snapshot diff into a gate report.
pub fn SnapshotDiffReport::to_gate_report(
  self : SnapshotDiffReport,
  policy? : ThresholdPolicy = ThresholdPolicy::balanced(),
) -> GateReport {
  let mut gate = GateReport::new(policy~)
  for diff in self.diffs {
    let passed = diff.status != "slower" && diff.status != "removed"
    let severity = if passed { "info" } else { "error" }
    let reason = if diff.status == "added" {
      "new benchmark added"
    } else if diff.status == "removed" {
      "benchmark was removed"
    } else if diff.status == "slower" {
      "snapshot diff indicates regression"
    } else {
      "snapshot diff accepted"
    }
    gate = gate.add(
      GateDecision::new(
        diff.name,
        passed,
        diff.status,
        reason,
        severity~,
        delta_pct=diff.delta_pct,
      ),
    )
  }
  gate
}
