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

/// A pure stopwatch state measured in microseconds.
pub(all) struct Stopwatch {
  elapsed_us : Int
  started_at_us : Int
  running : Bool
} derive(Eq, Debug)

/// Create a stopped stopwatch with no elapsed time.
pub fn Stopwatch::new() -> Stopwatch {
  { elapsed_us: 0, started_at_us: 0, running: false }
}

/// Start the stopwatch at `now_us`.
pub fn Stopwatch::start(self : Stopwatch, now_us : Int) -> Stopwatch {
  if self.running {
    self
  } else {
    { ..self, started_at_us: now_us, running: true }
  }
}

/// Stop the stopwatch at `now_us`.
pub fn Stopwatch::stop(self : Stopwatch, now_us : Int) -> Stopwatch {
  if self.running {
    {
      elapsed_us: self.elapsed_us + positive_delta(now_us, self.started_at_us),
      started_at_us: self.started_at_us,
      running: false,
    }
  } else {
    self
  }
}

/// Reset elapsed time and return to the stopped state.
pub fn Stopwatch::reset(_self : Stopwatch) -> Stopwatch {
  Stopwatch::new()
}

/// Return elapsed microseconds at `now_us` without changing the state.
pub fn Stopwatch::elapsed(self : Stopwatch, now_us : Int) -> Int {
  if self.running {
    self.elapsed_us + positive_delta(now_us, self.started_at_us)
  } else {
    self.elapsed_us
  }
}

/// Record a lap at `now_us`, returning the lap duration and updated stopwatch.
pub fn Stopwatch::lap(self : Stopwatch, now_us : Int) -> (Int, Stopwatch) {
  if self.running {
    let lap_us = positive_delta(now_us, self.started_at_us)
    (
      lap_us,
      {
        elapsed_us: self.elapsed_us + lap_us,
        started_at_us: now_us,
        running: true,
      },
    )
  } else {
    (0, self)
  }
}

fn positive_delta(now_us : Int, then_us : Int) -> Int {
  if now_us > then_us {
    now_us - then_us
  } else {
    0
  }
}
