test "median uses the middle item for odd samples" {
  inspect(median([1.0, 2.0, 9.0]), content="2")
}

test "median averages the two middle items for even samples" {
  inspect(median([1.0, 2.0, 4.0, 9.0]), content="3")
}
