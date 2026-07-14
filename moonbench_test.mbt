///|
test "SampleStats summarizes sorted and unsorted samples" {
  let stats = @moonbench.SampleStats::from_samples([10.0, 4.0, 8.0, 6.0])
  inspect(stats.count, content="4")
  inspect(stats.min_us, content="4")
  inspect(stats.max_us, content="10")
  inspect(stats.mean_us, content="7")
  inspect(stats.median_us, content="7")
  inspect(stats.p90_us, content="10")
  inspect(stats.p95_us, content="10")
}

///|
test "SampleStats handles an empty sample list" {
  let stats = @moonbench.SampleStats::from_samples([])
  inspect(stats.count, content="0")
  inspect(stats.min_us, content="0")
  inspect(stats.max_us, content="0")
  inspect(stats.mean_us, content="0")
  inspect(stats.median_us, content="0")
  inspect(stats.p90_us, content="0")
  inspect(stats.p95_us, content="0")
  inspect(stats.stddev_us, content="0")
}

///|
test "Stopwatch accumulates elapsed time across start and stop" {
  let watch = @moonbench.Stopwatch::new().start(100).stop(160).start(200)
  inspect(watch.elapsed(250), content="110")
  inspect(watch.stop(260).elapsed(999), content="120")
}

///|
test "Stopwatch lap returns the interval and keeps running" {
  let watch = @moonbench.Stopwatch::new().start(10)
  let (lap_us, next) = watch.lap(35)
  inspect(lap_us, content="25")
  inspect(next.elapsed(50), content="40")
}

///|
test "Stopwatch reset clears state" {
  let watch = @moonbench.Stopwatch::new().start(1).stop(10).reset()
  inspect(watch.elapsed(100), content="0")
  inspect(watch.running, content="false")
}

///|
test "BenchmarkRunner ignores warmup and summarizes iterations" {
  let mut cursor = 0
  let runner = @moonbench.BenchmarkRunner::new(warmup=2, iterations=3)
  let result = runner.run("demo", () => {
    cursor = cursor + 1
    cursor.to_double()
  })
  inspect(result.name, content="demo")
  inspect(result.warmup, content="2")
  inspect(result.iterations, content="3")
  debug_inspect(result.samples_us, content="[3, 4, 5]")
  inspect(result.stats.mean_us, content="4")
}

///|
test "BenchmarkRunner clamps invalid counts" {
  let runner = @moonbench.BenchmarkRunner::new(warmup=-2, iterations=0)
  inspect(runner.warmup, content="0")
  inspect(runner.iterations, content="1")
}

///|
test "BenchmarkRunner can time a function body" {
  let mut value = 0
  let result = @moonbench.BenchmarkRunner::new(warmup=1, iterations=2).run_timed(
    "timed",
    () => value = value + 1,
  )
  inspect(value, content="3")
  inspect(result.samples_us.length(), content="2")
  inspect(result.stats.count, content="2")
  inspect(result.stats.min_us >= 0.0, content="true")
}

///|
test "BenchmarkResult renders JSON with stats" {
  let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=2).run(
    "json demo",
    () => 7.0,
  )
  let json = result.to_json()
  inspect(json.contains("\"name\":\"json demo\""), content="true")
  inspect(json.contains("\"iterations\":2"), content="true")
  inspect(json.contains("\"mean_us\":7"), content="true")
  inspect(json.contains("\"p95_us\":7"), content="true")
}

///|
test "BenchmarkResult renders Markdown table" {
  let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=1).run(
    "pipe | demo",
    () => 3.0,
  )
  let markdown = result.to_markdown()
  inspect(
    markdown.contains(
      "| name | count | min_us | max_us | mean_us | median_us | p90_us | p95_us |",
    ),
    content="true",
  )
  inspect(markdown.contains("pipe \\| demo"), content="true")
}

///|
test "BenchmarkResult compares against a stable baseline" {
  let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=2).run(
    "stable",
    () => 102.0,
  )
  let comparison = result.compare_baseline(100.0, tolerance_pct=5.0)
  inspect(comparison.status, content="stable")
  inspect(comparison.delta_pct, content="2")
}

///|
test "BenchmarkResult marks faster and slower changes" {
  let faster = @moonbench.BenchmarkRunner::new(warmup=0, iterations=1)
    .run("fast", () => 80.0)
    .compare_baseline(100.0, tolerance_pct=5.0)
  let slower = @moonbench.BenchmarkRunner::new(warmup=0, iterations=1)
    .run("slow", () => 120.0)
    .compare_baseline(100.0, tolerance_pct=5.0)
  inspect(faster.status, content="faster")
  inspect(slower.status, content="slower")
}

///|
test "BaselineComparison renders Markdown" {
  let comparison = @moonbench.BenchmarkRunner::new(warmup=0, iterations=1)
    .run("pipe | compare", () => 90.0)
    .compare_baseline(100.0)
  let markdown = comparison.to_markdown()
  inspect(markdown.contains("pipe \\| compare"), content="true")
  inspect(markdown.contains("faster"), content="true")
}

///|
test "BenchmarkSuite summarizes multiple results" {
  let runner = @moonbench.BenchmarkRunner::new(warmup=0, iterations=2)
  let fast = runner.run("fast", () => 10.0)
  let slow = runner.run("slow", () => 30.0)
  let suite = @moonbench.BenchmarkSuite::new(
      title="demo suite",
      package_name="Han-Wentao/moonbench",
      package_version="0.2.0",
      target="wasm-gc",
    )
    .add(fast)
    .add(slow)
  inspect(suite.count(), content="2")
  inspect(suite.total_iterations(), content="4")
  inspect(suite.average_mean_us(), content="20")
  inspect(suite.fastest_name(), content="fast")
  inspect(suite.slowest_name(), content="slow")
}

///|
test "BenchmarkSuite renders Markdown JSON and CSV" {
  let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=2).run(
    "csv, json | demo",
    () => 12.0,
  )
  let suite = @moonbench.BenchmarkSuite::new(title="report").add(result)
  let markdown = suite.to_markdown()
  let json = suite.to_json()
  let csv = suite.to_csv()
  inspect(markdown.contains("## report"), content="true")
  inspect(markdown.contains("csv, json \\| demo"), content="true")
  inspect(json.contains("\"samples_us\":[12,12]"), content="true")
  inspect(csv.contains("p90_us,p95_us"), content="true")
  inspect(csv.contains("\"csv, json | demo\""), content="true")
}

///|
test "BaselineSet compares suites and tracks missing baselines" {
  let runner = @moonbench.BenchmarkRunner::new(warmup=0, iterations=1)
  let suite = @moonbench.BenchmarkSuite::new()
    .add(runner.run("fast", () => 80.0))
    .add(runner.run("same", () => 101.0))
    .add(runner.run("new", () => 50.0))
  let baselines = @moonbench.BaselineSet::new()
    .add("fast", 100.0)
    .add("same", 100.0)
  let report = baselines.compare_suite(suite, tolerance_pct=5.0)
  inspect(report.summary.total, content="3")
  inspect(report.summary.faster, content="1")
  inspect(report.summary.stable, content="1")
  inspect(report.summary.missing_baseline, content="1")
  inspect(report.to_markdown().contains("missing_baseline"), content="true")
  inspect(report.to_json().contains("\"faster\":1"), content="true")
}

///|
test "benchmark name validation rejects empty and multiline names" {
  inspect(@moonbench.validate_benchmark_name("").ok, content="false")
  inspect(@moonbench.validate_benchmark_name("a\nb").ok, content="false")
  inspect(@moonbench.validate_benchmark_name("ok").ok, content="true")
  inspect(@moonbench.normalize_benchmark_name("a|b\nc"), content="a/b c")
}
