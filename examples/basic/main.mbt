fn main {
  let mut current = 0
  let runner = @moonbench.BenchmarkRunner::new(warmup=1, iterations=4)
  let result = runner.run_timed("increment-example", () => {
    current = current + 10
    ignore(current)
  })
  println(result.to_markdown())
}
