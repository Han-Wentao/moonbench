test "SampleSeries computes distribution and trend metrics" {
  let series = @moonbench.SampleSeries::new(name="latency")
    .add_many([100.0, 102.0, 98.0, 110.0, 105.0])
  inspect(series.count(), content="5")
  inspect(series.min(), content="98")
  inspect(series.max(), content="110")
  inspect(series.mean(), content="103")
  inspect(series.median(), content="102")
  inspect(series.p90(), content="110")
  inspect(series.p95(), content="110")
  inspect(series.latest(), content="105")
  inspect(series.previous(), content="110")
  inspect(series.latest_delta(), content="-5")
}

test "SampleSeries normalizes and renders artifacts" {
  let series = @moonbench.SampleSeries::new(name="throughput", unit="ops")
    .add_many([10.0, 20.0, 30.0])
  let first = series.normalize_to_first()
  let mean = series.normalize_to_mean()
  inspect(first.to_array()[1], content="2")
  inspect(mean.to_array()[1], content="1")
  inspect(series.to_json().contains("\"unit\":\"ops\""), content="true")
  inspect(series.to_markdown().contains("| 2 | 30 | ops |"), content="true")
}

test "SampleSeries moving average keeps insertion order" {
  let series = @moonbench.SampleSeries::new(name="ma")
    .add_many([10.0, 20.0, 30.0, 40.0])
  let moving = series.moving_average(2)
  inspect(moving.to_array()[0], content="10")
  inspect(moving.to_array()[1], content="15")
  inspect(moving.to_array()[3], content="35")
}

test "TrendAnalysis classifies regression and noise" {
  let regression = @moonbench.SampleSeries::new(name="regression")
    .add_many([100.0, 108.0, 112.0])
    .analyze(tolerance_pct=5.0, noisy_cv_pct=100.0)
  inspect(regression.direction, content="up")
  inspect(regression.risk, content="regression")
  let noisy = @moonbench.SampleSeries::new(name="noisy")
    .add_many([10.0, 100.0, 10.0])
    .analyze(tolerance_pct=5.0, noisy_cv_pct=10.0)
  inspect(noisy.risk, content="noisy")
  inspect(noisy.to_json().contains("\"risk\":\"noisy\""), content="true")
  inspect(noisy.to_markdown().contains("| noisy |"), content="true")
}

test "ThresholdPolicy classifies deltas" {
  let policy = @moonbench.ThresholdPolicy::balanced()
  inspect(policy.classify_delta(6.0), content="slower")
  inspect(policy.classify_delta(-6.0), content="faster")
  inspect(policy.classify_delta(2.0), content="stable")
  inspect(policy.has_enough_samples(3), content="true")
  inspect(policy.is_noisy(30.0), content="true")
  inspect(policy.to_json().contains("\"name\":\"balanced\""), content="true")
}

test "GateReport evaluates comparison reports" {
  let runner = @moonbench.BenchmarkRunner::new(warmup=0, iterations=1)
  let suite = @moonbench.BenchmarkSuite::new()
    .add(runner.run("ok", () => 100.0))
    .add(runner.run("bad", () => 120.0))
    .add(runner.run("new", () => 10.0))
  let baselines = @moonbench.BaselineSet::new()
    .add("ok", 100.0)
    .add("bad", 100.0)
  let comparisons = baselines.compare_suite(suite, tolerance_pct=5.0)
  let gate = @moonbench.GateReport::from_comparison_report(
    comparisons,
    policy=@moonbench.ThresholdPolicy::strict(),
  )
  inspect(gate.count(), content="3")
  inspect(gate.failed_count(), content="2")
  inspect(gate.passed(), content="false")
  inspect(gate.to_markdown().contains("baseline is required"), content="true")
  inspect(gate.to_json().contains("\"failed\":2"), content="true")
}

test "GateReport evaluates sample quality" {
  let runner = @moonbench.BenchmarkRunner::new(warmup=0, iterations=2)
  let suite = @moonbench.BenchmarkSuite::new()
    .add(runner.run("stable", () => 10.0))
  let gate = @moonbench.GateReport::from_suite_samples(
    suite,
    policy=@moonbench.ThresholdPolicy::new(minimum_samples=2, noisy_cv_pct=5.0),
  )
  inspect(gate.passed(), content="true")
  inspect(gate.passed_count(), content="1")
}
