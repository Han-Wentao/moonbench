test "WorkloadScenario renders and builds runner" {
  let scenario = @moonbench.WorkloadScenario::new(
    "case",
    "Case",
    category="demo",
    tags=["a", "b"],
    data_size=100,
    warmup=2,
    iterations=5,
    complexity="O(n)",
    priority=120,
  )
  inspect(scenario.priority, content="100")
  inspect(scenario.runner().iterations, content="5")
  inspect(scenario.has_tag("a"), content="true")
  inspect(scenario.has_tag("z"), content="false")
  inspect(scenario.tags_text(), content="a, b")
  inspect(scenario.to_json().contains("\"category\":\"demo\""), content="true")
  inspect(scenario.to_markdown_row().contains("| case | Case | demo |"), content="true")
}

test "ScenarioCatalog filters and summarizes scenarios" {
  let catalog = @moonbench.ScenarioCatalog::new(title="catalog")
    .add(@moonbench.WorkloadScenario::new(
      "a",
      "A",
      category="array",
      tags=["x"],
      iterations=3,
      priority=80,
    ))
    .add(@moonbench.WorkloadScenario::new(
      "b",
      "B",
      category="string",
      tags=["x", "y"],
      iterations=5,
      priority=60,
    ))
  inspect(catalog.count(), content="2")
  inspect(catalog.total_iterations(), content="8")
  inspect(catalog.average_priority(), content="70")
  inspect(catalog.contains_id("a"), content="true")
  inspect(catalog.contains_id("missing"), content="false")
  inspect(catalog.filter_category("array").count(), content="1")
  inspect(catalog.filter_tag("x").count(), content="2")
  inspect(catalog.filter_priority(70).count(), content="1")
  inspect(catalog.count_category("string"), content="1")
  inspect(catalog.count_tag("y"), content="1")
}

test "Standard scenario catalog covers benchmark workflow categories" {
  let catalog = @moonbench.ScenarioCatalog::moonbench_standard()
  inspect(catalog.count() >= 20, content="true")
  inspect(catalog.count_category("baseline") >= 2, content="true")
  inspect(catalog.count_category("report") >= 3, content="true")
  inspect(catalog.count_tag("submission") >= 3, content="true")
  inspect(catalog.to_markdown().contains("MoonBench Standard Scenario Catalog"), content="true")
  inspect(catalog.to_json().contains("\"scenarios\""), content="true")
}

test "ScenarioCatalog can produce estimated benchmark suite" {
  let catalog = @moonbench.ScenarioCatalog::new(title="estimated")
    .add(@moonbench.WorkloadScenario::new(
      "linear",
      "Linear",
      data_size=100,
      iterations=2,
      complexity="O(n)",
      priority=50,
    ))
  let suite = catalog.estimated_suite()
  inspect(suite.count(), content="1")
  inspect(suite.results[0].iterations, content="2")
  inspect(suite.results[0].stats.mean_us > 0.0, content="true")
}
