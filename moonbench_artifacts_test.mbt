///|
test "ArtifactBundle tracks required paths" {
  let bundle = @moonbench.ArtifactBundle::new(title="artifacts")
    .add(@moonbench.Artifact::markdown("readme", "README.md"))
    .add(@moonbench.Artifact::zip("missing", "", description="missing path"))
    .add(@moonbench.Artifact::json("report", "_build/report.json"))
  inspect(bundle.count(), content="3")
  inspect(bundle.required_count(), content="2")
  inspect(bundle.with_path_count(), content="2")
  inspect(bundle.required_paths_ready(), content="false")
  inspect(
    bundle.to_markdown().contains("| readme | markdown | `README.md` | true |"),
    content="true",
  )
  inspect(
    bundle.to_json().contains("\"required_paths_ready\":false"),
    content="true",
  )
}

///|
test "MarkdownDocument composes benchmark reports" {
  let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=1).run(
    "doc-bench",
    () => 12.0,
  )
  let suite = @moonbench.BenchmarkSuite::new(title="doc suite").add(result)
  let doc = @moonbench.MarkdownDocument::new("Report", intro="intro")
    .with_suite(suite)
    .section("Notes", "done", level=3)
  let rendered = doc.render()
  inspect(doc.section_count(), content="2")
  inspect(rendered.contains("# Report"), content="true")
  inspect(rendered.contains("## Benchmark Suite"), content="true")
  inspect(rendered.contains("### Notes"), content="true")
}

///|
test "ChecklistItem can be completed and rendered" {
  let item = @moonbench.ChecklistItem::new("ci", "CI", required=true).complete(
    "green",
  )
  inspect(item.done, content="true")
  inspect(item.evidence, content="green")
  inspect(item.to_markdown_row().contains("[x]"), content="true")
  inspect(item.to_json().contains("\"done\":true"), content="true")
}

///|
test "SubmissionChecklist computes readiness" {
  let checklist = @moonbench.SubmissionChecklist::new()
    .add(@moonbench.ChecklistItem::new("a", "A", done=true))
    .add(@moonbench.ChecklistItem::new("b", "B", done=false))
    .add(@moonbench.ChecklistItem::new("c", "C", done=false, required=false))
  inspect(checklist.count(), content="3")
  inspect(checklist.required_count(), content="2")
  inspect(checklist.done_count(), content="1")
  inspect(checklist.missing_required_count(), content="1")
  inspect(checklist.ready(), content="false")
  inspect(
    checklist.to_markdown().contains("Missing required: 1"),
    content="true",
  )
  inspect(checklist.to_json().contains("\"ready\":false"), content="true")
}

///|
test "Standard submission bundles describe final contest assets" {
  let checklist = @moonbench.SubmissionChecklist::moonbench_standard()
  let bundle = @moonbench.ArtifactBundle::moonbench_standard()
  inspect(checklist.count() >= 8, content="true")
  inspect(checklist.ready(), content="false")
  inspect(bundle.count() >= 6, content="true")
  inspect(bundle.required_paths_ready(), content="true")
}
