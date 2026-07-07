/// A statistical summary of benchmark samples measured in microseconds.
pub(all) struct SampleStats {
  count : Int
  min_us : Double
  max_us : Double
  mean_us : Double
  median_us : Double
  p90_us : Double
  p95_us : Double
  stddev_us : Double
} derive(Eq, Debug)

/// Create a summary from an array of samples measured in microseconds.
pub fn SampleStats::from_samples(samples : Array[Double]) -> SampleStats {
  if samples.length() == 0 {
    return {
      count: 0,
      min_us: 0.0,
      max_us: 0.0,
      mean_us: 0.0,
      median_us: 0.0,
      p90_us: 0.0,
      p95_us: 0.0,
      stddev_us: 0.0,
    }
  }
  let sorted = samples.copy()
  sorted.sort()
  let count = sorted.length()
  let sum = for sample in sorted; acc = 0.0 {
    continue acc + sample
  } nobreak {
    acc
  }
  let mean = sum / count.to_double()
  let variance = if count < 2 {
    0.0
  } else {
    for sample in sorted; acc = 0.0 {
      let delta = sample - mean
      continue acc + delta * delta
    } nobreak {
      acc / (count - 1).to_double()
    }
  }
  {
    count,
    min_us: sorted[0],
    max_us: sorted[count - 1],
    mean_us: mean,
    median_us: median(sorted),
    p90_us: nearest_rank(sorted, 90),
    p95_us: nearest_rank(sorted, 95),
    stddev_us: variance.sqrt(),
  }
}

fn median(sorted : Array[Double]) -> Double {
  let count = sorted.length()
  let middle = count / 2
  if count % 2 == 1 {
    sorted[middle]
  } else {
    (sorted[middle - 1] + sorted[middle]) / 2.0
  }
}

fn nearest_rank(sorted : Array[Double], percentile : Int) -> Double {
  let count = sorted.length()
  if count == 0 {
    return 0.0
  }
  let mut index = ((count * percentile + 99) / 100) - 1
  if index < 0 {
    index = 0
  }
  if index >= count {
    index = count - 1
  }
  sorted[index]
}

/// A pure stopwatch state measured in microseconds.
pub(all) struct Stopwatch {
  elapsed_us : Int
  started_at_us : Int
  running : Bool
} derive(Eq, Debug)

/// Create a stopped stopwatch with no elapsed time.
pub fn Stopwatch::new() -> Stopwatch {
  { elapsed_us: 0, started_at_us: 0, running: false }
}

/// Start the stopwatch at `now_us`.
pub fn Stopwatch::start(self : Stopwatch, now_us : Int) -> Stopwatch {
  if self.running {
    self
  } else {
    { ..self, started_at_us: now_us, running: true }
  }
}

/// Stop the stopwatch at `now_us`.
pub fn Stopwatch::stop(self : Stopwatch, now_us : Int) -> Stopwatch {
  if self.running {
    {
      elapsed_us: self.elapsed_us + positive_delta(now_us, self.started_at_us),
      started_at_us: self.started_at_us,
      running: false,
    }
  } else {
    self
  }
}

/// Reset elapsed time and return to the stopped state.
pub fn Stopwatch::reset(_self : Stopwatch) -> Stopwatch {
  Stopwatch::new()
}

/// Return elapsed microseconds at `now_us` without changing the state.
pub fn Stopwatch::elapsed(self : Stopwatch, now_us : Int) -> Int {
  if self.running {
    self.elapsed_us + positive_delta(now_us, self.started_at_us)
  } else {
    self.elapsed_us
  }
}

/// Record a lap at `now_us`, returning the lap duration and updated stopwatch.
pub fn Stopwatch::lap(self : Stopwatch, now_us : Int) -> (Int, Stopwatch) {
  if self.running {
    let lap_us = positive_delta(now_us, self.started_at_us)
    (
      lap_us,
      {
        elapsed_us: self.elapsed_us + lap_us,
        started_at_us: now_us,
        running: true,
      },
    )
  } else {
    (0, self)
  }
}

fn positive_delta(now_us : Int, then_us : Int) -> Int {
  if now_us > then_us {
    now_us - then_us
  } else {
    0
  }
}

/// A named benchmark result.
pub(all) struct BenchmarkResult {
  name : String
  warmup : Int
  iterations : Int
  samples_us : Array[Double]
  stats : SampleStats
} derive(Eq, Debug)

/// Configuration for repeatable benchmark runs.
pub(all) struct BenchmarkRunner {
  warmup : Int
  iterations : Int
} derive(Eq, Debug)

/// Create a benchmark runner.
pub fn BenchmarkRunner::new(warmup? : Int = 1, iterations? : Int = 10) -> BenchmarkRunner {
  {
    warmup: clamp_non_negative(warmup),
    iterations: clamp_positive(iterations),
  }
}

/// Run a measurement function and summarize the returned microsecond samples.
pub fn BenchmarkRunner::run(
  self : BenchmarkRunner,
  name : String,
  measure : () -> Double,
) -> BenchmarkResult {
  for _ in 0..<self.warmup {
    ignore(measure())
  }
  let samples : Array[Double] = []
  for _ in 0..<self.iterations {
    samples.push(measure())
  }
  let stats = SampleStats::from_samples(samples)
  { name, warmup: self.warmup, iterations: self.iterations, samples_us: samples, stats }
}

/// Run and time a benchmark body with the monotonic clock.
pub fn BenchmarkRunner::run_timed(
  self : BenchmarkRunner,
  name : String,
  body : () -> Unit,
) -> BenchmarkResult {
  self.run(name, () => {
    let started = @bench.monotonic_clock_start()
    body()
    @bench.monotonic_clock_end(started)
  })
}

fn clamp_non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

fn clamp_positive(value : Int) -> Int {
  if value < 1 {
    1
  } else {
    value
  }
}

/// Render a benchmark result as compact JSON.
pub fn BenchmarkResult::to_json(self : BenchmarkResult) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"warmup\":\{self.warmup}," +
  "\"iterations\":\{self.iterations}," +
  "\"stats\":\{self.stats.to_json()}" +
  "}"
}

/// Render a benchmark result as a Markdown table.
pub fn BenchmarkResult::to_markdown(self : BenchmarkResult) -> String {
  "| name | count | min_us | max_us | mean_us | median_us | p90_us | p95_us | stddev_us |\n" +
  "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n" +
  self.to_markdown_row()
}

/// Render one Markdown table row for a benchmark result.
pub fn BenchmarkResult::to_markdown_row(self : BenchmarkResult) -> String {
  "| \{escape_markdown(self.name)} | \{self.stats.count} | \{self.stats.min_us} | \{self.stats.max_us} | \{self.stats.mean_us} | \{self.stats.median_us} | \{self.stats.p90_us} | \{self.stats.p95_us} | \{self.stats.stddev_us} |\n"
}

/// Render sample statistics as JSON.
pub fn SampleStats::to_json(self : SampleStats) -> String {
  "{" +
  "\"count\":\{self.count}," +
  "\"min_us\":\{self.min_us}," +
  "\"max_us\":\{self.max_us}," +
  "\"mean_us\":\{self.mean_us}," +
  "\"median_us\":\{self.median_us}," +
  "\"p90_us\":\{self.p90_us}," +
  "\"p95_us\":\{self.p95_us}," +
  "\"stddev_us\":\{self.stddev_us}" +
  "}"
}

fn escape_json(value : String) -> String {
  value.replace(old="\\", new="\\\\").replace(old="\"", new="\\\"")
}

fn escape_markdown(value : String) -> String {
  value.replace(old="|", new="\\|")
}

/// Comparison between a current benchmark and a baseline mean.
pub(all) struct BaselineComparison {
  name : String
  baseline_mean_us : Double
  current_mean_us : Double
  delta_pct : Double
  status : String
} derive(Eq, Debug)

/// Compare a result with a baseline mean in microseconds.
pub fn BenchmarkResult::compare_baseline(
  self : BenchmarkResult,
  baseline_mean_us : Double,
  tolerance_pct? : Double = 5.0,
) -> BaselineComparison {
  let delta_pct = if baseline_mean_us == 0.0 {
    0.0
  } else {
    (self.stats.mean_us - baseline_mean_us) / baseline_mean_us * 100.0
  }
  let limit = tolerance_pct.abs()
  let status = if delta_pct > limit {
    "slower"
  } else if delta_pct < 0.0 - limit {
    "faster"
  } else {
    "stable"
  }
  {
    name: self.name,
    baseline_mean_us,
    current_mean_us: self.stats.mean_us,
    delta_pct,
    status,
  }
}

/// Render a baseline comparison as Markdown.
pub fn BaselineComparison::to_markdown(self : BaselineComparison) -> String {
  "| name | baseline_mean_us | current_mean_us | delta_pct | status |\n" +
  "| --- | ---: | ---: | ---: | --- |\n" +
  "| \{escape_markdown(self.name)} | \{self.baseline_mean_us} | \{self.current_mean_us} | \{self.delta_pct} | \{self.status} |\n"
}

/// Human-readable metadata attached to a benchmark report.
pub(all) struct ReportMetadata {
  title : String
  package_name : String
  package_version : String
  target : String
  note : String
} derive(Eq, Debug)

/// Create report metadata with practical defaults.
pub fn ReportMetadata::new(
  title? : String = "MoonBench Report",
  package_name? : String = "",
  package_version? : String = "",
  target? : String = "",
  note? : String = "",
) -> ReportMetadata {
  { title, package_name, package_version, target, note }
}

/// Render metadata as a small Markdown block.
pub fn ReportMetadata::to_markdown(self : ReportMetadata) -> String {
  let mut body = "## \{escape_markdown(self.title)}\n\n"
  if self.package_name != "" {
    body = body + "- Package: `\{escape_markdown(self.package_name)}`\n"
  }
  if self.package_version != "" {
    body = body + "- Version: `\{escape_markdown(self.package_version)}`\n"
  }
  if self.target != "" {
    body = body + "- Target: `\{escape_markdown(self.target)}`\n"
  }
  if self.note != "" {
    body = body + "- Note: \{escape_markdown(self.note)}\n"
  }
  body + "\n"
}

/// Render metadata as compact JSON.
pub fn ReportMetadata::to_json(self : ReportMetadata) -> String {
  "{" +
  "\"title\":\"\{escape_json(self.title)}\"," +
  "\"package_name\":\"\{escape_json(self.package_name)}\"," +
  "\"package_version\":\"\{escape_json(self.package_version)}\"," +
  "\"target\":\"\{escape_json(self.target)}\"," +
  "\"note\":\"\{escape_json(self.note)}\"" +
  "}"
}

/// A collection of benchmark results that can be rendered as one report.
pub(all) struct BenchmarkSuite {
  metadata : ReportMetadata
  results : Array[BenchmarkResult]
} derive(Eq, Debug)

/// Create an empty benchmark suite.
pub fn BenchmarkSuite::new(
  title? : String = "MoonBench Report",
  package_name? : String = "",
  package_version? : String = "",
  target? : String = "",
  note? : String = "",
) -> BenchmarkSuite {
  {
    metadata: ReportMetadata::new(
      title=title,
      package_name=package_name,
      package_version=package_version,
      target=target,
      note=note,
    ),
    results: [],
  }
}

/// Return a new suite with one result appended.
pub fn BenchmarkSuite::add(self : BenchmarkSuite, result : BenchmarkResult) -> BenchmarkSuite {
  let results = self.results.copy()
  results.push(result)
  { ..self, results }
}

/// Return a new suite with another suite appended.
pub fn BenchmarkSuite::append(self : BenchmarkSuite, other : BenchmarkSuite) -> BenchmarkSuite {
  let results = self.results.copy()
  for result in other.results {
    results.push(result)
  }
  { ..self, results }
}

/// Count benchmark results in the suite.
pub fn BenchmarkSuite::count(self : BenchmarkSuite) -> Int {
  self.results.length()
}

/// Count all measured iterations in the suite.
pub fn BenchmarkSuite::total_iterations(self : BenchmarkSuite) -> Int {
  for result in self.results; acc = 0 {
    continue acc + result.iterations
  } nobreak {
    acc
  }
}

/// Average the per-result mean values in the suite.
pub fn BenchmarkSuite::average_mean_us(self : BenchmarkSuite) -> Double {
  if self.results.length() == 0 {
    return 0.0
  }
  let total = for result in self.results; acc = 0.0 {
    continue acc + result.stats.mean_us
  } nobreak {
    acc
  }
  total / self.results.length().to_double()
}

/// Name of the result with the lowest mean time.
pub fn BenchmarkSuite::fastest_name(self : BenchmarkSuite) -> String {
  if self.results.length() == 0 {
    return ""
  }
  let mut best_name = self.results[0].name
  let mut best_mean = self.results[0].stats.mean_us
  for result in self.results {
    if result.stats.mean_us < best_mean {
      best_name = result.name
      best_mean = result.stats.mean_us
    }
  }
  best_name
}

/// Name of the result with the highest mean time.
pub fn BenchmarkSuite::slowest_name(self : BenchmarkSuite) -> String {
  if self.results.length() == 0 {
    return ""
  }
  let mut worst_name = self.results[0].name
  let mut worst_mean = self.results[0].stats.mean_us
  for result in self.results {
    if result.stats.mean_us > worst_mean {
      worst_name = result.name
      worst_mean = result.stats.mean_us
    }
  }
  worst_name
}

/// Render the suite as Markdown with one combined table.
pub fn BenchmarkSuite::to_markdown(self : BenchmarkSuite) -> String {
  let mut body = self.metadata.to_markdown()
  body = body + "- Benchmarks: \{self.count()}\n"
  body = body + "- Total iterations: \{self.total_iterations()}\n"
  body = body + "- Average mean us: \{self.average_mean_us()}\n"
  if self.count() > 0 {
    body = body + "- Fastest: `\{escape_markdown(self.fastest_name())}`\n"
    body = body + "- Slowest: `\{escape_markdown(self.slowest_name())}`\n"
  }
  body = body + "\n"
  body = body + "| name | count | min_us | max_us | mean_us | median_us | p90_us | p95_us | stddev_us |\n"
  body = body + "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n"
  for result in self.results {
    body = body + result.to_markdown_row()
  }
  body
}

/// Render the suite as compact JSON.
pub fn BenchmarkSuite::to_json(self : BenchmarkSuite) -> String {
  let mut body = "{"
  body = body + "\"metadata\":\{self.metadata.to_json()},"
  body = body + "\"summary\":{"
  body = body + "\"benchmarks\":\{self.count()},"
  body = body + "\"total_iterations\":\{self.total_iterations()},"
  body = body + "\"average_mean_us\":\{self.average_mean_us()},"
  body = body + "\"fastest\":\"\{escape_json(self.fastest_name())}\","
  body = body + "\"slowest\":\"\{escape_json(self.slowest_name())}\""
  body = body + "},"
  body = body + "\"results\":["
  for i in 0..<self.results.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.results[i].to_json_with_samples()
  }
  body + "]}"
}

/// Render the suite as CSV for spreadsheet or CI artifact consumption.
pub fn BenchmarkSuite::to_csv(self : BenchmarkSuite) -> String {
  let mut body = "name,warmup,iterations,count,min_us,max_us,mean_us,median_us,p90_us,p95_us,stddev_us\n"
  for result in self.results {
    body = body + result.to_csv_row()
  }
  body
}

/// Render a benchmark result as JSON including the raw samples.
pub fn BenchmarkResult::to_json_with_samples(self : BenchmarkResult) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"warmup\":\{self.warmup}," +
  "\"iterations\":\{self.iterations}," +
  "\"samples_us\":\{samples_to_json(self.samples_us)}," +
  "\"stats\":\{self.stats.to_json()}" +
  "}"
}

/// Render a result as one CSV row.
pub fn BenchmarkResult::to_csv_row(self : BenchmarkResult) -> String {
  csv_cell(self.name) + "," +
  "\{self.warmup}," +
  "\{self.iterations}," +
  "\{self.stats.count}," +
  "\{self.stats.min_us}," +
  "\{self.stats.max_us}," +
  "\{self.stats.mean_us}," +
  "\{self.stats.median_us}," +
  "\{self.stats.p90_us}," +
  "\{self.stats.p95_us}," +
  "\{self.stats.stddev_us}\n"
}

fn samples_to_json(samples : Array[Double]) -> String {
  let mut body = "["
  for i in 0..<samples.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + "\{samples[i]}"
  }
  body + "]"
}

fn csv_cell(value : String) -> String {
  let escaped = value.replace(old="\"", new="\"\"")
  if value.contains(",") || value.contains("\"") || value.contains("\n") {
    "\"\{escaped}\""
  } else {
    escaped
  }
}

/// A named baseline value measured in microseconds.
pub(all) struct BaselineEntry {
  name : String
  mean_us : Double
} derive(Eq, Debug)

/// A simple baseline database for matching results by benchmark name.
pub(all) struct BaselineSet {
  entries : Array[BaselineEntry]
} derive(Eq, Debug)

/// Create an empty baseline set.
pub fn BaselineSet::new() -> BaselineSet {
  { entries: [] }
}

/// Return a new baseline set with one entry appended.
pub fn BaselineSet::add(
  self : BaselineSet,
  name : String,
  mean_us : Double,
) -> BaselineSet {
  let entries = self.entries.copy()
  entries.push({ name, mean_us })
  { entries, }
}

/// Count entries in the baseline set.
pub fn BaselineSet::count(self : BaselineSet) -> Int {
  self.entries.length()
}

/// Compare every benchmark in a suite with matching baselines.
pub fn BaselineSet::compare_suite(
  self : BaselineSet,
  suite : BenchmarkSuite,
  tolerance_pct? : Double = 5.0,
) -> ComparisonReport {
  let comparisons : Array[NamedComparison] = []
  for result in suite.results {
    let (found, baseline_mean_us) = self.find(result.name)
    if found {
      let comparison = result.compare_baseline(baseline_mean_us, tolerance_pct=tolerance_pct)
      comparisons.push({
        name: result.name,
        baseline_found: true,
        baseline_mean_us,
        current_mean_us: result.stats.mean_us,
        delta_pct: comparison.delta_pct,
        status: comparison.status,
      })
    } else {
      comparisons.push({
        name: result.name,
        baseline_found: false,
        baseline_mean_us: 0.0,
        current_mean_us: result.stats.mean_us,
        delta_pct: 0.0,
        status: "missing_baseline",
      })
    }
  }
  ComparisonReport::from_comparisons(comparisons)
}

fn BaselineSet::find(self : BaselineSet, name : String) -> (Bool, Double) {
  for entry in self.entries {
    if entry.name == name {
      return (true, entry.mean_us)
    }
  }
  (false, 0.0)
}

/// One comparison row that preserves missing-baseline status.
pub(all) struct NamedComparison {
  name : String
  baseline_found : Bool
  baseline_mean_us : Double
  current_mean_us : Double
  delta_pct : Double
  status : String
} derive(Eq, Debug)

/// Summary of baseline comparison status counts.
pub(all) struct TrendSummary {
  total : Int
  faster : Int
  stable : Int
  slower : Int
  missing_baseline : Int
  best_delta_pct : Double
  worst_delta_pct : Double
} derive(Eq, Debug)

/// A full baseline comparison report.
pub(all) struct ComparisonReport {
  comparisons : Array[NamedComparison]
  summary : TrendSummary
} derive(Eq, Debug)

/// Build a comparison report from rows.
pub fn ComparisonReport::from_comparisons(comparisons : Array[NamedComparison]) -> ComparisonReport {
  let mut faster = 0
  let mut stable = 0
  let mut slower = 0
  let mut missing = 0
  let mut best = 0.0
  let mut worst = 0.0
  let mut has_delta = false
  for comparison in comparisons {
    if comparison.status == "faster" {
      faster = faster + 1
    } else if comparison.status == "slower" {
      slower = slower + 1
    } else if comparison.status == "stable" {
      stable = stable + 1
    } else {
      missing = missing + 1
    }
    if comparison.baseline_found {
      if !has_delta {
        best = comparison.delta_pct
        worst = comparison.delta_pct
        has_delta = true
      } else {
        if comparison.delta_pct < best {
          best = comparison.delta_pct
        }
        if comparison.delta_pct > worst {
          worst = comparison.delta_pct
        }
      }
    }
  }
  {
    comparisons,
    summary: {
      total: comparisons.length(),
      faster,
      stable,
      slower,
      missing_baseline: missing,
      best_delta_pct: best,
      worst_delta_pct: worst,
    },
  }
}

/// Render a comparison report as Markdown.
pub fn ComparisonReport::to_markdown(self : ComparisonReport) -> String {
  let mut body = "## Baseline Comparison\n\n"
  body = body + "- Total: \{self.summary.total}\n"
  body = body + "- Faster: \{self.summary.faster}\n"
  body = body + "- Stable: \{self.summary.stable}\n"
  body = body + "- Slower: \{self.summary.slower}\n"
  body = body + "- Missing baseline: \{self.summary.missing_baseline}\n"
  body = body + "- Best delta pct: \{self.summary.best_delta_pct}\n"
  body = body + "- Worst delta pct: \{self.summary.worst_delta_pct}\n\n"
  body = body + "| name | baseline_found | baseline_mean_us | current_mean_us | delta_pct | status |\n"
  body = body + "| --- | --- | ---: | ---: | ---: | --- |\n"
  for comparison in self.comparisons {
    body = body + comparison.to_markdown_row()
  }
  body
}

/// Render one comparison row as Markdown.
pub fn NamedComparison::to_markdown_row(self : NamedComparison) -> String {
  "| \{escape_markdown(self.name)} | \{self.baseline_found} | \{self.baseline_mean_us} | \{self.current_mean_us} | \{self.delta_pct} | \{self.status} |\n"
}

/// Render a comparison report as compact JSON.
pub fn ComparisonReport::to_json(self : ComparisonReport) -> String {
  let mut body = "{"
  body = body + "\"summary\":\{self.summary.to_json()},"
  body = body + "\"comparisons\":["
  for i in 0..<self.comparisons.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.comparisons[i].to_json()
  }
  body + "]}"
}

/// Render trend summary as compact JSON.
pub fn TrendSummary::to_json(self : TrendSummary) -> String {
  "{" +
  "\"total\":\{self.total}," +
  "\"faster\":\{self.faster}," +
  "\"stable\":\{self.stable}," +
  "\"slower\":\{self.slower}," +
  "\"missing_baseline\":\{self.missing_baseline}," +
  "\"best_delta_pct\":\{self.best_delta_pct}," +
  "\"worst_delta_pct\":\{self.worst_delta_pct}" +
  "}"
}

/// Render one named comparison as compact JSON.
pub fn NamedComparison::to_json(self : NamedComparison) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"baseline_found\":\{self.baseline_found}," +
  "\"baseline_mean_us\":\{self.baseline_mean_us}," +
  "\"current_mean_us\":\{self.current_mean_us}," +
  "\"delta_pct\":\{self.delta_pct}," +
  "\"status\":\"\{escape_json(self.status)}\"" +
  "}"
}

/// Validation result for benchmark naming and report hygiene.
pub(all) struct ValidationIssue {
  ok : Bool
  message : String
} derive(Eq, Debug)

/// Validate benchmark names before they appear in reports or CI artifacts.
pub fn validate_benchmark_name(name : String) -> ValidationIssue {
  if name == "" {
    return { ok: false, message: "benchmark name must not be empty" }
  }
  if name.contains("\n") {
    return { ok: false, message: "benchmark name must stay on one line" }
  }
  { ok: true, message: "ok" }
}

/// Normalize a benchmark name for compact console reports.
pub fn normalize_benchmark_name(name : String) -> String {
  name.replace(old="\n", new=" ").replace(old="\r", new=" ").replace(old="|", new="/")
}
