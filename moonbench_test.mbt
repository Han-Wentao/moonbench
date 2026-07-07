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
