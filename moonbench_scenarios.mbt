///|
/// A benchmark workload scenario that can be documented and selected.
pub(all) struct WorkloadScenario {
  id : String
  name : String
  category : String
  description : String
  tags : Array[String]
  data_size : Int
  warmup : Int
  iterations : Int
  expected_unit : String
  complexity : String
  priority : Int
} derive(Eq, Debug)

///|
/// Create a workload scenario descriptor.
pub fn WorkloadScenario::new(
  id : String,
  name : String,
  category? : String = "general",
  description? : String = "",
  tags? : Array[String] = [],
  data_size? : Int = 1,
  warmup? : Int = 1,
  iterations? : Int = 10,
  expected_unit? : String = "us",
  complexity? : String = "O(1)",
  priority? : Int = 50,
) -> WorkloadScenario {
  {
    id,
    name,
    category,
    description,
    tags,
    data_size: clamp_positive(data_size),
    warmup: clamp_non_negative(warmup),
    iterations: clamp_positive(iterations),
    expected_unit,
    complexity,
    priority: clamp_priority(priority),
  }
}

///|
fn clamp_priority(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}

///|
/// Build a benchmark runner using this scenario's sampling settings.
pub fn WorkloadScenario::runner(self : WorkloadScenario) -> BenchmarkRunner {
  BenchmarkRunner::new(warmup=self.warmup, iterations=self.iterations)
}

///|
/// Whether the scenario has a tag.
pub fn WorkloadScenario::has_tag(self : WorkloadScenario, tag : String) -> Bool {
  for item in self.tags {
    if item == tag {
      return true
    }
  }
  false
}

///|
/// Whether the scenario belongs to a category.
pub fn WorkloadScenario::is_category(
  self : WorkloadScenario,
  category : String,
) -> Bool {
  self.category == category
}

///|
/// Render tags as comma-separated text.
pub fn WorkloadScenario::tags_text(self : WorkloadScenario) -> String {
  let mut body = ""
  for i in 0..<self.tags.length() {
    if i > 0 {
      body = body + ", "
    }
    body = body + self.tags[i]
  }
  body
}

///|
/// Render a scenario as Markdown row.
pub fn WorkloadScenario::to_markdown_row(self : WorkloadScenario) -> String {
  "| \{escape_markdown(self.id)} | \{escape_markdown(self.name)} | \{escape_markdown(self.category)} | \{self.data_size} | \{self.warmup} | \{self.iterations} | \{escape_markdown(self.complexity)} | \{self.priority} | \{escape_markdown(self.tags_text())} |\n"
}

///|
/// Render a scenario as JSON.
pub fn WorkloadScenario::to_json(self : WorkloadScenario) -> String {
  "{" +
  "\"id\":\"\{escape_json(self.id)}\"," +
  "\"name\":\"\{escape_json(self.name)}\"," +
  "\"category\":\"\{escape_json(self.category)}\"," +
  "\"description\":\"\{escape_json(self.description)}\"," +
  "\"tags\":\{string_array_to_json(self.tags)}," +
  "\"data_size\":\{self.data_size}," +
  "\"warmup\":\{self.warmup}," +
  "\"iterations\":\{self.iterations}," +
  "\"expected_unit\":\"\{escape_json(self.expected_unit)}\"," +
  "\"complexity\":\"\{escape_json(self.complexity)}\"," +
  "\"priority\":\{self.priority}" +
  "}"
}

///|
fn string_array_to_json(values : Array[String]) -> String {
  let mut body = "["
  for i in 0..<values.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + "\"\{escape_json(values[i])}\""
  }
  body + "]"
}

///|
/// A catalog of recommended workload scenarios.
pub(all) struct ScenarioCatalog {
  title : String
  scenarios : Array[WorkloadScenario]
} derive(Eq, Debug)

///|
/// Create an empty scenario catalog.
pub fn ScenarioCatalog::new(
  title? : String = "MoonBench Scenario Catalog",
) -> ScenarioCatalog {
  { title, scenarios: [] }
}

///|
/// Append one scenario.
pub fn ScenarioCatalog::add(
  self : ScenarioCatalog,
  scenario : WorkloadScenario,
) -> ScenarioCatalog {
  let scenarios = self.scenarios.copy()
  scenarios.push(scenario)
  { ..self, scenarios, }
}

///|
/// Number of scenarios.
pub fn ScenarioCatalog::count(self : ScenarioCatalog) -> Int {
  self.scenarios.length()
}

///|
/// Total planned iterations in the catalog.
pub fn ScenarioCatalog::total_iterations(self : ScenarioCatalog) -> Int {
  for scenario in self.scenarios; acc = 0 {
    continue acc + scenario.iterations
  } nobreak {
    acc
  }
}

///|
/// Average priority across scenarios.
pub fn ScenarioCatalog::average_priority(self : ScenarioCatalog) -> Double {
  if self.scenarios.length() == 0 {
    return 0.0
  }
  let total = for scenario in self.scenarios; acc = 0 {
    continue acc + scenario.priority
  } nobreak {
    acc
  }
  total.to_double() / self.scenarios.length().to_double()
}

///|
/// Find a scenario by id.
pub fn ScenarioCatalog::find(
  self : ScenarioCatalog,
  id : String,
) -> WorkloadScenario {
  for scenario in self.scenarios {
    if scenario.id == id {
      return scenario
    }
  }
  WorkloadScenario::new("", "")
}

///|
/// Whether the catalog contains a scenario id.
pub fn ScenarioCatalog::contains_id(
  self : ScenarioCatalog,
  id : String,
) -> Bool {
  self.find(id).id != ""
}

///|
/// Filter scenarios by category.
pub fn ScenarioCatalog::filter_category(
  self : ScenarioCatalog,
  category : String,
) -> ScenarioCatalog {
  let mut catalog = ScenarioCatalog::new(title=self.title + " / " + category)
  for scenario in self.scenarios {
    if scenario.category == category {
      catalog = catalog.add(scenario)
    }
  }
  catalog
}

///|
/// Filter scenarios by tag.
pub fn ScenarioCatalog::filter_tag(
  self : ScenarioCatalog,
  tag : String,
) -> ScenarioCatalog {
  let mut catalog = ScenarioCatalog::new(title=self.title + " / tag:" + tag)
  for scenario in self.scenarios {
    if scenario.has_tag(tag) {
      catalog = catalog.add(scenario)
    }
  }
  catalog
}

///|
/// Filter scenarios with priority greater than or equal to threshold.
pub fn ScenarioCatalog::filter_priority(
  self : ScenarioCatalog,
  minimum_priority : Int,
) -> ScenarioCatalog {
  let mut catalog = ScenarioCatalog::new(title=self.title + " / priority")
  for scenario in self.scenarios {
    if scenario.priority >= minimum_priority {
      catalog = catalog.add(scenario)
    }
  }
  catalog
}

///|
/// Count scenarios by category.
pub fn ScenarioCatalog::count_category(
  self : ScenarioCatalog,
  category : String,
) -> Int {
  for scenario in self.scenarios; acc = 0 {
    if scenario.category == category {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Count scenarios by tag.
pub fn ScenarioCatalog::count_tag(self : ScenarioCatalog, tag : String) -> Int {
  for scenario in self.scenarios; acc = 0 {
    if scenario.has_tag(tag) {
      continue acc + 1
    } else {
      continue acc
    }
  } nobreak {
    acc
  }
}

///|
/// Build a suite with manual estimated costs for all scenarios.
pub fn ScenarioCatalog::estimated_suite(
  self : ScenarioCatalog,
) -> BenchmarkSuite {
  let mut suite = BenchmarkSuite::new(
    title=self.title + " Estimated Costs",
    package_name="Han-Wentao/moonbench",
    package_version="0.2.0",
  )
  for scenario in self.scenarios {
    let runner = scenario.runner()
    let result = runner.run(scenario.id, () => scenario.estimated_cost_us())
    suite = suite.add(result)
  }
  suite
}

///|
/// Estimate cost in microseconds from scenario metadata.
pub fn WorkloadScenario::estimated_cost_us(self : WorkloadScenario) -> Double {
  let size = self.data_size.to_double()
  let complexity_factor = if self.complexity == "O(1)" {
    1.0
  } else if self.complexity == "O(log n)" {
    2.0
  } else if self.complexity == "O(n)" {
    5.0
  } else if self.complexity == "O(n log n)" {
    8.0
  } else if self.complexity == "O(n^2)" {
    20.0
  } else {
    10.0
  }
  size.sqrt() * complexity_factor + self.priority.to_double() / 10.0
}

///|
/// Render catalog as Markdown.
pub fn ScenarioCatalog::to_markdown(self : ScenarioCatalog) -> String {
  let mut body = "## \{escape_markdown(self.title)}\n\n"
  body = body + "- Scenarios: \{self.count()}\n"
  body = body + "- Total iterations: \{self.total_iterations()}\n"
  body = body + "- Average priority: \{self.average_priority()}\n\n"
  body = body +
    "| id | name | category | data_size | warmup | iterations | complexity | priority | tags |\n"
  body = body + "| --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- |\n"
  for scenario in self.scenarios {
    body = body + scenario.to_markdown_row()
  }
  body
}

///|
/// Render catalog as JSON.
pub fn ScenarioCatalog::to_json(self : ScenarioCatalog) -> String {
  let mut body = "{"
  body = body + "\"title\":\"\{escape_json(self.title)}\","
  body = body + "\"count\":\{self.count()},"
  body = body + "\"total_iterations\":\{self.total_iterations()},"
  body = body + "\"average_priority\":\{self.average_priority()},"
  body = body + "\"scenarios\":["
  for i in 0..<self.scenarios.length() {
    if i > 0 {
      body = body + ","
    }
    body = body + self.scenarios[i].to_json()
  }
  body + "]}"
}

///|
/// Build the standard MoonBench scenario catalog.
pub fn ScenarioCatalog::moonbench_standard() -> ScenarioCatalog {
  ScenarioCatalog::new(title="MoonBench Standard Scenario Catalog")
  .add(
    WorkloadScenario::new(
      "counter-small",
      "Small counter update",
      category="state",
      description="Tiny mutable state update used as smoke benchmark",
      tags=["state", "smoke", "micro"],
      data_size=1,
      warmup=2,
      iterations=20,
      complexity="O(1)",
      priority=90,
    ),
  )
  .add(
    WorkloadScenario::new(
      "counter-batch",
      "Batch counter update",
      category="state",
      description="Repeated mutable state updates in one benchmark body",
      tags=["state", "loop", "micro"],
      data_size=100,
      warmup=2,
      iterations=20,
      complexity="O(n)",
      priority=85,
    ),
  )
  .add(
    WorkloadScenario::new(
      "array-scan-small",
      "Small array scan",
      category="array",
      description="Linear traversal over a small array",
      tags=["array", "scan", "linear"],
      data_size=64,
      warmup=3,
      iterations=30,
      complexity="O(n)",
      priority=80,
    ),
  )
  .add(
    WorkloadScenario::new(
      "array-scan-medium",
      "Medium array scan",
      category="array",
      description="Linear traversal over a medium array",
      tags=["array", "scan", "linear"],
      data_size=1024,
      warmup=3,
      iterations=30,
      complexity="O(n)",
      priority=78,
    ),
  )
  .add(
    WorkloadScenario::new(
      "array-build",
      "Array build",
      category="array",
      description="Append values to a fresh array",
      tags=["array", "allocation", "append"],
      data_size=512,
      warmup=3,
      iterations=25,
      complexity="O(n)",
      priority=76,
    ),
  )
  .add(
    WorkloadScenario::new(
      "array-copy",
      "Array copy",
      category="array",
      description="Copy a prepared array before mutation",
      tags=["array", "copy", "memory"],
      data_size=512,
      warmup=3,
      iterations=25,
      complexity="O(n)",
      priority=75,
    ),
  )
  .add(
    WorkloadScenario::new(
      "sort-small",
      "Small sort",
      category="algorithm",
      description="Sort a small numeric collection",
      tags=["sort", "algorithm", "array"],
      data_size=64,
      warmup=3,
      iterations=20,
      complexity="O(n log n)",
      priority=82,
    ),
  )
  .add(
    WorkloadScenario::new(
      "sort-medium",
      "Medium sort",
      category="algorithm",
      description="Sort a medium numeric collection",
      tags=["sort", "algorithm", "array"],
      data_size=1024,
      warmup=3,
      iterations=15,
      complexity="O(n log n)",
      priority=80,
    ),
  )
  .add(
    WorkloadScenario::new(
      "string-concat-small",
      "Small string concat",
      category="string",
      description="Build a short string with repeated concatenation",
      tags=["string", "concat", "allocation"],
      data_size=32,
      warmup=2,
      iterations=20,
      complexity="O(n)",
      priority=70,
    ),
  )
  .add(
    WorkloadScenario::new(
      "string-escape-json",
      "JSON escaping",
      category="string",
      description="Escape text for JSON benchmark artifacts",
      tags=["string", "json", "report"],
      data_size=256,
      warmup=2,
      iterations=20,
      complexity="O(n)",
      priority=84,
    ),
  )
  .add(
    WorkloadScenario::new(
      "markdown-row",
      "Markdown row rendering",
      category="report",
      description="Render one benchmark row for Markdown",
      tags=["markdown", "report", "format"],
      data_size=1,
      warmup=2,
      iterations=25,
      complexity="O(1)",
      priority=88,
    ),
  )
  .add(
    WorkloadScenario::new(
      "json-result",
      "JSON result rendering",
      category="report",
      description="Render benchmark result JSON",
      tags=["json", "report", "format"],
      data_size=10,
      warmup=2,
      iterations=25,
      complexity="O(n)",
      priority=88,
    ),
  )
  .add(
    WorkloadScenario::new(
      "csv-suite",
      "CSV suite rendering",
      category="report",
      description="Render a suite as CSV",
      tags=["csv", "report", "format"],
      data_size=20,
      warmup=2,
      iterations=25,
      complexity="O(n)",
      priority=86,
    ),
  )
  .add(
    WorkloadScenario::new(
      "baseline-lookup",
      "Baseline lookup",
      category="baseline",
      description="Find a baseline by benchmark name",
      tags=["baseline", "lookup", "comparison"],
      data_size=50,
      warmup=2,
      iterations=25,
      complexity="O(n)",
      priority=90,
    ),
  )
  .add(
    WorkloadScenario::new(
      "baseline-compare",
      "Baseline compare",
      category="baseline",
      description="Compare benchmark result with historical mean",
      tags=["baseline", "comparison", "gate"],
      data_size=50,
      warmup=2,
      iterations=25,
      complexity="O(n)",
      priority=90,
    ),
  )
  .add(
    WorkloadScenario::new(
      "trend-analysis",
      "Trend analysis",
      category="analysis",
      description="Analyze a sample series for direction and noise",
      tags=["trend", "analysis", "quality"],
      data_size=30,
      warmup=2,
      iterations=20,
      complexity="O(n)",
      priority=87,
    ),
  )
  .add(
    WorkloadScenario::new(
      "moving-average",
      "Moving average",
      category="analysis",
      description="Compute a moving average over a sample series",
      tags=["trend", "analysis", "window"],
      data_size=60,
      warmup=2,
      iterations=20,
      complexity="O(n)",
      priority=82,
    ),
  )
  .add(
    WorkloadScenario::new(
      "quality-gate",
      "Quality gate evaluation",
      category="quality",
      description="Evaluate comparison rows against a threshold policy",
      tags=["quality", "ci", "gate"],
      data_size=20,
      warmup=2,
      iterations=25,
      complexity="O(n)",
      priority=92,
    ),
  )
  .add(
    WorkloadScenario::new(
      "artifact-bundle",
      "Artifact bundle rendering",
      category="submission",
      description="Render contest artifact metadata",
      tags=["artifact", "submission", "report"],
      data_size=10,
      warmup=2,
      iterations=20,
      complexity="O(n)",
      priority=75,
    ),
  )
  .add(
    WorkloadScenario::new(
      "checklist-render",
      "Checklist rendering",
      category="submission",
      description="Render a contest checklist",
      tags=["checklist", "submission", "report"],
      data_size=10,
      warmup=2,
      iterations=20,
      complexity="O(n)",
      priority=78,
    ),
  )
  .add(
    WorkloadScenario::new(
      "document-build",
      "Markdown document build",
      category="submission",
      description="Compose a multi-section Markdown report",
      tags=["markdown", "document", "submission"],
      data_size=10,
      warmup=2,
      iterations=20,
      complexity="O(n)",
      priority=76,
    ),
  )
  .add(
    WorkloadScenario::new(
      "percentile-small",
      "Small percentile summary",
      category="statistics",
      description="Compute p90 and p95 on a small sample set",
      tags=["stats", "percentile", "summary"],
      data_size=20,
      warmup=2,
      iterations=30,
      complexity="O(n log n)",
      priority=86,
    ),
  )
  .add(
    WorkloadScenario::new(
      "percentile-medium",
      "Medium percentile summary",
      category="statistics",
      description="Compute p90 and p95 on a medium sample set",
      tags=["stats", "percentile", "summary"],
      data_size=200,
      warmup=2,
      iterations=20,
      complexity="O(n log n)",
      priority=84,
    ),
  )
  .add(
    WorkloadScenario::new(
      "stddev-small",
      "Small standard deviation",
      category="statistics",
      description="Compute sample standard deviation on a small sample set",
      tags=["stats", "stddev", "summary"],
      data_size=20,
      warmup=2,
      iterations=30,
      complexity="O(n)",
      priority=80,
    ),
  )
  .add(
    WorkloadScenario::new(
      "validation-name",
      "Benchmark name validation",
      category="validation",
      description="Validate benchmark names before reporting",
      tags=["validation", "name", "safety"],
      data_size=1,
      warmup=2,
      iterations=30,
      complexity="O(n)",
      priority=72,
    ),
  )
  .add(
    WorkloadScenario::new(
      "validation-normalize",
      "Benchmark name normalization",
      category="validation",
      description="Normalize names for compact reports",
      tags=["validation", "name", "format"],
      data_size=1,
      warmup=2,
      iterations=30,
      complexity="O(n)",
      priority=72,
    ),
  )
}
