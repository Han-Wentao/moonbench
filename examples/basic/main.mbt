fn main {
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
  ).add(increment).add(arithmetic)
  println(suite.to_markdown())
  println(@moonbench.BaselineSet::new()
    .add("increment-example", increment.stats.mean_us)
    .add("manual-sample-example", 40.0)
    .compare_suite(suite)
    .to_markdown())
}
