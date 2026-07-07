/// A statistical summary of benchmark samples measured in microseconds.
pub(all) struct SampleStats {
  count : Int
  min_us : Double
  max_us : Double
  mean_us : Double
  median_us : Double
  stddev_us : Double
} derive(Eq, Debug)

/// Create a summary from an array of samples measured in microseconds.
pub fn SampleStats::from_samples(samples : Array[Double]) -> SampleStats {
  if samples.length() == 0 {
    return {
      count: 0,
      min_us: 0.0,
      max_us: 0.0,
      mean_us: 0.0,
      median_us: 0.0,
      stddev_us: 0.0,
    }
  }
  let sorted = samples.copy()
  sorted.sort()
  let count = sorted.length()
  let sum = for sample in sorted; acc = 0.0 {
    continue acc + sample
  } nobreak {
    acc
  }
  let mean = sum / count.to_double()
  let variance = if count < 2 {
    0.0
  } else {
    for sample in sorted; acc = 0.0 {
      let delta = sample - mean
      continue acc + delta * delta
    } nobreak {
      acc / (count - 1).to_double()
    }
  }
  {
    count,
    min_us: sorted[0],
    max_us: sorted[count - 1],
    mean_us: mean,
    median_us: median(sorted),
    stddev_us: variance.sqrt(),
  }
}

fn median(sorted : Array[Double]) -> Double {
  let count = sorted.length()
  let middle = count / 2
  if count % 2 == 1 {
    sorted[middle]
  } else {
    (sorted[middle - 1] + sorted[middle]) / 2.0
  }
}
