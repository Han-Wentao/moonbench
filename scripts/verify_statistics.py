"""Cross-check MoonBench with Python statistics; no third-party dependencies.

Nearest-rank percentiles use integer arithmetic, not Python's interpolated
quantiles. Generated tests are temporary and removed even on test failure.
"""
import argparse
from pathlib import Path
import random
import statistics
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--target', default='wasm-gc', choices=['wasm-gc', 'wasm', 'js', 'native'])
    args = parser.parse_args()
    rng = random.Random(20260914)
    cases = [[float(rng.randint(-100000, 100000)) / 8 for _ in range(n)]
             for n in range(1, 65)]
    lines = ['///|', 'test "Python statistics oracle: 64 deterministic series" {']
    assertions = 0
    for values in cases:
        ordered = sorted(values)
        n = len(values)
        checks = [('mean_us', statistics.mean(values)),
                  ('median_us', statistics.median(values)),
                  ('stddev_us', statistics.stdev(values) if n > 1 else 0.0),
                  ('p90_us', ordered[(n * 90 + 99) // 100 - 1]),
                  ('p95_us', ordered[(n * 95 + 99) // 100 - 1])]
        lines.append('  {')
        lines.append('    let s = @moonbench.SampleStats::from_samples([' + ','.join(map(repr, values)) + '])')
        for field, expected in checks:
            tolerance = max(1e-9, abs(expected) * 1e-12)
            lines.append(f'    assert_true((s.{field} - ({expected!r})).abs() <= {tolerance:.17e})')
            assertions += 1
        lines.append('  }')
    lines.append('}')
    path = ROOT / 'moonbench_python_oracle_test.mbt'
    # Exclusive creation prevents replacing someone else's work.
    with path.open('x', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    try:
        subprocess.run(['moon', 'test', '--target', args.target], cwd=str(ROOT), check=True)
    finally:
        path.unlink()
    print(f'ORACLE PASS: {len(cases)} series, {assertions} comparisons; target={args.target}; seed=20260914')

if __name__ == '__main__':
    main()
