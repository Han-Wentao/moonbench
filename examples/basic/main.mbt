///|
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
      package_version="0.3.0",
    )
    .add(increment)
    .add(arithmetic)
  println(suite.to_markdown())
  let baseline_text = "# Baseline shared by local runs and CI\n" +
    "increment-example=1.0\n" +
    "manual-sample-example=40.0\n"
  let parsed = @moonbench.BaselineSet::parse_text(baseline_text)
  println(parsed.baselines.compare_suite(suite).to_markdown())
}
