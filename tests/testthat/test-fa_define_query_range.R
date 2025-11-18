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

test_that("fa_define_query_range accepts city codes", {
  # City code as origin
  query <- fa_define_query_range(
    origin = "NYC",
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  expect_true(inherits(query, "flight_query") || inherits(query, "Scrape"))
  expect_equal(query$type, "chain-trip")
  expect_true(all(unlist(query$origin) == "NYC"))
  expect_true(all(unlist(query$dest) == "JFK"))
})

test_that("fa_define_query_range accepts full city names for single-airport cities", {
  # Use a city that has only one major airport
  # Mumbai = BOM
  query <- fa_define_query_range(
    origin = "Mumbai",
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  expect_true(inherits(query, "flight_query") || inherits(query, "Scrape"))
  expect_true(all(unlist(query$origin) == "BOM"))
  expect_true(all(unlist(query$dest) == "JFK"))
})

test_that("fa_define_query_range expands city names to multiple airports in origin", {
  # "New York" should expand to multiple airports: JFK, LGA, EWR, etc.
  queries <- fa_define_query_range(
    origin = "New York",
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  # Should return a list with multiple queries (one for each NY airport)
  expect_true(is.list(queries))
  expect_true(length(queries) > 1)
  
  # Names should be airport codes like LGA, JFK, etc.
  expect_true(all(nchar(names(queries)) == 3))
})

test_that("fa_define_query_range handles mixed formats", {
  # Mix of city codes, airport codes, and city names
  queries <- fa_define_query_range(
    origin = c("NYC", "BOM"),
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-19"
  )

  expect_true(is.list(queries))
  expect_equal(length(queries), 2)
  expect_true(all(c("NYC", "BOM") %in% names(queries)))
})

test_that("fa_define_query_range removes duplicates", {
  # If same code specified multiple times, should only appear once
  queries <- fa_define_query_range(
    origin = c("BOM", "NYC", "NYC"),
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  # Should return list with BOM and NYC (NYC not duplicated)
  expect_true(is.list(queries))
  expect_equal(length(queries), 2)
  expect_equal(sort(names(queries)), c("BOM", "NYC"))
})

test_that("fa_define_query_range validates inputs", {
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
  
  # Missing origin
  expect_error(
    fa_define_query_range(
      dest = "JFK",
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "argument \"origin\" is missing"
  )
  
  # Missing dest
  expect_error(
    fa_define_query_range(
      origin = "BOM",
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "argument \"dest\" is missing"
  )
})

test_that("fa_define_query_range rejects unknown city names", {
  # Unknown city name should throw an error
  expect_error(
    fa_define_query_range(
      origin = "BOM",
      dest = "New York City",
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "not found in airport database"
  )
})

test_that("fa_define_query_range handles multiple destination airports gracefully", {
  # When a city name expands to multiple airports, it should use the first one
  # and show a message (not error)
  expect_message(
    queries <- fa_define_query_range(
      origin = "BOM",
      dest = "New York",
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "Using the first one"
  )
  
  # Should create a query successfully
  expect_true(inherits(queries, "flight_query") || inherits(queries, "Scrape"))
  
  # Destination should be the first NY airport
  expect_true(all(unlist(queries$dest) %in% c("LGA", "JFK")))
})
