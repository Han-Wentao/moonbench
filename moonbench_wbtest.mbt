test "median uses the middle item for odd samples" {
  inspect(median([1.0, 2.0, 9.0]), content="2")
}

test "median averages the two middle items for even samples" {
  inspect(median([1.0, 2.0, 4.0, 9.0]), content="3")
}

test "positive_delta clamps reversed timestamps" {
  inspect(positive_delta(5, 10), content="0")
  inspect(positive_delta(12, 10), content="2")
}
