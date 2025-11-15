test_that("fa_define_query_range creates valid query object for single origin", {
  # Single origin - should return one query object
  query <- fa_define_query_range(
    origin = "BOM",
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  # Check it's a query object
  expect_true(inherits(query, "flight_query") || inherits(query, "Scrape"))

  # Check type
  expect_equal(query$type, "chain-trip")

  # Should have 3 dates for 1 airport = 3 segments
  expect_equal(length(query$origin), 3)
  expect_equal(length(query$dest), 3)
  expect_equal(length(query$date), 3)

  # All destinations should be JFK
  expect_true(all(unlist(query$dest) == "JFK"))

  # All origins should be BOM
  expect_true(all(unlist(query$origin) == "BOM"))

  # Dates should be in increasing order
  dates <- unlist(query$date)
  expect_true(all(dates == sort(dates)))
})

test_that("fa_define_query_range creates list for multiple origins", {
  # Multiple origins - should return list of query objects
  queries <- fa_define_query_range(
    origin = c("BOM", "DEL"),
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  # Check it's a list
  expect_true(is.list(queries))
  expect_equal(length(queries), 2)
  expect_equal(names(queries), c("BOM", "DEL"))

  # Check each element is a flight query object
  expect_true(
    inherits(queries$BOM, "flight_query") || inherits(queries$BOM, "Scrape")
  )
  expect_true(
    inherits(queries$DEL, "flight_query") || inherits(queries$DEL, "Scrape")
  )

  # Check BOM query
  expect_equal(queries$BOM$type, "chain-trip")
  expect_equal(length(queries$BOM$origin), 3) # 3 dates
  expect_true(all(unlist(queries$BOM$origin) == "BOM"))
  expect_true(all(unlist(queries$BOM$dest) == "JFK"))

  # Check DEL query
  expect_equal(queries$DEL$type, "chain-trip")
  expect_equal(length(queries$DEL$origin), 3) # 3 dates
  expect_true(all(unlist(queries$DEL$origin) == "DEL"))
  expect_true(all(unlist(queries$DEL$dest) == "JFK"))

  # Dates should be in increasing order for each
  bom_dates <- unlist(queries$BOM$date)
  expect_true(all(bom_dates == sort(bom_dates)))

  del_dates <- unlist(queries$DEL$date)
  expect_true(all(del_dates == sort(del_dates)))
})

test_that("fa_define_query_range validates inputs", {
  # Invalid airport code
  expect_error(
    fa_define_query_range(
      origin = c("BO"),
      dest = "JFK",
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "All airport codes must be 3 characters"
  )

  # Invalid date order
  expect_error(
    fa_define_query_range(
      origin = "BOM",
      dest = "JFK",
      date_min = "2025-12-20",
      date_max = "2025-12-18"
    ),
    "date_min must be before or equal to date_max"
  )
})

