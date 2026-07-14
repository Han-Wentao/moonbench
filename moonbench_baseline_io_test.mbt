///|
test "baseline text round-trips and duplicate values use last declaration" {
  let source = @moonbench.BaselineSet::new()
    .add("parse-small", 12.5)
    .add("render-large", 80.0)
    .to_text()
  let report = @moonbench.BaselineSet::parse_text(source + "parse-small=10.0\n")
  inspect(report.is_valid(), content="true")
  inspect(report.count(), content="2")
  let runner = @moonbench.BenchmarkRunner::new(warmup=0, iterations=1)
  let suite = @moonbench.BenchmarkSuite::new().add(
    runner.run("parse-small", () => 11.0),
  )
  let comparison = report.baselines.compare_suite(suite, tolerance_pct=5.0)
  inspect(comparison.summary.slower, content="1")
}

///|
test "baseline parser skips invalid lines and reports diagnostics" {
  let text = "# generated baseline\n" +
    "valid = 42.5\n" +
    "missing separator\n" +
    " = 1.0\n" +
    "negative=-2\n" +
    "nan-value=nan\n"
  let report = @moonbench.BaselineSet::parse_text(text)
  inspect(report.is_valid(), content="false")
  inspect(report.count(), content="1")
  inspect(report.issue_count(), content="4")
  inspect(report.issues[0].line, content="3")
  inspect(
    report.issues_to_markdown().contains("expected name=mean_us"),
    content="true",
  )
}

///|
test "JSON escaping handles control characters" {
  let metadata = @moonbench.ReportMetadata::new(
    title="line one\nline two\tindented\rreturn",
  )
  let json = metadata.to_json()
  inspect(
    json.contains("line one\\nline two\\tindented\\rreturn"),
    content="true",
  )
  inspect(json.contains("\n"), content="false")
}
