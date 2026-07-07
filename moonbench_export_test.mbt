test "StatusBadge and BadgeSet render Markdown and JSON" {
  let badge = @moonbench.StatusBadge::new(
    "moon bit",
    "published",
    color="brightgreen",
    link="https://example.com",
  )
  inspect(badge.url().contains("moon%20bit-published-brightgreen"), content="true")
  inspect(badge.to_markdown().contains("https://example.com"), content="true")
  inspect(badge.to_json().contains("\"message\":\"published\""), content="true")
  let badges = @moonbench.BadgeSet::new().add(badge)
  inspect(badges.count(), content="1")
  inspect(badges.to_markdown().contains("img.shields.io"), content="true")
}

test "ReleaseNotes groups entries by kind" {
  let notes = @moonbench.ReleaseNotes::new("1.0.0", date="2026-07-08")
    .add(@moonbench.ReleaseNoteEntry::new("feature", "A"))
    .add(@moonbench.ReleaseNoteEntry::new("fix", "B", issue="#1"))
    .add(@moonbench.ReleaseNoteEntry::new("feature", "C", detail="detail"))
  inspect(notes.count(), content="3")
  inspect(notes.count_kind("feature"), content="2")
  inspect(notes.to_markdown().contains("Version 1.0.0"), content="true")
  inspect(notes.to_json().contains("\"issue\":\"#1\""), content="true")
}

test "ReviewerSummary renders contest-friendly summary" {
  let summary = @moonbench.ReviewerSummary::new(project="Demo")
    .add_highlight("fast")
    .add_verification("moon test")
  inspect(summary.to_markdown().contains("Demo 评审摘要"), content="true")
  inspect(summary.to_json().contains("\"verification\""), content="true")
}

test "GitHubStepSummary combines badges suite and gates" {
  let result = @moonbench.BenchmarkRunner::new(warmup=0, iterations=2).run(
    "summary",
    () => 10.0,
  )
  let suite = @moonbench.BenchmarkSuite::new(title="suite").add(result)
  let gate = @moonbench.GateReport::from_suite_samples(
    suite,
    policy=@moonbench.ThresholdPolicy::relaxed(),
  )
  let summary = @moonbench.GitHubStepSummary::new(suite=suite, gate=gate)
  inspect(summary.to_markdown().contains("MoonBench CI Summary"), content="true")
  inspect(summary.to_markdown().contains("Quality Gate"), content="true")
  inspect(summary.to_json().contains("\"suite\""), content="true")
}

test "Standard release notes and badges are populated" {
  inspect(@moonbench.BadgeSet::moonbench_standard().count() >= 4, content="true")
  inspect(@moonbench.ReleaseNotes::moonbench_0_2_0().count() >= 6, content="true")
  inspect(@moonbench.ReviewerSummary::moonbench_standard().highlights.length() >= 5, content="true")
}

test "Standard export helpers mention final project links" {
  let badges = @moonbench.BadgeSet::moonbench_standard()
  let notes = @moonbench.ReleaseNotes::moonbench_0_2_0()
  let summary = @moonbench.ReviewerSummary::moonbench_standard()
  inspect(badges.to_markdown().contains("mooncakes"), content="true")
  inspect(notes.to_markdown().contains("Chinese contest documentation"), content="true")
  inspect(summary.to_markdown().contains("https://github.com/Han-Wentao/moonbench"), content="true")
  inspect(summary.to_markdown().contains("https://mooncakes.io/docs/Han-Wentao/moonbench"), content="true")
  inspect(summary.to_json().contains("\"project\":\"MoonBench\""), content="true")
}
