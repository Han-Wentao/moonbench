# MoonBench

MoonBench is a lightweight stopwatch, benchmark reporting, and baseline
comparison toolkit for MoonBit projects.

The project is built for the 2026 MoonBit open-source ecosystem contest. It
focuses on a practical package that MoonBit developers can use to collect
repeatable micro-benchmark samples, export stable reports, and compare current
results with a baseline.

## Features

- Pure `Stopwatch` state for deterministic manual measurements.
- `BenchmarkRunner` with warmup and iteration controls.
- `SampleStats` for min, max, mean, median, and standard deviation.
- JSON and Markdown report rendering.
- Baseline comparison with `faster`, `stable`, and `slower` statuses.
- Runnable demos for quick verification.

## Quick Start

Run the bundled demo:

```powershell
moon run cmd/main
```

Run the package checks:

```powershell
moon check
moon test
moon run examples/basic
```

## Minimal Example

```moonbit
let mut sample = 0
let result = @moonbench.BenchmarkRunner::new(warmup=1, iterations=3).run(
  "increment",
  () => {
    sample = sample + 10
    sample.to_double()
  },
)
println(result.to_markdown())
println(result.compare_baseline(20.0).to_markdown())
```

## Contest Notes

MoonBench is an original MoonBit implementation. It does not port another
benchmark library directly. The package is intentionally small, testable, and
usable as an ecosystem utility for MoonBit library authors who need simple
performance reports in README files, pull requests, or release notes.

## License

MIT
