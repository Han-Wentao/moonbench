fn main {
  let mut current = 0
  let runner = @moonbench.BenchmarkRunner::new(warmup=1, iterations=4)
  let result = runner.run("increment-example", () => {
    current = current + 10
    current.to_double()
  })
  println(result.to_markdown())
}
