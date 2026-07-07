fn main {
  let mut sample = 40
  let result = @moonbench.BenchmarkRunner::new(warmup=1, iterations=3).run(
    "demo-counter",
    () => {
      sample = sample + 5
      sample.to_double()
    },
  )
  println("# MoonBench demo")
  println("")
  println(result.to_markdown())
  println(result.compare_baseline(50.0).to_markdown())
}
