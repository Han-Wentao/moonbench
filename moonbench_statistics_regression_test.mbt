///|
test "percentile clamps extreme Int inputs before arithmetic" {
  let s = @moonbench.SampleSeries::new().add_many([1.0, 2.0, 3.0])
  assert_eq(s.percentile(2147483647), 3.0)
  assert_eq(s.percentile(-2147483648), 1.0)
}

///|
test "median of large finite values remains finite" {
  let s = @moonbench.SampleSeries::new().add_many([1.0e308, 1.0e308])
  assert_eq(s.median(), 1.0e308)
  assert_eq(
    @moonbench.SampleStats::from_samples(s.to_array()).median_us,
    1.0e308,
  )
}

///|
test "median preserves opposite signs and subnormal equal values" {
  assert_eq(
    @moonbench.SampleSeries::new().add_many([-1.0e308, 1.0e308]).median(),
    0.0,
  )
  assert_eq(
    @moonbench.SampleSeries::new().add_many([5.0e-324, 5.0e-324]).median(),
    5.0e-324,
  )
}

///|
test "median retains infinite endpoint behavior" {
  let inf = 1.0 / 0.0
  assert_eq(@moonbench.SampleSeries::new().add_many([1.0, inf]).median(), inf)
  assert_eq(
    @moonbench.SampleSeries::new().add_many([-inf, -1.0]).median(),
    -inf,
  )
}

///|
test "nearest rank matches exact integer oracle across window boundaries" {
  for n in 1..<205 {
    let values = Array::makei(n, i => i.to_double())
    let series = @moonbench.SampleSeries::new().add_many(values)
    for p in 1..<100 {
      let index = (n * p + 99) / 100 - 1
      assert_eq(series.percentile(p), index.to_double())
    }
  }
}
