test "SampleStats summarizes sorted and unsorted samples" {
  let stats = @moonbench.SampleStats::from_samples([10.0, 4.0, 8.0, 6.0])
  inspect(stats.count, content="4")
  inspect(stats.min_us, content="4")
  inspect(stats.max_us, content="10")
  inspect(stats.mean_us, content="7")
  inspect(stats.median_us, content="7")
}

test "SampleStats handles an empty sample list" {
  let stats = @moonbench.SampleStats::from_samples([])
  inspect(stats.count, content="0")
  inspect(stats.min_us, content="0")
  inspect(stats.max_us, content="0")
  inspect(stats.mean_us, content="0")
  inspect(stats.median_us, content="0")
  inspect(stats.stddev_us, content="0")
}

test "Stopwatch accumulates elapsed time across start and stop" {
  let watch = @moonbench.Stopwatch::new().start(100).stop(160).start(200)
  inspect(watch.elapsed(250), content="110")
  inspect(watch.stop(260).elapsed(999), content="120")
}

test "Stopwatch lap returns the interval and keeps running" {
  let watch = @moonbench.Stopwatch::new().start(10)
  let (lap_us, next) = watch.lap(35)
  inspect(lap_us, content="25")
  inspect(next.elapsed(50), content="40")
}

test "Stopwatch reset clears state" {
  let watch = @moonbench.Stopwatch::new().start(1).stop(10).reset()
  inspect(watch.elapsed(100), content="0")
  inspect(watch.running, content="false")
}

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

test "BenchmarkRunner clamps invalid counts" {
  let runner = @moonbench.BenchmarkRunner::new(warmup=-2, iterations=0)
  inspect(runner.warmup, content="0")
  inspect(runner.iterations, content="1")
}

test "BenchmarkResult renders JSON with stats" {
  let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=2).run(
    "json demo",
    () => 7.0,
  )
  let json = result.to_json()
  inspect(json.contains("\"name\":\"json demo\""), content="true")
  inspect(json.contains("\"iterations\":2"), content="true")
  inspect(json.contains("\"mean_us\":7"), content="true")
}

test "BenchmarkResult renders Markdown table" {
  let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=1).run(
    "pipe | demo",
    () => 3.0,
  )
  let markdown = result.to_markdown()
  inspect(markdown.contains("| name | count |"), content="true")
  inspect(markdown.contains("pipe \\| demo"), content="true")
}
