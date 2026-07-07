/// A compact status badge for README, CI summary, or release notes.
pub(all) struct StatusBadge {
  label : String
  message : String
  color : String
  link : String
} derive(Eq, Debug)

/// Create a status badge.
pub fn StatusBadge::new(
  label : String,
  message : String,
  color? : String = "blue",
  link? : String = "",
) -> StatusBadge {
  { label, message, color, link }
}

/// Render a shields.io badge URL.
pub fn StatusBadge::url(self : StatusBadge) -> String {
  "https://img.shields.io/badge/" +
  badge_escape(self.label) +
  "-" +
  badge_escape(self.message) +
  "-" +
  badge_escape(self.color)
}

fn badge_escape(value : String) -> String {
  value
    .replace(old="-", new="--")
    .replace(old=" ", new="%20")
    .replace(old="_", new="__")
    .replace(old="/", new="%2F")
}

/// Render badge Markdown.
pub fn StatusBadge::to_markdown(self : StatusBadge) -> String {
  let image = "![\{escape_markdown(self.label)}](\{self.url()})"
  if self.link == "" {
    image
  } else {
    "[\{image}](\{self.link})"
  }
}

/// Render badge JSON.
pub fn StatusBadge::to_json(self : StatusBadge) -> String {
  "{" +
  "\"label\":\"\{escape_json(self.label)}\"," +
  "\"message\":\"\{escape_json(self.message)}\"," +
  "\"color\":\"\{escape_json(self.color)}\"," +
  "\"link\":\"\{escape_json(self.link)}\"," +
  "\"url\":\"\{escape_json(self.url())}\"" +
  "}"
}

/// A collection of badges.
pub(all) struct BadgeSet {
  badges : Array[StatusBadge]
} derive(Eq, Debug)

/// Create an empty badge set.
pub fn BadgeSet::new() -> BadgeSet {
  { badges: [] }
}

/// Append a badge.
pub fn BadgeSet::add(self : BadgeSet, badge : StatusBadge) -> BadgeSet {
  let badges = self.badges.copy()
  badges.push(badge)
  { badges, }
}

/// Number of badges.
pub fn BadgeSet::count(self : BadgeSet) -> Int {
  self.badges.length()
}

/// Render all badges as one Markdown line.
pub fn BadgeSet::to_markdown(self : BadgeSet) -> String {
  let mut body = ""
  for i in 0..<self.badges.length() {
    if i > 0 {
      body = body + " "
    }
    body = body + self.badges[i].to_markdown()
  }
  body
}

/// Render badges as JSON.
pub fn BadgeSet::to_json(self : BadgeSet) -> String {
  let mut body = "{\"badges\":["
  for i in 0..<self.badges.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.badges[i].to_json()
  }
  body + "]}"
}

/// Standard badges for MoonBench.
pub fn BadgeSet::moonbench_standard() -> BadgeSet {
  BadgeSet::new()
    .add(StatusBadge::new(
      "MoonBit",
      "0.1.20260703",
      color="blue",
      link="https://www.moonbitlang.com/",
    ))
    .add(StatusBadge::new(
      "tests",
      "passing",
      color="brightgreen",
      link="https://github.com/Han-Wentao/moonbench/actions",
    ))
    .add(StatusBadge::new(
      "mooncakes",
      "published",
      color="success",
      link="https://mooncakes.io/docs/Han-Wentao/moonbench",
    ))
    .add(StatusBadge::new(
      "license",
      "MIT",
      color="green",
      link="LICENSE",
    ))
}

/// A release note entry.
pub(all) struct ReleaseNoteEntry {
  kind : String
  title : String
  detail : String
  issue : String
} derive(Eq, Debug)

/// Create a release note entry.
pub fn ReleaseNoteEntry::new(
  kind : String,
  title : String,
  detail? : String = "",
  issue? : String = "",
) -> ReleaseNoteEntry {
  { kind, title, detail, issue }
}

/// Render release note entry as Markdown bullet.
pub fn ReleaseNoteEntry::to_markdown(self : ReleaseNoteEntry) -> String {
  let mut body = "- **\{escape_markdown(self.kind)}**: \{escape_markdown(self.title)}"
  if self.issue != "" {
    body = body + " (\{escape_markdown(self.issue)})"
  }
  if self.detail != "" {
    body = body + "\n  \{escape_markdown(self.detail)}"
  }
  body + "\n"
}

/// Render release note entry as JSON.
pub fn ReleaseNoteEntry::to_json(self : ReleaseNoteEntry) -> String {
  "{" +
  "\"kind\":\"\{escape_json(self.kind)}\"," +
  "\"title\":\"\{escape_json(self.title)}\"," +
  "\"detail\":\"\{escape_json(self.detail)}\"," +
  "\"issue\":\"\{escape_json(self.issue)}\"" +
  "}"
}

/// Release notes for a package version.
pub(all) struct ReleaseNotes {
  version : String
  date : String
  entries : Array[ReleaseNoteEntry]
} derive(Eq, Debug)

/// Create release notes.
pub fn ReleaseNotes::new(version : String, date? : String = "") -> ReleaseNotes {
  { version, date, entries: [] }
}

/// Append a release note entry.
pub fn ReleaseNotes::add(self : ReleaseNotes, entry : ReleaseNoteEntry) -> ReleaseNotes {
  let entries = self.entries.copy()
  entries.push(entry)
  { ..self, entries }
}

/// Count entries.
pub fn ReleaseNotes::count(self : ReleaseNotes) -> Int {
  self.entries.length()
}

/// Count entries by kind.
pub fn ReleaseNotes::count_kind(self : ReleaseNotes, kind : String) -> Int {
  for entry in self.entries; acc = 0 {
    if entry.kind == kind {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

/// Render release notes as Markdown.
pub fn ReleaseNotes::to_markdown(self : ReleaseNotes) -> String {
  let mut body = "## Version \{escape_markdown(self.version)}\n\n"
  if self.date != "" {
    body = body + "- Date: \{escape_markdown(self.date)}\n"
  }
  body = body + "- Entries: \{self.count()}\n\n"
  for entry in self.entries {
    body = body + entry.to_markdown()
  }
  body
}

/// Render release notes as JSON.
pub fn ReleaseNotes::to_json(self : ReleaseNotes) -> String {
  let mut body = "{"
  body = body + "\"version\":\"\{escape_json(self.version)}\","
  body = body + "\"date\":\"\{escape_json(self.date)}\","
  body = body + "\"entries\":["
  for i in 0..<self.entries.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.entries[i].to_json()
  }
  body + "]}"
}

/// Standard release notes for MoonBench 0.2.0.
pub fn ReleaseNotes::moonbench_0_2_0() -> ReleaseNotes {
  ReleaseNotes::new("0.2.0", date="2026-07-08")
    .add(ReleaseNoteEntry::new(
      "feature",
      "BenchmarkSuite multi-result reporting",
      detail="Render grouped benchmark results as Markdown, JSON, and CSV.",
    ))
    .add(ReleaseNoteEntry::new(
      "feature",
      "Trend analysis and quality gates",
      detail="Analyze noisy samples and evaluate performance regressions with threshold policies.",
    ))
    .add(ReleaseNoteEntry::new(
      "feature",
      "Submission artifact helpers",
      detail="Describe contest artifacts, checklists, badges, and generated reports.",
    ))
    .add(ReleaseNoteEntry::new(
      "feature",
      "Scenario catalog",
      detail="Provide a reusable catalog of benchmark workload scenarios.",
    ))
    .add(ReleaseNoteEntry::new(
      "test",
      "Expanded test coverage",
      detail="Cover suite, baseline, gate, artifact, and scenario behavior.",
    ))
    .add(ReleaseNoteEntry::new(
      "docs",
      "Chinese contest documentation",
      detail="Rewrite README, package docs, project proposal, and development report in Chinese.",
    ))
}

/// A summary card for judges and project reviewers.
pub(all) struct ReviewerSummary {
  project : String
  package_name : String
  version : String
  github_url : String
  package_url : String
  highlights : Array[String]
  verification : Array[String]
} derive(Eq, Debug)

/// Create a reviewer summary.
pub fn ReviewerSummary::new(
  project? : String = "MoonBench",
  package_name? : String = "Han-Wentao/moonbench",
  version? : String = "0.2.0",
  github_url? : String = "https://github.com/Han-Wentao/moonbench",
  package_url? : String = "https://mooncakes.io/docs/Han-Wentao/moonbench",
) -> ReviewerSummary {
  {
    project,
    package_name,
    version,
    github_url,
    package_url,
    highlights: [],
    verification: [],
  }
}

/// Add a highlight.
pub fn ReviewerSummary::add_highlight(
  self : ReviewerSummary,
  highlight : String,
) -> ReviewerSummary {
  let highlights = self.highlights.copy()
  highlights.push(highlight)
  { ..self, highlights }
}

/// Add a verification command or evidence line.
pub fn ReviewerSummary::add_verification(
  self : ReviewerSummary,
  line : String,
) -> ReviewerSummary {
  let verification = self.verification.copy()
  verification.push(line)
  { ..self, verification }
}

/// Render reviewer summary as Markdown.
pub fn ReviewerSummary::to_markdown(self : ReviewerSummary) -> String {
  let mut body = "## \{escape_markdown(self.project)} 评审摘要\n\n"
  body = body + "- 包名：`\{escape_markdown(self.package_name)}`\n"
  body = body + "- 版本：`\{escape_markdown(self.version)}`\n"
  body = body + "- GitHub：\{self.github_url}\n"
  body = body + "- mooncakes.io：\{self.package_url}\n\n"
  body = body + "### 亮点\n\n"
  for highlight in self.highlights {
    body = body + "- \{escape_markdown(highlight)}\n"
  }
  body = body + "\n### 验证\n\n"
  for line in self.verification {
    body = body + "- `\{escape_markdown(line)}`\n"
  }
  body
}

/// Render reviewer summary as JSON.
pub fn ReviewerSummary::to_json(self : ReviewerSummary) -> String {
  "{" +
  "\"project\":\"\{escape_json(self.project)}\"," +
  "\"package_name\":\"\{escape_json(self.package_name)}\"," +
  "\"version\":\"\{escape_json(self.version)}\"," +
  "\"github_url\":\"\{escape_json(self.github_url)}\"," +
  "\"package_url\":\"\{escape_json(self.package_url)}\"," +
  "\"highlights\":\{string_array_to_json(self.highlights)}," +
  "\"verification\":\{string_array_to_json(self.verification)}" +
  "}"
}

/// Standard reviewer summary for MoonBench.
pub fn ReviewerSummary::moonbench_standard() -> ReviewerSummary {
  ReviewerSummary::new()
    .add_highlight("MoonBit 原生实现的性能报告工具包")
    .add_highlight("支持 Stopwatch、SampleStats、BenchmarkRunner、BenchmarkSuite")
    .add_highlight("支持 Markdown、JSON、CSV 三类输出")
    .add_highlight("支持历史基线对比、趋势分析和质量门禁")
    .add_highlight("提供中文 README、开发报告、项目方案和提交清单")
    .add_verification("moon check")
    .add_verification("moon test")
    .add_verification("moon run cmd/main")
    .add_verification("moon run examples/basic")
    .add_verification("moon package")
}

/// A GitHub step summary document.
pub(all) struct GitHubStepSummary {
  title : String
  badges : BadgeSet
  reviewer_summary : ReviewerSummary
  suite : BenchmarkSuite
  gate : GateReport
} derive(Eq, Debug)

/// Create a GitHub step summary.
pub fn GitHubStepSummary::new(
  title? : String = "MoonBench CI Summary",
  badges? : BadgeSet = BadgeSet::moonbench_standard(),
  reviewer_summary? : ReviewerSummary = ReviewerSummary::moonbench_standard(),
  suite? : BenchmarkSuite = BenchmarkSuite::new(title="Empty Suite"),
  gate? : GateReport = GateReport::new(),
) -> GitHubStepSummary {
  { title, badges, reviewer_summary, suite, gate }
}

/// Render GitHub step summary Markdown.
pub fn GitHubStepSummary::to_markdown(self : GitHubStepSummary) -> String {
  "# \{escape_markdown(self.title)}\n\n" +
  self.badges.to_markdown() + "\n\n" +
  self.reviewer_summary.to_markdown() + "\n\n" +
  self.suite.to_markdown() + "\n\n" +
  self.gate.to_markdown()
}

/// Render GitHub step summary JSON metadata.
pub fn GitHubStepSummary::to_json(self : GitHubStepSummary) -> String {
  "{" +
  "\"title\":\"\{escape_json(self.title)}\"," +
  "\"badges\":\{self.badges.to_json()}," +
  "\"reviewer_summary\":\{self.reviewer_summary.to_json()}," +
  "\"suite\":\{self.suite.to_json()}," +
  "\"gate\":\{self.gate.to_json()}" +
  "}"
}
