test "BenchmarkSnapshot captures suite metrics" {
  let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=2).run(
    "snap",
    () => 20.0,
  )
  let suite = @moonbench.BenchmarkSuite::new(title="suite").add(result)
  let snapshot = @moonbench.BenchmarkSnapshot::from_suite(
    suite,
    label="after",
    commit="abc",
    created_at="2026-07-08",
  )
  inspect(snapshot.count(), content="1")
  inspect(snapshot.contains("snap"), content="true")
  inspect(snapshot.average_mean_us(), content="20")
  inspect(snapshot.to_baseline_text().contains("snap=20"), content="true")
  inspect(snapshot.to_markdown().contains("Snapshot after"), content="true")
  inspect(snapshot.to_json().contains("\"commit\":\"abc\""), content="true")
}

test "BenchmarkSnapshot converts to baseline set" {
  let snapshot = @moonbench.BenchmarkSnapshot::new(label="base")
    .add(@moonbench.MetricSnapshot::new("a", 10.0))
    .add(@moonbench.MetricSnapshot::new("b", 20.0))
  let baselines = snapshot.to_baseline_set()
  inspect(baselines.count(), content="2")
  let suite = @moonbench.BenchmarkSuite::new()
    .add(@moonbench.BenchmarkRunner::new(warmup=0, iterations=1).run("a", () => 11.0))
  let report = baselines.compare_suite(suite, tolerance_pct=5.0)
  inspect(report.summary.stable, content="0")
  inspect(report.summary.slower, content="1")
}

test "SnapshotDiffReport detects faster slower added and removed" {
  let before = @moonbench.BenchmarkSnapshot::new(label="before")
    .add(@moonbench.MetricSnapshot::new("same", 100.0))
    .add(@moonbench.MetricSnapshot::new("slow", 100.0))
    .add(@moonbench.MetricSnapshot::new("gone", 10.0))
  let after = @moonbench.BenchmarkSnapshot::new(label="after")
    .add(@moonbench.MetricSnapshot::new("same", 102.0))
    .add(@moonbench.MetricSnapshot::new("slow", 120.0))
    .add(@moonbench.MetricSnapshot::new("new", 5.0))
  let diff = before.diff(after, tolerance_pct=5.0)
  inspect(diff.count(), content="4")
  inspect(diff.count_status("stable"), content="1")
  inspect(diff.count_status("slower"), content="1")
  inspect(diff.count_status("added"), content="1")
  inspect(diff.count_status("removed"), content="1")
  inspect(diff.has_regression(), content="true")
  inspect(diff.is_clean(), content="false")
  inspect(diff.to_markdown().contains("Snapshot Diff"), content="true")
  inspect(diff.to_json().contains("\"has_regression\":true"), content="true")
}

test "SnapshotDiffReport converts to gate report" {
  let before = @moonbench.BenchmarkSnapshot::new(label="before")
    .add(@moonbench.MetricSnapshot::new("x", 100.0))
  let after = @moonbench.BenchmarkSnapshot::new(label="after")
    .add(@moonbench.MetricSnapshot::new("x", 130.0))
  let gate = before.diff(after).to_gate_report()
  inspect(gate.count(), content="1")
  inspect(gate.passed(), content="false")
  inspect(gate.to_markdown().contains("snapshot diff indicates regression"), content="true")
}
