fn main {
  let mut sample = 40
  let result = @moonbench.BenchmarkRunner::new(warmup=1, iterations=3).run_timed(
    "demo-counter",
    () => {
      sample = sample + 5
      ignore(sample)
    },
  )
  println("# MoonBench demo")
  println("")
  println(result.to_markdown())
  println(result.compare_baseline(result.stats.mean_us).to_markdown())
}
