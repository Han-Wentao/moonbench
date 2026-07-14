///|
/// A reusable documentation template fragment.
pub(all) struct DocTemplate {
  id : String
  title : String
  audience : String
  purpose : String
  body : String
  required : Bool
} derive(Eq, Debug)

///|
/// Create a documentation template fragment.
pub fn DocTemplate::new(
  id : String,
  title : String,
  audience? : String = "developer",
  purpose? : String = "",
  body? : String = "",
  required? : Bool = true,
) -> DocTemplate {
  { id, title, audience, purpose, body, required }
}

///|
/// Render a documentation template as Markdown.
pub fn DocTemplate::to_markdown(self : DocTemplate) -> String {
  "### \{escape_markdown(self.title)}\n\n" +
  "- ID: `\{escape_markdown(self.id)}`\n" +
  "- Audience: \{escape_markdown(self.audience)}\n" +
  "- Purpose: \{escape_markdown(self.purpose)}\n" +
  "- Required: \{self.required}\n\n" +
  self.body +
  "\n"
}

///|
/// Render a template as Markdown row.
pub fn DocTemplate::to_markdown_row(self : DocTemplate) -> String {
  "| \{escape_markdown(self.id)} | \{escape_markdown(self.title)} | \{escape_markdown(self.audience)} | \{self.required} | \{escape_markdown(self.purpose)} |\n"
}

///|
/// Render a documentation template as JSON.
pub fn DocTemplate::to_json(self : DocTemplate) -> String {
  "{" +
  "\"id\":\"\{escape_json(self.id)}\"," +
  "\"title\":\"\{escape_json(self.title)}\"," +
  "\"audience\":\"\{escape_json(self.audience)}\"," +
  "\"purpose\":\"\{escape_json(self.purpose)}\"," +
  "\"body\":\"\{escape_json(self.body)}\"," +
  "\"required\":\{self.required}" +
  "}"
}

///|
/// A documentation template set.
pub(all) struct DocTemplateSet {
  title : String
  templates : Array[DocTemplate]
} derive(Eq, Debug)

///|
/// Create an empty documentation template set.
pub fn DocTemplateSet::new(
  title? : String = "MoonBench Documentation Templates",
) -> DocTemplateSet {
  { title, templates: [] }
}

///|
/// Append one template.
pub fn DocTemplateSet::add(
  self : DocTemplateSet,
  template : DocTemplate,
) -> DocTemplateSet {
  let templates = self.templates.copy()
  templates.push(template)
  { ..self, templates, }
}

///|
/// Number of templates.
pub fn DocTemplateSet::count(self : DocTemplateSet) -> Int {
  self.templates.length()
}

///|
/// Number of required templates.
pub fn DocTemplateSet::required_count(self : DocTemplateSet) -> Int {
  for template in self.templates; acc = 0 {
    if template.required {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Count templates by audience.
pub fn DocTemplateSet::count_audience(
  self : DocTemplateSet,
  audience : String,
) -> Int {
  for template in self.templates; acc = 0 {
    if template.audience == audience {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Find a template by id.
pub fn DocTemplateSet::find(self : DocTemplateSet, id : String) -> DocTemplate {
  for template in self.templates {
    if template.id == id {
      return template
    }
  }
  DocTemplate::new("", "")
}

///|
/// Whether a template exists.
pub fn DocTemplateSet::contains(self : DocTemplateSet, id : String) -> Bool {
  self.find(id).id != ""
}

///|
/// Render an index of templates.
pub fn DocTemplateSet::to_markdown(self : DocTemplateSet) -> String {
  let mut body = "## \{escape_markdown(self.title)}\n\n"
  body = body + "- Templates: \{self.count()}\n"
  body = body + "- Required: \{self.required_count()}\n\n"
  body = body + "| id | title | audience | required | purpose |\n"
  body = body + "| --- | --- | --- | --- | --- |\n"
  for template in self.templates {
    body = body + template.to_markdown_row()
  }
  body
}

///|
/// Render all template bodies as one Markdown document.
pub fn DocTemplateSet::render_all(self : DocTemplateSet) -> String {
  let mut body = "# \{escape_markdown(self.title)}\n\n"
  for template in self.templates {
    body = body + template.to_markdown() + "\n"
  }
  body
}

///|
/// Render template set as JSON.
pub fn DocTemplateSet::to_json(self : DocTemplateSet) -> String {
  let mut body = "{"
  body = body + "\"title\":\"\{escape_json(self.title)}\","
  body = body + "\"count\":\{self.count()},"
  body = body + "\"required\":\{self.required_count()},"
  body = body + "\"templates\":["
  for i in 0..<self.templates.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.templates[i].to_json()
  }
  body + "]}"
}

///|
/// Standard documentation template set for a contest-ready package.
pub fn DocTemplateSet::moonbench_standard() -> DocTemplateSet {
  DocTemplateSet::new()
  .add(
    DocTemplate::new(
      "overview",
      "项目概述",
      audience="reviewer",
      purpose="Explain what the package does and why it matters.",
      body="说明 MoonBench 是 MoonBit 性能报告工具包，覆盖计时、统计、报告、基线对比和质量门禁。",
    ),
  )
  .add(
    DocTemplate::new(
      "install",
      "安装方式",
      audience="developer",
      purpose="Show how to install the mooncakes package.",
      body="使用 `moon add Han-Wentao/moonbench` 安装已发布包。",
    ),
  )
  .add(
    DocTemplate::new(
      "quick-start",
      "快速开始",
      audience="developer",
      purpose="Give a minimal runnable benchmark example.",
      body="展示 BenchmarkRunner、BenchmarkSuite 和 Markdown 输出。",
    ),
  )
  .add(
    DocTemplate::new(
      "api",
      "公开 API",
      audience="developer",
      purpose="List stable public types and functions.",
      body="链接 ApiCatalog，并说明核心类型的职责边界。",
    ),
  )
  .add(
    DocTemplate::new(
      "quality",
      "工程质量",
      audience="reviewer",
      purpose="Show tests, CI, examples, and package publication.",
      body="列出 `moon check`、`moon test`、示例运行、CI 和 mooncakes.io 发布证据。",
    ),
  )
  .add(
    DocTemplate::new(
      "submission",
      "比赛提交",
      audience="participant",
      purpose="Explain final links, uploaded files, and user confirmation steps.",
      body="列出 GitHub、GitLink、mooncakes.io、源码包和开发报告。",
    ),
  )
  .add(
    DocTemplate::new(
      "roadmap",
      "后续规划",
      audience="maintainer",
      purpose="Keep future maintenance direction clear.",
      body="说明基线文件、HTML 报告、更多统计指标和真实 benchmark 场景。",
      required=false,
    ),
  )
}
