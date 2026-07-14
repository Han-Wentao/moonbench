///|
/// A named numeric series used for trend analysis.
pub(all) struct SampleSeries {
  name : String
  unit : String
  values : Array[Double]
} derive(Eq, Debug)

///|
/// Create an empty numeric series.
pub fn SampleSeries::new(
  name? : String = "",
  unit? : String = "us",
) -> SampleSeries {
  { name, unit, values: [] }
}

///|
/// Create a series from an existing benchmark result.
pub fn SampleSeries::from_result(result : BenchmarkResult) -> SampleSeries {
  { name: result.name, unit: "us", values: result.samples_us.copy() }
}

///|
/// Return a new series with one value appended.
pub fn SampleSeries::add(self : SampleSeries, value : Double) -> SampleSeries {
  let values = self.values.copy()
  values.push(value)
  { ..self, values, }
}

///|
/// Return a new series with many values appended.
pub fn SampleSeries::add_many(
  self : SampleSeries,
  more : Array[Double],
) -> SampleSeries {
  let values = self.values.copy()
  for value in more {
    values.push(value)
  }
  { ..self, values, }
}

///|
/// Number of values in the series.
pub fn SampleSeries::count(self : SampleSeries) -> Int {
  self.values.length()
}

///|
/// Whether the series has no values.
pub fn SampleSeries::is_empty(self : SampleSeries) -> Bool {
  self.values.length() == 0
}

///|
/// Copy values as a new array.
pub fn SampleSeries::to_array(self : SampleSeries) -> Array[Double] {
  self.values.copy()
}

///|
/// Sort values ascending without mutating the original series.
pub fn SampleSeries::sorted(self : SampleSeries) -> Array[Double] {
  let values = self.values.copy()
  values.sort()
  values
}

///|
/// Sum all values in the series.
pub fn SampleSeries::sum(self : SampleSeries) -> Double {
  for value in self.values; acc = 0.0 {
    continue acc + value
  } nobreak {
    acc
  }
}

///|
/// Minimum value in the series.
pub fn SampleSeries::min(self : SampleSeries) -> Double {
  if self.values.length() == 0 {
    return 0.0
  }
  let mut best = self.values[0]
  for value in self.values {
    if value < best {
      best = value
    }
  }
  best
}

///|
/// Maximum value in the series.
pub fn SampleSeries::max(self : SampleSeries) -> Double {
  if self.values.length() == 0 {
    return 0.0
  }
  let mut worst = self.values[0]
  for value in self.values {
    if value > worst {
      worst = value
    }
  }
  worst
}

///|
/// Mean value in the series.
pub fn SampleSeries::mean(self : SampleSeries) -> Double {
  if self.values.length() == 0 {
    0.0
  } else {
    self.sum() / self.values.length().to_double()
  }
}

///|
/// Median value in the series.
pub fn SampleSeries::median(self : SampleSeries) -> Double {
  if self.values.length() == 0 {
    0.0
  } else {
    median(self.sorted())
  }
}

///|
/// Nearest-rank percentile value in the series.
pub fn SampleSeries::percentile(
  self : SampleSeries,
  percentile : Int,
) -> Double {
  nearest_rank(self.sorted(), percentile)
}

///|
/// 90th percentile value.
pub fn SampleSeries::p90(self : SampleSeries) -> Double {
  self.percentile(90)
}

///|
/// 95th percentile value.
pub fn SampleSeries::p95(self : SampleSeries) -> Double {
  self.percentile(95)
}

///|
/// Population variance.
pub fn SampleSeries::population_variance(self : SampleSeries) -> Double {
  if self.values.length() == 0 {
    return 0.0
  }
  let mean = self.mean()
  let total = for value in self.values; acc = 0.0 {
    let delta = value - mean
    continue acc + delta * delta
  } nobreak {
    acc
  }
  total / self.values.length().to_double()
}

///|
/// Sample variance.
pub fn SampleSeries::sample_variance(self : SampleSeries) -> Double {
  if self.values.length() < 2 {
    return 0.0
  }
  let mean = self.mean()
  let total = for value in self.values; acc = 0.0 {
    let delta = value - mean
    continue acc + delta * delta
  } nobreak {
    acc
  }
  total / (self.values.length() - 1).to_double()
}

///|
/// Population standard deviation.
pub fn SampleSeries::population_stddev(self : SampleSeries) -> Double {
  self.population_variance().sqrt()
}

///|
/// Sample standard deviation.
pub fn SampleSeries::sample_stddev(self : SampleSeries) -> Double {
  self.sample_variance().sqrt()
}

///|
/// Difference between max and min.
pub fn SampleSeries::range(self : SampleSeries) -> Double {
  self.max() - self.min()
}

///|
/// Latest value in insertion order.
pub fn SampleSeries::latest(self : SampleSeries) -> Double {
  if self.values.length() == 0 {
    0.0
  } else {
    self.values[self.values.length() - 1]
  }
}

///|
/// Previous value in insertion order.
pub fn SampleSeries::previous(self : SampleSeries) -> Double {
  if self.values.length() < 2 {
    0.0
  } else {
    self.values[self.values.length() - 2]
  }
}

///|
/// Delta between latest and previous values.
pub fn SampleSeries::latest_delta(self : SampleSeries) -> Double {
  if self.values.length() < 2 {
    0.0
  } else {
    self.latest() - self.previous()
  }
}

///|
/// Percentage delta between latest and previous values.
pub fn SampleSeries::latest_delta_pct(self : SampleSeries) -> Double {
  let previous = self.previous()
  if previous == 0.0 {
    0.0
  } else {
    (self.latest() - previous) / previous * 100.0
  }
}

///|
/// Coefficient of variation in percent.
pub fn SampleSeries::coefficient_of_variation_pct(
  self : SampleSeries,
) -> Double {
  let mean = self.mean()
  if mean == 0.0 {
    0.0
  } else {
    self.sample_stddev() / mean.abs() * 100.0
  }
}

///|
/// Count values that are above the mean by at least `z_limit` sample stddevs.
pub fn SampleSeries::high_outlier_count(
  self : SampleSeries,
  z_limit? : Double = 2.0,
) -> Int {
  let mean = self.mean()
  let stddev = self.sample_stddev()
  if stddev == 0.0 {
    return 0
  }
  let limit = z_limit.abs()
  for value in self.values; acc = 0 {
    let z = (value - mean) / stddev
    if z >= limit {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Count values that are below the mean by at least `z_limit` sample stddevs.
pub fn SampleSeries::low_outlier_count(
  self : SampleSeries,
  z_limit? : Double = 2.0,
) -> Int {
  let mean = self.mean()
  let stddev = self.sample_stddev()
  if stddev == 0.0 {
    return 0
  }
  let limit = 0.0 - z_limit.abs()
  for value in self.values; acc = 0 {
    let z = (value - mean) / stddev
    if z <= limit {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Count all z-score outliers.
pub fn SampleSeries::outlier_count(
  self : SampleSeries,
  z_limit? : Double = 2.0,
) -> Int {
  self.high_outlier_count(z_limit~) + self.low_outlier_count(z_limit~)
}

///|
/// Ratio of values within percent tolerance of the mean.
pub fn SampleSeries::stable_ratio(
  self : SampleSeries,
  tolerance_pct? : Double = 5.0,
) -> Double {
  if self.values.length() == 0 {
    return 0.0
  }
  let mean = self.mean()
  if mean == 0.0 {
    return 1.0
  }
  let limit = tolerance_pct.abs()
  let stable = for value in self.values; acc = 0 {
    let delta_pct = (value - mean).abs() / mean.abs() * 100.0
    if delta_pct <= limit {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
  stable.to_double() / self.values.length().to_double()
}

///|
/// Return the first `limit` values from the series.
pub fn SampleSeries::take(self : SampleSeries, limit : Int) -> SampleSeries {
  let values : Array[Double] = []
  if limit <= 0 {
    return { ..self, values, }
  }
  let end = if limit > self.values.length() {
    self.values.length()
  } else {
    limit
  }
  for i in 0..<end {
    values.push(self.values[i])
  }
  { ..self, values, }
}

///|
/// Return the last `limit` values from the series.
pub fn SampleSeries::take_last(
  self : SampleSeries,
  limit : Int,
) -> SampleSeries {
  let values : Array[Double] = []
  if limit <= 0 {
    return { ..self, values, }
  }
  let start = if limit >= self.values.length() {
    0
  } else {
    self.values.length() - limit
  }
  for i in start..<self.values.length() {
    values.push(self.values[i])
  }
  { ..self, values, }
}

///|
/// Moving average series with a fixed window.
pub fn SampleSeries::moving_average(
  self : SampleSeries,
  window : Int,
) -> SampleSeries {
  let values : Array[Double] = []
  if window <= 0 || self.values.length() == 0 {
    return { name: self.name + "/moving-average", unit: self.unit, values }
  }
  for i in 0..<self.values.length() {
    let start = if i + 1 < window { 0 } else { i + 1 - window }
    let mut total = 0.0
    let mut count = 0
    for j in start..<(i + 1) {
      total = total + self.values[j]
      count = count + 1
    }
    values.push(total / count.to_double())
  }
  { name: self.name + "/moving-average", unit: self.unit, values }
}

///|
/// Normalize values by the first value.
pub fn SampleSeries::normalize_to_first(self : SampleSeries) -> SampleSeries {
  let values : Array[Double] = []
  if self.values.length() == 0 || self.values[0] == 0.0 {
    return { name: self.name + "/normalized", unit: "ratio", values }
  }
  let base = self.values[0]
  for value in self.values {
    values.push(value / base)
  }
  { name: self.name + "/normalized", unit: "ratio", values }
}

///|
/// Normalize values by the mean.
pub fn SampleSeries::normalize_to_mean(self : SampleSeries) -> SampleSeries {
  let values : Array[Double] = []
  let mean = self.mean()
  if mean == 0.0 {
    return { name: self.name + "/mean-normalized", unit: "ratio", values }
  }
  for value in self.values {
    values.push(value / mean)
  }
  { name: self.name + "/mean-normalized", unit: "ratio", values }
}

///|
/// Render the series as a compact JSON array document.
pub fn SampleSeries::to_json(self : SampleSeries) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"unit\":\"\{escape_json(self.unit)}\"," +
  "\"values\":\{samples_to_json(self.values)}" +
  "}"
}

///|
/// Render the series as a Markdown table.
pub fn SampleSeries::to_markdown(self : SampleSeries) -> String {
  let mut body = "### \{escape_markdown(self.name)}\n\n"
  body = body + "| index | value | unit |\n"
  body = body + "| ---: | ---: | --- |\n"
  for i in 0..<self.values.length() {
    body = body +
      "| \{i} | \{self.values[i]} | \{escape_markdown(self.unit)} |\n"
  }
  body
}

///|
/// Analysis summary for a sample series.
pub(all) struct TrendAnalysis {
  name : String
  unit : String
  count : Int
  first : Double
  latest : Double
  min : Double
  max : Double
  mean : Double
  median : Double
  p90 : Double
  p95 : Double
  stddev : Double
  latest_delta_pct : Double
  coefficient_of_variation_pct : Double
  stable_ratio : Double
  outlier_count : Int
  direction : String
  risk : String
} derive(Eq, Debug)

///|
/// Analyze distribution and trend of a series.
pub fn SampleSeries::analyze(
  self : SampleSeries,
  tolerance_pct? : Double = 5.0,
  noisy_cv_pct? : Double = 15.0,
) -> TrendAnalysis {
  let first = if self.values.length() == 0 { 0.0 } else { self.values[0] }
  let latest = self.latest()
  let latest_delta_pct = if first == 0.0 {
    0.0
  } else {
    (latest - first) / first * 100.0
  }
  let limit = tolerance_pct.abs()
  let direction = if latest_delta_pct > limit {
    "up"
  } else if latest_delta_pct < 0.0 - limit {
    "down"
  } else {
    "flat"
  }
  let cv = self.coefficient_of_variation_pct()
  let risk = if self.values.length() < 2 {
    "insufficient"
  } else if cv > noisy_cv_pct.abs() {
    "noisy"
  } else if direction == "up" {
    "regression"
  } else {
    "ok"
  }
  {
    name: self.name,
    unit: self.unit,
    count: self.count(),
    first,
    latest,
    min: self.min(),
    max: self.max(),
    mean: self.mean(),
    median: self.median(),
    p90: self.p90(),
    p95: self.p95(),
    stddev: self.sample_stddev(),
    latest_delta_pct,
    coefficient_of_variation_pct: cv,
    stable_ratio: self.stable_ratio(tolerance_pct~),
    outlier_count: self.outlier_count(),
    direction,
    risk,
  }
}

///|
/// Render trend analysis as compact JSON.
pub fn TrendAnalysis::to_json(self : TrendAnalysis) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"unit\":\"\{escape_json(self.unit)}\"," +
  "\"count\":\{self.count}," +
  "\"first\":\{self.first}," +
  "\"latest\":\{self.latest}," +
  "\"min\":\{self.min}," +
  "\"max\":\{self.max}," +
  "\"mean\":\{self.mean}," +
  "\"median\":\{self.median}," +
  "\"p90\":\{self.p90}," +
  "\"p95\":\{self.p95}," +
  "\"stddev\":\{self.stddev}," +
  "\"latest_delta_pct\":\{self.latest_delta_pct}," +
  "\"coefficient_of_variation_pct\":\{self.coefficient_of_variation_pct}," +
  "\"stable_ratio\":\{self.stable_ratio}," +
  "\"outlier_count\":\{self.outlier_count}," +
  "\"direction\":\"\{escape_json(self.direction)}\"," +
  "\"risk\":\"\{escape_json(self.risk)}\"" +
  "}"
}

///|
/// Render trend analysis as Markdown.
pub fn TrendAnalysis::to_markdown(self : TrendAnalysis) -> String {
  "| name | count | first | latest | mean | p90 | p95 | delta_pct | cv_pct | stable_ratio | outliers | direction | risk |\n" +
  "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |\n" +
  "| \{escape_markdown(self.name)} | \{self.count} | \{self.first} | \{self.latest} | \{self.mean} | \{self.p90} | \{self.p95} | \{self.latest_delta_pct} | \{self.coefficient_of_variation_pct} | \{self.stable_ratio} | \{self.outlier_count} | \{self.direction} | \{self.risk} |\n"
}

///|
/// Policy used by CI quality gates.
pub(all) struct ThresholdPolicy {
  name : String
  faster_pct : Double
  slower_pct : Double
  noisy_cv_pct : Double
  minimum_samples : Int
  allow_missing_baseline : Bool
} derive(Eq, Debug)

///|
/// Create a custom threshold policy.
pub fn ThresholdPolicy::new(
  name? : String = "balanced",
  faster_pct? : Double = 5.0,
  slower_pct? : Double = 5.0,
  noisy_cv_pct? : Double = 20.0,
  minimum_samples? : Int = 3,
  allow_missing_baseline? : Bool = true,
) -> ThresholdPolicy {
  {
    name,
    faster_pct: faster_pct.abs(),
    slower_pct: slower_pct.abs(),
    noisy_cv_pct: noisy_cv_pct.abs(),
    minimum_samples: clamp_positive(minimum_samples),
    allow_missing_baseline,
  }
}

///|
/// Strict policy for release gates.
pub fn ThresholdPolicy::strict() -> ThresholdPolicy {
  ThresholdPolicy::new(
    name="strict",
    faster_pct=3.0,
    slower_pct=3.0,
    noisy_cv_pct=10.0,
    minimum_samples=5,
    allow_missing_baseline=false,
  )
}

///|
/// Balanced policy for normal CI.
pub fn ThresholdPolicy::balanced() -> ThresholdPolicy {
  ThresholdPolicy::new(
    name="balanced",
    faster_pct=5.0,
    slower_pct=5.0,
    noisy_cv_pct=20.0,
    minimum_samples=3,
    allow_missing_baseline=true,
  )
}

///|
/// Relaxed policy for local development.
pub fn ThresholdPolicy::relaxed() -> ThresholdPolicy {
  ThresholdPolicy::new(
    name="relaxed",
    faster_pct=10.0,
    slower_pct=10.0,
    noisy_cv_pct=35.0,
    minimum_samples=2,
    allow_missing_baseline=true,
  )
}

///|
/// Classify a percentage delta with this policy.
pub fn ThresholdPolicy::classify_delta(
  self : ThresholdPolicy,
  delta_pct : Double,
) -> String {
  if delta_pct > self.slower_pct {
    "slower"
  } else if delta_pct < 0.0 - self.faster_pct {
    "faster"
  } else {
    "stable"
  }
}

///|
/// Whether a sample count satisfies the policy.
pub fn ThresholdPolicy::has_enough_samples(
  self : ThresholdPolicy,
  count : Int,
) -> Bool {
  count >= self.minimum_samples
}

///|
/// Whether a coefficient of variation is considered noisy.
pub fn ThresholdPolicy::is_noisy(
  self : ThresholdPolicy,
  cv_pct : Double,
) -> Bool {
  cv_pct > self.noisy_cv_pct
}

///|
/// Render policy as JSON.
pub fn ThresholdPolicy::to_json(self : ThresholdPolicy) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"faster_pct\":\{self.faster_pct}," +
  "\"slower_pct\":\{self.slower_pct}," +
  "\"noisy_cv_pct\":\{self.noisy_cv_pct}," +
  "\"minimum_samples\":\{self.minimum_samples}," +
  "\"allow_missing_baseline\":\{self.allow_missing_baseline}" +
  "}"
}

///|
/// One gate decision for benchmark automation.
pub(all) struct GateDecision {
  name : String
  passed : Bool
  status : String
  reason : String
  severity : String
  delta_pct : Double
  sample_count : Int
  cv_pct : Double
} derive(Eq, Debug)

///|
/// Create an explicit gate decision.
pub fn GateDecision::new(
  name : String,
  passed : Bool,
  status : String,
  reason : String,
  severity? : String = "info",
  delta_pct? : Double = 0.0,
  sample_count? : Int = 0,
  cv_pct? : Double = 0.0,
) -> GateDecision {
  { name, passed, status, reason, severity, delta_pct, sample_count, cv_pct }
}

///|
/// Render a gate decision as Markdown row.
pub fn GateDecision::to_markdown_row(self : GateDecision) -> String {
  "| \{escape_markdown(self.name)} | \{self.passed} | \{self.status} | \{self.severity} | \{self.delta_pct} | \{self.sample_count} | \{self.cv_pct} | \{escape_markdown(self.reason)} |\n"
}

///|
/// Render a gate decision as compact JSON.
pub fn GateDecision::to_json(self : GateDecision) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"passed\":\{self.passed}," +
  "\"status\":\"\{escape_json(self.status)}\"," +
  "\"severity\":\"\{escape_json(self.severity)}\"," +
  "\"delta_pct\":\{self.delta_pct}," +
  "\"sample_count\":\{self.sample_count}," +
  "\"cv_pct\":\{self.cv_pct}," +
  "\"reason\":\"\{escape_json(self.reason)}\"" +
  "}"
}

///|
/// A collection of gate decisions.
pub(all) struct GateReport {
  policy : ThresholdPolicy
  decisions : Array[GateDecision]
} derive(Eq, Debug)

///|
/// Create an empty gate report.
pub fn GateReport::new(
  policy? : ThresholdPolicy = ThresholdPolicy::balanced(),
) -> GateReport {
  { policy, decisions: [] }
}

///|
/// Return a new report with one decision appended.
pub fn GateReport::add(
  self : GateReport,
  decision : GateDecision,
) -> GateReport {
  let decisions = self.decisions.copy()
  decisions.push(decision)
  { ..self, decisions, }
}

///|
/// Number of gate decisions.
pub fn GateReport::count(self : GateReport) -> Int {
  self.decisions.length()
}

///|
/// Number of passed decisions.
pub fn GateReport::passed_count(self : GateReport) -> Int {
  for decision in self.decisions; acc = 0 {
    if decision.passed {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Number of failed decisions.
pub fn GateReport::failed_count(self : GateReport) -> Int {
  self.count() - self.passed_count()
}

///|
/// Whether every decision passes.
pub fn GateReport::passed(self : GateReport) -> Bool {
  self.failed_count() == 0
}

///|
/// Render gate report as Markdown.
pub fn GateReport::to_markdown(self : GateReport) -> String {
  let mut body = "## Quality Gate\n\n"
  body = body + "- Policy: `\{escape_markdown(self.policy.name)}`\n"
  body = body + "- Passed: \{self.passed()}\n"
  body = body + "- Total decisions: \{self.count()}\n"
  body = body + "- Failed decisions: \{self.failed_count()}\n\n"
  body = body +
    "| name | passed | status | severity | delta_pct | samples | cv_pct | reason |\n"
  body = body + "| --- | --- | --- | --- | ---: | ---: | ---: | --- |\n"
  for decision in self.decisions {
    body = body + decision.to_markdown_row()
  }
  body
}

///|
/// Render gate report as compact JSON.
pub fn GateReport::to_json(self : GateReport) -> String {
  let mut body = "{"
  body = body + "\"policy\":\{self.policy.to_json()},"
  body = body + "\"passed\":\{self.passed()},"
  body = body + "\"total\":\{self.count()},"
  body = body + "\"failed\":\{self.failed_count()},"
  body = body + "\"decisions\":["
  for i in 0..<self.decisions.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.decisions[i].to_json()
  }
  body + "]}"
}

///|
/// Evaluate a comparison report with a threshold policy.
pub fn GateReport::from_comparison_report(
  report : ComparisonReport,
  policy? : ThresholdPolicy = ThresholdPolicy::balanced(),
) -> GateReport {
  let mut gate = GateReport::new(policy~)
  for comparison in report.comparisons {
    if !comparison.baseline_found {
      if policy.allow_missing_baseline {
        gate = gate.add(
          GateDecision::new(
            comparison.name,
            true,
            "missing_baseline",
            "baseline is missing but policy allows it",
            severity="warning",
          ),
        )
      } else {
        gate = gate.add(
          GateDecision::new(
            comparison.name,
            false,
            "missing_baseline",
            "baseline is required by policy",
            severity="error",
          ),
        )
      }
    } else {
      let status = policy.classify_delta(comparison.delta_pct)
      let passed = status != "slower"
      let reason = if passed {
        "delta is within policy"
      } else {
        "benchmark is slower than allowed"
      }
      gate = gate.add(
        GateDecision::new(
          comparison.name,
          passed,
          status,
          reason,
          severity=if passed { "info" } else { "error" },
          delta_pct=comparison.delta_pct,
        ),
      )
    }
  }
  gate
}

///|
/// Evaluate raw benchmark results without baselines for sample quality.
pub fn GateReport::from_suite_samples(
  suite : BenchmarkSuite,
  policy? : ThresholdPolicy = ThresholdPolicy::balanced(),
) -> GateReport {
  let mut gate = GateReport::new(policy~)
  for result in suite.results {
    let series = SampleSeries::from_result(result)
    let cv = series.coefficient_of_variation_pct()
    if !policy.has_enough_samples(result.stats.count) {
      gate = gate.add(
        GateDecision::new(
          result.name,
          false,
          "insufficient_samples",
          "sample count is below policy minimum",
          severity="error",
          sample_count=result.stats.count,
          cv_pct=cv,
        ),
      )
    } else if policy.is_noisy(cv) {
      gate = gate.add(
        GateDecision::new(
          result.name,
          false,
          "noisy",
          "coefficient of variation is above policy limit",
          severity="warning",
          sample_count=result.stats.count,
          cv_pct=cv,
        ),
      )
    } else {
      gate = gate.add(
        GateDecision::new(
          result.name,
          true,
          "sample_quality_ok",
          "sample count and variation are acceptable",
          sample_count=result.stats.count,
          cv_pct=cv,
        ),
      )
    }
  }
  gate
}
