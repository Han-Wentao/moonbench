///|
test "median uses the middle item for odd samples" {
  inspect(median([1.0, 2.0, 9.0]), content="2")
}

///|
test "median averages the two middle items for even samples" {
  inspect(median([1.0, 2.0, 4.0, 9.0]), content="3")
}

///|
test "nearest rank percentile clamps to valid samples" {
  inspect(nearest_rank([1.0, 2.0, 3.0, 4.0, 5.0], 90), content="5")
  inspect(nearest_rank([1.0, 2.0, 3.0, 4.0, 5.0], 50), content="3")
  inspect(nearest_rank([1.0, 2.0, 3.0], 0), content="1")
  inspect(nearest_rank([1.0, 2.0, 3.0], 120), content="3")
}

///|
test "positive_delta clamps reversed timestamps" {
  inspect(positive_delta(5, 10), content="0")
  inspect(positive_delta(12, 10), content="2")
}

///|
test "runner count clamps are predictable" {
  inspect(clamp_non_negative(-1), content="0")
  inspect(clamp_non_negative(2), content="2")
  inspect(clamp_positive(0), content="1")
  inspect(clamp_positive(3), content="3")
}

///|
test "report escaping protects JSON and Markdown syntax" {
  inspect(escape_json("a\"b\\c"), content="a\\\"b\\\\c")
  inspect(escape_markdown("a|b"), content="a\\|b")
}
