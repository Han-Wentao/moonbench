///|
test "ApiCatalog indexes public symbols" {
  let catalog = @moonbench.ApiCatalog::moonbench_standard()
  inspect(catalog.count() >= 50, content="true")
  inspect(catalog.count_kind("struct") >= 15, content="true")
  inspect(catalog.count_kind("function") >= 20, content="true")
  inspect(catalog.stable_count(), content="\{catalog.count()}")
  inspect(catalog.contains("BenchmarkSuite"), content="true")
  inspect(catalog.contains("missing"), content="false")
  inspect(catalog.filter_kind("struct").count() >= 15, content="true")
  inspect(catalog.filter_since("0.2.0").count() >= 30, content="true")
  inspect(catalog.to_markdown().contains("Public API Catalog"), content="true")
  inspect(
    catalog.to_json().contains("\"BenchmarkSnapshot::diff\""),
    content="true",
  )
}

///|
test "DocTemplateSet renders documentation index and bodies" {
  let templates = @moonbench.DocTemplateSet::moonbench_standard()
  inspect(templates.count() >= 7, content="true")
  inspect(templates.required_count() >= 6, content="true")
  inspect(templates.count_audience("reviewer") >= 2, content="true")
  inspect(templates.contains("overview"), content="true")
  inspect(templates.contains("none"), content="false")
  inspect(templates.find("install").title, content="安装方式")
  inspect(
    templates.to_markdown().contains("MoonBench Documentation Templates"),
    content="true",
  )
  inspect(templates.render_all().contains("项目概述"), content="true")
  inspect(templates.to_json().contains("\"quick-start\""), content="true")
}

///|
test "ProjectScorecard grades readiness using LOC and required items" {
  let incomplete = @moonbench.ProjectScorecard::moonbench_standard(
    actual_loc=4700,
  )
  inspect(incomplete.loc_ready(), content="false")
  inspect(incomplete.ready(), content="false")
  inspect(incomplete.grade(), content="incomplete")
  let ready = @moonbench.ProjectScorecard::moonbench_standard(actual_loc=5000)
  inspect(ready.loc_ready(), content="true")
  inspect(ready.missing_required_count(), content="0")
  inspect(ready.ready(), content="true")
  inspect(ready.section_count(), content="2")
  inspect(ready.item_count() >= 14, content="true")
  inspect(ready.earned_score() > 0, content="true")
  inspect(ready.to_markdown().contains("MoonBench Scorecard"), content="true")
  inspect(ready.to_json().contains("\"actual_loc\":5000"), content="true")
}

///|
test "ScoreItem and ScoreSection support partial scoring" {
  let item = @moonbench.ScoreItem::new("x", "X", max_score=10).partial(
    6, "partial",
  )
  inspect(item.earned_score, content="6")
  inspect(item.passed, content="false")
  inspect(item.ratio(), content="0.6")
  let section = @moonbench.ScoreSection::new("s", "Section")
    .add(item)
    .add(@moonbench.ScoreItem::new("y", "Y", max_score=5).pass("ok"))
  inspect(section.count(), content="2")
  inspect(section.earned_score(), content="11")
  inspect(section.max_score(), content="15")
  inspect(section.required_passed(), content="false")
  inspect(section.to_json().contains("\"missing_required\":1"), content="true")
}

///|
test "Custom ApiCatalog and DocTemplateSet remain composable" {
  let symbol = @moonbench.ApiSymbol::new(
    "Demo::run",
    "function",
    package_name="demo/pkg",
    summary="Run demo",
    since="1.0.0",
    stable=false,
    example="Demo::run()",
  )
  inspect(symbol.to_markdown_row().contains("Demo::run"), content="true")
  inspect(symbol.to_json().contains("\"stable\":false"), content="true")
  let catalog = @moonbench.ApiCatalog::new(title="Custom")
    .add(symbol)
    .add(
      @moonbench.ApiSymbol::new(
        "Demo",
        "struct",
        package_name="demo/pkg",
        summary="Demo struct",
        since="1.0.0",
      ),
    )
  inspect(catalog.count(), content="2")
  inspect(catalog.count_kind("function"), content="1")
  inspect(catalog.stable_count(), content="1")
  inspect(catalog.find("Demo").kind, content="struct")
  let template = @moonbench.DocTemplate::new(
    "custom",
    "Custom Section",
    audience="maintainer",
    purpose="Show extension behavior",
    body="Body",
    required=false,
  )
  inspect(template.to_markdown().contains("Custom Section"), content="true")
  inspect(template.to_json().contains("\"required\":false"), content="true")
  let templates = @moonbench.DocTemplateSet::new(title="Custom Templates").add(
    template,
  )
  inspect(templates.count(), content="1")
  inspect(templates.required_count(), content="0")
  inspect(templates.count_audience("maintainer"), content="1")
  inspect(templates.render_all().contains("Body"), content="true")
}

///|
test "Standard catalogs expose submission-oriented helpers" {
  let api = @moonbench.ApiCatalog::moonbench_standard()
  let docs = @moonbench.DocTemplateSet::moonbench_standard()
  inspect(api.contains("SubmissionChecklist"), content="true")
  inspect(api.contains("ProjectScorecard::moonbench_standard"), content="true")
  inspect(docs.contains("submission"), content="true")
  inspect(docs.required_count() >= 6, content="true")
}
