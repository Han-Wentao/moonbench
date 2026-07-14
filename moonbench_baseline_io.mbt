///|
/// One diagnostic produced while parsing baseline text.
pub(all) struct BaselineParseIssue {
  line : Int
  content : String
  message : String
} derive(Eq, Debug)

///|
/// Result of parsing a portable MoonBench baseline document.
pub(all) struct BaselineParseReport {
  baselines : BaselineSet
  issues : Array[BaselineParseIssue]
} derive(Eq, Debug)

///|
/// Parse `name=mean_us` lines into a baseline set.
///
/// Empty lines and lines beginning with `#` are ignored. Whitespace around
/// names and values is trimmed. Invalid lines are reported and skipped, while
/// duplicate names use the last valid value.
pub fn BaselineSet::parse_text(text : String) -> BaselineParseReport {
  let mut baselines = BaselineSet::new()
  let issues : Array[BaselineParseIssue] = []
  let mut line_number = 0
  for raw_line in text.split("\n") {
    line_number = line_number + 1
    let line = raw_line.trim().to_owned()
    if line == "" || line.has_prefix("#") {
      continue
    }
    match line.split_once("=") {
      None =>
        issues.push({
          line: line_number,
          content: line,
          message: "expected name=mean_us",
        })
      Some((raw_name, raw_value)) => {
        let name = raw_name.trim().to_owned()
        let value_text = raw_value.trim().to_owned()
        let validation = validate_benchmark_name(name)
        if !validation.ok {
          issues.push({
            line: line_number,
            content: line,
            message: validation.message,
          })
          continue
        }
        match parse_baseline_value(value_text) {
          None =>
            issues.push({
              line: line_number,
              content: line,
              message: "mean_us must be a finite non-negative number",
            })
          Some(value) =>
            if value.is_nan() || value.is_inf() || value < 0.0 {
              issues.push({
                line: line_number,
                content: line,
                message: "mean_us must be a finite non-negative number",
              })
            } else {
              baselines = baselines.set(name, value)
            }
        }
      }
    }
  }
  { baselines, issues }
}

///|
fn parse_baseline_value(text : String) -> Double? {
  try @string.parse_double(text) catch {
    _ => None
  } noraise {
    value => Some(value)
  }
}

///|
/// Whether the complete baseline document parsed without diagnostics.
pub fn BaselineParseReport::is_valid(self : BaselineParseReport) -> Bool {
  self.issues.length() == 0
}

///|
/// Number of accepted, unique baseline entries.
pub fn BaselineParseReport::count(self : BaselineParseReport) -> Int {
  self.baselines.count()
}

///|
/// Number of invalid input lines.
pub fn BaselineParseReport::issue_count(self : BaselineParseReport) -> Int {
  self.issues.length()
}

///|
/// Render parser diagnostics as Markdown for CI summaries.
pub fn BaselineParseReport::issues_to_markdown(
  self : BaselineParseReport,
) -> String {
  if self.issues.length() == 0 {
    return "No baseline parse issues.\n"
  }
  let mut body = "| line | content | issue |\n"
  body = body + "| ---: | --- | --- |\n"
  for issue in self.issues {
    body = body +
      "| \{issue.line} | \{escape_markdown(issue.content)} | \{escape_markdown(issue.message)} |\n"
  }
  body
}
