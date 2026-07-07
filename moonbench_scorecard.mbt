/// One score item in a project rubric.
pub(all) struct ScoreItem {
  id : String
  title : String
  description : String
  max_score : Int
  earned_score : Int
  passed : Bool
  evidence : String
  required : Bool
} derive(Eq, Debug)

/// Create a score item.
pub fn ScoreItem::new(
  id : String,
  title : String,
  description? : String = "",
  max_score? : Int = 1,
  earned_score? : Int = 0,
  passed? : Bool = false,
  evidence? : String = "",
  required? : Bool = true,
) -> ScoreItem {
  let max_score = clamp_non_negative(max_score)
  let earned_score = clamp_score(earned_score, max_score)
  { id, title, description, max_score, earned_score, passed, evidence, required }
}

fn clamp_score(value : Int, max_score : Int) -> Int {
  if value < 0 {
    0
  } else if value > max_score {
    max_score
  } else {
    value
  }
}

/// Mark an item as fully passed.
pub fn ScoreItem::pass(self : ScoreItem, evidence : String) -> ScoreItem {
  { ..self, earned_score: self.max_score, passed: true, evidence }
}

/// Mark an item as partially earned.
pub fn ScoreItem::partial(self : ScoreItem, score : Int, evidence : String) -> ScoreItem {
  let earned = clamp_score(score, self.max_score)
  { ..self, earned_score: earned, passed: earned == self.max_score, evidence }
}

/// Mark an item as failed.
pub fn ScoreItem::fail(self : ScoreItem, evidence : String) -> ScoreItem {
  { ..self, earned_score: 0, passed: false, evidence }
}

/// Completion ratio for the item.
pub fn ScoreItem::ratio(self : ScoreItem) -> Double {
  if self.max_score == 0 {
    1.0
  } else {
    self.earned_score.to_double() / self.max_score.to_double()
  }
}

/// Render score item as Markdown row.
pub fn ScoreItem::to_markdown_row(self : ScoreItem) -> String {
  "| \{escape_markdown(self.id)} | \{escape_markdown(self.title)} | \{self.earned_score}/\{self.max_score} | \{self.passed} | \{self.required} | \{escape_markdown(self.evidence)} |\n"
}

/// Render score item as JSON.
pub fn ScoreItem::to_json(self : ScoreItem) -> String {
  "{" +
  "\"id\":\"\{escape_json(self.id)}\"," +
  "\"title\":\"\{escape_json(self.title)}\"," +
  "\"description\":\"\{escape_json(self.description)}\"," +
  "\"max_score\":\{self.max_score}," +
  "\"earned_score\":\{self.earned_score}," +
  "\"passed\":\{self.passed}," +
  "\"evidence\":\"\{escape_json(self.evidence)}\"," +
  "\"required\":\{self.required}" +
  "}"
}

/// A score section in a project rubric.
pub(all) struct ScoreSection {
  id : String
  title : String
  items : Array[ScoreItem]
} derive(Eq, Debug)

/// Create an empty score section.
pub fn ScoreSection::new(id : String, title : String) -> ScoreSection {
  { id, title, items: [] }
}

/// Append an item.
pub fn ScoreSection::add(self : ScoreSection, item : ScoreItem) -> ScoreSection {
  let items = self.items.copy()
  items.push(item)
  { ..self, items }
}

/// Number of score items.
pub fn ScoreSection::count(self : ScoreSection) -> Int {
  self.items.length()
}

/// Maximum score in this section.
pub fn ScoreSection::max_score(self : ScoreSection) -> Int {
  for item in self.items; acc = 0 {
    continue acc + item.max_score
  } nobreak {
    acc
  }
}

/// Earned score in this section.
pub fn ScoreSection::earned_score(self : ScoreSection) -> Int {
  for item in self.items; acc = 0 {
    continue acc + item.earned_score
  } nobreak {
    acc
  }
}

/// Missing required items in this section.
pub fn ScoreSection::missing_required_count(self : ScoreSection) -> Int {
  for item in self.items; acc = 0 {
    if item.required && !item.passed {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

/// Ratio for this section.
pub fn ScoreSection::ratio(self : ScoreSection) -> Double {
  let max_score = self.max_score()
  if max_score == 0 {
    1.0
  } else {
    self.earned_score().to_double() / max_score.to_double()
  }
}

/// Whether all required items in this section pass.
pub fn ScoreSection::required_passed(self : ScoreSection) -> Bool {
  self.missing_required_count() == 0
}

/// Render section as Markdown.
pub fn ScoreSection::to_markdown(self : ScoreSection) -> String {
  let mut body = "### \{escape_markdown(self.title)}\n\n"
  body = body + "- Score: \{self.earned_score()}/\{self.max_score()}\n"
  body = body + "- Missing required: \{self.missing_required_count()}\n\n"
  body = body + "| id | item | score | passed | required | evidence |\n"
  body = body + "| --- | --- | ---: | --- | --- | --- |\n"
  for item in self.items {
    body = body + item.to_markdown_row()
  }
  body
}

/// Render section as JSON.
pub fn ScoreSection::to_json(self : ScoreSection) -> String {
  let mut body = "{"
  body = body + "\"id\":\"\{escape_json(self.id)}\","
  body = body + "\"title\":\"\{escape_json(self.title)}\","
  body = body + "\"max_score\":\{self.max_score()},"
  body = body + "\"earned_score\":\{self.earned_score()},"
  body = body + "\"missing_required\":\{self.missing_required_count()},"
  body = body + "\"items\":["
  for i in 0..<self.items.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.items[i].to_json()
  }
  body + "]}"
}

/// Full project scorecard.
pub(all) struct ProjectScorecard {
  title : String
  target_loc : Int
  actual_loc : Int
  sections : Array[ScoreSection]
} derive(Eq, Debug)

/// Create an empty project scorecard.
pub fn ProjectScorecard::new(
  title? : String = "MoonBench Scorecard",
  target_loc? : Int = 4800,
  actual_loc? : Int = 0,
) -> ProjectScorecard {
  { title, target_loc, actual_loc, sections: [] }
}

/// Append a score section.
pub fn ProjectScorecard::add_section(
  self : ProjectScorecard,
  section : ScoreSection,
) -> ProjectScorecard {
  let sections = self.sections.copy()
  sections.push(section)
  { ..self, sections }
}

/// Number of sections.
pub fn ProjectScorecard::section_count(self : ProjectScorecard) -> Int {
  self.sections.length()
}

/// Number of score items.
pub fn ProjectScorecard::item_count(self : ProjectScorecard) -> Int {
  for section in self.sections; acc = 0 {
    continue acc + section.count()
  } nobreak {
    acc
  }
}

/// Total maximum score.
pub fn ProjectScorecard::max_score(self : ProjectScorecard) -> Int {
  for section in self.sections; acc = 0 {
    continue acc + section.max_score()
  } nobreak {
    acc
  }
}

/// Total earned score.
pub fn ProjectScorecard::earned_score(self : ProjectScorecard) -> Int {
  for section in self.sections; acc = 0 {
    continue acc + section.earned_score()
  } nobreak {
    acc
  }
}

/// Missing required item count.
pub fn ProjectScorecard::missing_required_count(self : ProjectScorecard) -> Int {
  for section in self.sections; acc = 0 {
    continue acc + section.missing_required_count()
  } nobreak {
    acc
  }
}

/// Score ratio.
pub fn ProjectScorecard::ratio(self : ProjectScorecard) -> Double {
  let max_score = self.max_score()
  if max_score == 0 {
    1.0
  } else {
    self.earned_score().to_double() / max_score.to_double()
  }
}

/// Whether LOC target is reached.
pub fn ProjectScorecard::loc_ready(self : ProjectScorecard) -> Bool {
  self.actual_loc >= self.target_loc
}

/// Whether all required items and LOC target pass.
pub fn ProjectScorecard::ready(self : ProjectScorecard) -> Bool {
  self.loc_ready() && self.missing_required_count() == 0
}

/// Grade from the current score ratio.
pub fn ProjectScorecard::grade(self : ProjectScorecard) -> String {
  let ratio = self.ratio()
  if !self.ready() {
    "incomplete"
  } else if ratio >= 0.95 {
    "excellent"
  } else if ratio >= 0.85 {
    "strong"
  } else if ratio >= 0.70 {
    "accepted"
  } else {
    "weak"
  }
}

/// Render scorecard as Markdown.
pub fn ProjectScorecard::to_markdown(self : ProjectScorecard) -> String {
  let mut body = "## \{escape_markdown(self.title)}\n\n"
  body = body + "- Target MoonBit LOC: \{self.target_loc}\n"
  body = body + "- Actual MoonBit LOC: \{self.actual_loc}\n"
  body = body + "- LOC ready: \{self.loc_ready()}\n"
  body = body + "- Score: \{self.earned_score()}/\{self.max_score()}\n"
  body = body + "- Missing required: \{self.missing_required_count()}\n"
  body = body + "- Ready: \{self.ready()}\n"
  body = body + "- Grade: \{self.grade()}\n\n"
  for section in self.sections {
    body = body + section.to_markdown() + "\n"
  }
  body
}

/// Render scorecard as JSON.
pub fn ProjectScorecard::to_json(self : ProjectScorecard) -> String {
  let mut body = "{"
  body = body + "\"title\":\"\{escape_json(self.title)}\","
  body = body + "\"target_loc\":\{self.target_loc},"
  body = body + "\"actual_loc\":\{self.actual_loc},"
  body = body + "\"loc_ready\":\{self.loc_ready()},"
  body = body + "\"max_score\":\{self.max_score()},"
  body = body + "\"earned_score\":\{self.earned_score()},"
  body = body + "\"missing_required\":\{self.missing_required_count()},"
  body = body + "\"ready\":\{self.ready()},"
  body = body + "\"grade\":\"\{escape_json(self.grade())}\","
  body = body + "\"sections\":["
  for i in 0..<self.sections.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.sections[i].to_json()
  }
  body + "]}"
}

/// Build the standard excellent-work scorecard.
pub fn ProjectScorecard::moonbench_standard(actual_loc? : Int = 0) -> ProjectScorecard {
  ProjectScorecard::new(actual_loc=actual_loc)
    .add_section(ScoreSection::new("official", "官方验收底线")
      .add(ScoreItem::new(
        "moonbit-primary",
        "MoonBit 为主要实现语言",
        max_score=10,
      ).pass("核心库、测试、示例均为 MoonBit"))
      .add(ScoreItem::new(
        "public-repo",
        "公开仓库",
        max_score=10,
      ).pass("https://github.com/Han-Wentao/moonbench"))
      .add(ScoreItem::new(
        "readme",
        "清晰 README",
        max_score=10,
      ).pass("中文 README.md 和 README.mbt.md"))
      .add(ScoreItem::new(
        "examples",
        "可运行示例",
        max_score=10,
      ).pass("cmd/main 与 examples/basic"))
      .add(ScoreItem::new(
        "ci",
        "CI",
        max_score=10,
      ).pass(".github/workflows/ci.yml"))
      .add(ScoreItem::new(
        "tests",
        "测试",
        max_score=10,
      ).pass("moon test"))
      .add(ScoreItem::new(
        "mooncakes",
        "mooncakes.io 发布",
        max_score=10,
      ).pass("https://mooncakes.io/docs/Han-Wentao/moonbench"))
      .add(ScoreItem::new(
        "license",
        "开源许可证",
        max_score=5,
      ).pass("MIT License")))
    .add_section(ScoreSection::new("excellent", "优秀作品增强项")
      .add(ScoreItem::new(
        "loc",
        "4800+ MoonBit LOC",
        max_score=15,
      ).partial(if actual_loc >= 4800 { 15 } else { 0 }, "target=4800 actual=\{actual_loc}"))
      .add(ScoreItem::new(
        "report-chain",
        "完整性能报告链路",
        max_score=10,
      ).pass("suite, trend, gate, snapshot, artifact"))
      .add(ScoreItem::new(
        "formats",
        "多格式输出",
        max_score=10,
      ).pass("Markdown, JSON, CSV, badge, GitHub summary"))
      .add(ScoreItem::new(
        "chinese-docs",
        "中文正式文档",
        max_score=10,
      ).pass("README, project proposal, development report, acceptance matrix"))
      .add(ScoreItem::new(
        "submission-ready",
        "提交材料闭环",
        max_score=10,
        required=false,
      ).partial(8, "GitLink 与最终表单需用户确认"))
      .add(ScoreItem::new(
        "maintainability",
        "可维护性",
        max_score=10,
      ).pass("模块化 API、测试覆盖、CI 验证")))
}
