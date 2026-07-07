/// A generated artifact that can be attached to CI or contest submission.
pub(all) struct Artifact {
  name : String
  kind : String
  path : String
  media_type : String
  description : String
  required : Bool
} derive(Eq, Debug)

/// Create a generic artifact descriptor.
pub fn Artifact::new(
  name : String,
  kind? : String = "file",
  path? : String = "",
  media_type? : String = "text/plain",
  description? : String = "",
  required? : Bool = false,
) -> Artifact {
  { name, kind, path, media_type, description, required }
}

/// Create a Markdown artifact descriptor.
pub fn Artifact::markdown(name : String, path : String, description? : String = "") -> Artifact {
  Artifact::new(
    name,
    kind="markdown",
    path=path,
    media_type="text/markdown",
    description=description,
    required=true,
  )
}

/// Create a JSON artifact descriptor.
pub fn Artifact::json(name : String, path : String, description? : String = "") -> Artifact {
  Artifact::new(
    name,
    kind="json",
    path=path,
    media_type="application/json",
    description=description,
    required=false,
  )
}

/// Create a CSV artifact descriptor.
pub fn Artifact::csv(name : String, path : String, description? : String = "") -> Artifact {
  Artifact::new(
    name,
    kind="csv",
    path=path,
    media_type="text/csv",
    description=description,
    required=false,
  )
}

/// Create a zip artifact descriptor.
pub fn Artifact::zip(name : String, path : String, description? : String = "") -> Artifact {
  Artifact::new(
    name,
    kind="zip",
    path=path,
    media_type="application/zip",
    description=description,
    required=true,
  )
}

/// Whether the artifact has a usable path.
pub fn Artifact::has_path(self : Artifact) -> Bool {
  self.path != ""
}

/// Render an artifact as one Markdown table row.
pub fn Artifact::to_markdown_row(self : Artifact) -> String {
  "| \{escape_markdown(self.name)} | \{self.kind} | `\{escape_markdown(self.path)}` | \{self.required} | \{escape_markdown(self.description)} |\n"
}

/// Render an artifact as compact JSON.
pub fn Artifact::to_json(self : Artifact) -> String {
  "{" +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"kind\":\"\{escape_json(self.kind)}\"," +
  "\"path\":\"\{escape_json(self.path)}\"," +
  "\"media_type\":\"\{escape_json(self.media_type)}\"," +
  "\"description\":\"\{escape_json(self.description)}\"," +
  "\"required\":\{self.required}" +
  "}"
}

/// A bundle of generated or expected artifacts.
pub(all) struct ArtifactBundle {
  title : String
  artifacts : Array[Artifact]
} derive(Eq, Debug)

/// Create an empty artifact bundle.
pub fn ArtifactBundle::new(title? : String = "MoonBench Artifacts") -> ArtifactBundle {
  { title, artifacts: [] }
}

/// Return a new bundle with one artifact appended.
pub fn ArtifactBundle::add(self : ArtifactBundle, artifact : Artifact) -> ArtifactBundle {
  let artifacts = self.artifacts.copy()
  artifacts.push(artifact)
  { ..self, artifacts }
}

/// Number of artifacts.
pub fn ArtifactBundle::count(self : ArtifactBundle) -> Int {
  self.artifacts.length()
}

/// Number of required artifacts.
pub fn ArtifactBundle::required_count(self : ArtifactBundle) -> Int {
  for artifact in self.artifacts; acc = 0 {
    if artifact.required {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

/// Number of artifacts with a path.
pub fn ArtifactBundle::with_path_count(self : ArtifactBundle) -> Int {
  for artifact in self.artifacts; acc = 0 {
    if artifact.has_path() {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

/// Whether every required artifact has a path.
pub fn ArtifactBundle::required_paths_ready(self : ArtifactBundle) -> Bool {
  for artifact in self.artifacts {
    if artifact.required && !artifact.has_path() {
      return false
    }
  }
  true
}

/// Render artifact bundle as Markdown.
pub fn ArtifactBundle::to_markdown(self : ArtifactBundle) -> String {
  let mut body = "## \{escape_markdown(self.title)}\n\n"
  body = body + "- Total: \{self.count()}\n"
  body = body + "- Required: \{self.required_count()}\n"
  body = body + "- With path: \{self.with_path_count()}\n"
  body = body + "- Required paths ready: \{self.required_paths_ready()}\n\n"
  body = body + "| name | kind | path | required | description |\n"
  body = body + "| --- | --- | --- | --- | --- |\n"
  for artifact in self.artifacts {
    body = body + artifact.to_markdown_row()
  }
  body
}

/// Render artifact bundle as compact JSON.
pub fn ArtifactBundle::to_json(self : ArtifactBundle) -> String {
  let mut body = "{"
  body = body + "\"title\":\"\{escape_json(self.title)}\","
  body = body + "\"total\":\{self.count()},"
  body = body + "\"required\":\{self.required_count()},"
  body = body + "\"with_path\":\{self.with_path_count()},"
  body = body + "\"required_paths_ready\":\{self.required_paths_ready()},"
  body = body + "\"artifacts\":["
  for i in 0..<self.artifacts.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.artifacts[i].to_json()
  }
  body + "]}"
}

/// One Markdown section with a title and body.
pub(all) struct MarkdownSection {
  title : String
  level : Int
  body : String
} derive(Eq, Debug)

/// Create a Markdown section.
pub fn MarkdownSection::new(title : String, body? : String = "", level? : Int = 2) -> MarkdownSection {
  { title, body, level: clamp_markdown_level(level) }
}

fn clamp_markdown_level(level : Int) -> Int {
  if level < 1 {
    1
  } else if level > 6 {
    6
  } else {
    level
  }
}

fn heading_prefix(level : Int) -> String {
  if level <= 1 {
    "#"
  } else if level == 2 {
    "##"
  } else if level == 3 {
    "###"
  } else if level == 4 {
    "####"
  } else if level == 5 {
    "#####"
  } else {
    "######"
  }
}

/// Render a Markdown section.
pub fn MarkdownSection::render(self : MarkdownSection) -> String {
  heading_prefix(self.level) + " " + self.title + "\n\n" + self.body + "\n"
}

/// A composable Markdown document.
pub(all) struct MarkdownDocument {
  title : String
  intro : String
  sections : Array[MarkdownSection]
} derive(Eq, Debug)

/// Create a Markdown document.
pub fn MarkdownDocument::new(title : String, intro? : String = "") -> MarkdownDocument {
  { title, intro, sections: [] }
}

/// Append a section.
pub fn MarkdownDocument::add_section(
  self : MarkdownDocument,
  section : MarkdownSection,
) -> MarkdownDocument {
  let sections = self.sections.copy()
  sections.push(section)
  { ..self, sections }
}

/// Append a section from title and body.
pub fn MarkdownDocument::section(
  self : MarkdownDocument,
  title : String,
  body : String,
  level? : Int = 2,
) -> MarkdownDocument {
  self.add_section(MarkdownSection::new(title, body=body, level=level))
}

/// Number of sections.
pub fn MarkdownDocument::section_count(self : MarkdownDocument) -> Int {
  self.sections.length()
}

/// Render the document.
pub fn MarkdownDocument::render(self : MarkdownDocument) -> String {
  let mut body = "# \{self.title}\n\n"
  if self.intro != "" {
    body = body + self.intro + "\n\n"
  }
  for section in self.sections {
    body = body + section.render() + "\n"
  }
  body
}

/// Add a benchmark suite section.
pub fn MarkdownDocument::with_suite(
  self : MarkdownDocument,
  suite : BenchmarkSuite,
  title? : String = "Benchmark Suite",
) -> MarkdownDocument {
  self.section(title, suite.to_markdown(), level=2)
}

/// Add a comparison report section.
pub fn MarkdownDocument::with_comparison(
  self : MarkdownDocument,
  report : ComparisonReport,
  title? : String = "Baseline Comparison",
) -> MarkdownDocument {
  self.section(title, report.to_markdown(), level=2)
}

/// Add a quality gate section.
pub fn MarkdownDocument::with_gate(
  self : MarkdownDocument,
  gate : GateReport,
  title? : String = "Quality Gate",
) -> MarkdownDocument {
  self.section(title, gate.to_markdown(), level=2)
}

/// Add an artifact bundle section.
pub fn MarkdownDocument::with_artifacts(
  self : MarkdownDocument,
  bundle : ArtifactBundle,
  title? : String = "Artifacts",
) -> MarkdownDocument {
  self.section(title, bundle.to_markdown(), level=2)
}

/// A checklist item for release and contest submission.
pub(all) struct ChecklistItem {
  id : String
  title : String
  description : String
  done : Bool
  evidence : String
  required : Bool
} derive(Eq, Debug)

/// Create a checklist item.
pub fn ChecklistItem::new(
  id : String,
  title : String,
  description? : String = "",
  done? : Bool = false,
  evidence? : String = "",
  required? : Bool = true,
) -> ChecklistItem {
  { id, title, description, done, evidence, required }
}

/// Mark a checklist item as done.
pub fn ChecklistItem::complete(self : ChecklistItem, evidence : String) -> ChecklistItem {
  { ..self, done: true, evidence }
}

/// Mark a checklist item as pending.
pub fn ChecklistItem::pending(self : ChecklistItem, evidence? : String = "") -> ChecklistItem {
  { ..self, done: false, evidence }
}

/// Render a checklist item as Markdown row.
pub fn ChecklistItem::to_markdown_row(self : ChecklistItem) -> String {
  let mark = if self.done { "x" } else { " " }
  "| [\{mark}] | \{escape_markdown(self.id)} | \{escape_markdown(self.title)} | \{self.required} | \{escape_markdown(self.evidence)} |\n"
}

/// Render a checklist item as JSON.
pub fn ChecklistItem::to_json(self : ChecklistItem) -> String {
  "{" +
  "\"id\":\"\{escape_json(self.id)}\"," +
  "\"title\":\"\{escape_json(self.title)}\"," +
  "\"description\":\"\{escape_json(self.description)}\"," +
  "\"done\":\{self.done}," +
  "\"evidence\":\"\{escape_json(self.evidence)}\"," +
  "\"required\":\{self.required}" +
  "}"
}

/// A checklist with completion metrics.
pub(all) struct SubmissionChecklist {
  title : String
  items : Array[ChecklistItem]
} derive(Eq, Debug)

/// Create an empty submission checklist.
pub fn SubmissionChecklist::new(title? : String = "MoonBench Submission Checklist") -> SubmissionChecklist {
  { title, items: [] }
}

/// Append a checklist item.
pub fn SubmissionChecklist::add(
  self : SubmissionChecklist,
  item : ChecklistItem,
) -> SubmissionChecklist {
  let items = self.items.copy()
  items.push(item)
  { ..self, items }
}

/// Number of checklist items.
pub fn SubmissionChecklist::count(self : SubmissionChecklist) -> Int {
  self.items.length()
}

/// Number of required checklist items.
pub fn SubmissionChecklist::required_count(self : SubmissionChecklist) -> Int {
  for item in self.items; acc = 0 {
    if item.required {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

/// Number of completed items.
pub fn SubmissionChecklist::done_count(self : SubmissionChecklist) -> Int {
  for item in self.items; acc = 0 {
    if item.done {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

/// Number of incomplete required items.
pub fn SubmissionChecklist::missing_required_count(self : SubmissionChecklist) -> Int {
  for item in self.items; acc = 0 {
    if item.required && !item.done {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

/// Whether all required items are complete.
pub fn SubmissionChecklist::ready(self : SubmissionChecklist) -> Bool {
  self.missing_required_count() == 0
}

/// Completion ratio for all items.
pub fn SubmissionChecklist::completion_ratio(self : SubmissionChecklist) -> Double {
  if self.items.length() == 0 {
    0.0
  } else {
    self.done_count().to_double() / self.items.length().to_double()
  }
}

/// Render checklist as Markdown.
pub fn SubmissionChecklist::to_markdown(self : SubmissionChecklist) -> String {
  let mut body = "## \{escape_markdown(self.title)}\n\n"
  body = body + "- Total: \{self.count()}\n"
  body = body + "- Required: \{self.required_count()}\n"
  body = body + "- Done: \{self.done_count()}\n"
  body = body + "- Missing required: \{self.missing_required_count()}\n"
  body = body + "- Ready: \{self.ready()}\n\n"
  body = body + "| done | id | title | required | evidence |\n"
  body = body + "| --- | --- | --- | --- | --- |\n"
  for item in self.items {
    body = body + item.to_markdown_row()
  }
  body
}

/// Render checklist as compact JSON.
pub fn SubmissionChecklist::to_json(self : SubmissionChecklist) -> String {
  let mut body = "{"
  body = body + "\"title\":\"\{escape_json(self.title)}\","
  body = body + "\"total\":\{self.count()},"
  body = body + "\"required\":\{self.required_count()},"
  body = body + "\"done\":\{self.done_count()},"
  body = body + "\"missing_required\":\{self.missing_required_count()},"
  body = body + "\"ready\":\{self.ready()},"
  body = body + "\"items\":["
  for i in 0..<self.items.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.items[i].to_json()
  }
  body + "]}"
}

/// Standard checklist for MoonBench contest submission.
pub fn SubmissionChecklist::moonbench_standard() -> SubmissionChecklist {
  SubmissionChecklist::new()
    .add(ChecklistItem::new(
      "public-repo",
      "公开 GitHub 仓库",
      done=true,
      evidence="https://github.com/Han-Wentao/moonbench",
    ))
    .add(ChecklistItem::new(
      "readme",
      "中文 README 与 mooncakes 文档",
      done=true,
      evidence="README.md, README.mbt.md",
    ))
    .add(ChecklistItem::new(
      "tests",
      "MoonBit 测试可运行",
      done=true,
      evidence="moon test",
    ))
    .add(ChecklistItem::new(
      "ci",
      "GitHub Actions CI",
      done=true,
      evidence=".github/workflows/ci.yml",
    ))
    .add(ChecklistItem::new(
      "examples",
      "可运行示例",
      done=true,
      evidence="moon run cmd/main; moon run examples/basic",
    ))
    .add(ChecklistItem::new(
      "mooncakes",
      "mooncakes.io 发布",
      done=true,
      evidence="https://mooncakes.io/docs/Han-Wentao/moonbench",
    ))
    .add(ChecklistItem::new(
      "gitlink",
      "GitLink 仓库同步",
      done=false,
      evidence="用户最终提交前确认",
    ))
    .add(ChecklistItem::new(
      "final-form",
      "比赛作品提交表单",
      done=false,
      evidence="用户本人确认提交",
    ))
}

/// Standard artifact bundle for MoonBench submission.
pub fn ArtifactBundle::moonbench_standard() -> ArtifactBundle {
  ArtifactBundle::new(title="MoonBench Submission Artifacts")
    .add(Artifact::markdown(
      "中文 README",
      "README.md",
      description="项目首页说明",
    ))
    .add(Artifact::markdown(
      "Mooncakes 包文档",
      "README.mbt.md",
      description="发布到 mooncakes.io 的包文档",
    ))
    .add(Artifact::markdown(
      "开发报告",
      "docs/development-report.md",
      description="中文开发报告，可导出 PDF 上传",
    ))
    .add(Artifact::markdown(
      "项目方案",
      "docs/project-proposal.md",
      description="项目定位与技术路线",
    ))
    .add(Artifact::zip(
      "源码提交包",
      "_build/submission/moonbench-source-submission.zip",
      description="最终提交可上传的源码包",
    ))
    .add(Artifact::zip(
      "mooncakes 发布包",
      "_build/publish/Han-Wentao-moonbench-0.2.0.zip",
      description="moon package 生成的发布包",
    ))
}
