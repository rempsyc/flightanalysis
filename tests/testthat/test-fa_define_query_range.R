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
    "All airport/city codes must be 3 characters"
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

test_that("fa_define_query_range accepts city codes with origin_city parameter", {
  # Single city origin - should return one query object
  query <- fa_define_query_range(
    origin_city = "NYC",
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  # Check it's a query object
  expect_true(inherits(query, "flight_query") || inherits(query, "Scrape"))
  expect_equal(query$type, "chain-trip")

  # All origins should be NYC (city code)
  expect_true(all(unlist(query$origin) == "NYC"))
  
  # All destinations should be JFK
  expect_true(all(unlist(query$dest) == "JFK"))
})

test_that("fa_define_query_range accepts city codes with dest_city parameter", {
  # Airport origin to city destination
  query <- fa_define_query_range(
    origin = "BOM",
    dest_city = "LON",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  # Check it's a query object
  expect_true(inherits(query, "flight_query") || inherits(query, "Scrape"))
  
  # All origins should be BOM
  expect_true(all(unlist(query$origin) == "BOM"))
  
  # All destinations should be LON (city code)
  expect_true(all(unlist(query$dest) == "LON"))
})

test_that("fa_define_query_range accepts multiple city origins", {
  # Multiple city origins - should return list of query objects
  queries <- fa_define_query_range(
    origin_city = c("NYC", "BOS"),
    dest_city = "LON",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  # Check it's a list
  expect_true(is.list(queries))
  expect_equal(length(queries), 2)
  expect_equal(names(queries), c("NYC", "BOS"))
  
  # Check NYC query
  expect_true(all(unlist(queries$NYC$origin) == "NYC"))
  expect_true(all(unlist(queries$NYC$dest) == "LON"))
  
  # Check BOS query
  expect_true(all(unlist(queries$BOS$origin) == "BOS"))
  expect_true(all(unlist(queries$BOS$dest) == "LON"))
})

test_that("fa_define_query_range allows combining origin and origin_city", {
  # Can specify both origin and origin_city - they get combined
  queries <- fa_define_query_range(
    origin = "BOM",
    origin_city = "NYC",
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )
  
  # Should return list with both BOM and NYC
  expect_true(is.list(queries))
  expect_equal(length(queries), 2)
  expect_true(all(c("BOM", "NYC") %in% names(queries)))
})

test_that("fa_define_query_range removes duplicates when combining", {
  # If same code specified in both, should only appear once
  queries <- fa_define_query_range(
    origin = c("BOM", "NYC"),
    origin_city = "NYC",
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )
  
  # Should return list with BOM and NYC (NYC not duplicated)
  expect_true(is.list(queries))
  expect_equal(length(queries), 2)
  expect_equal(sort(names(queries)), c("BOM", "NYC"))
})

test_that("fa_define_query_range validates at least one origin specified", {
  # Cannot specify neither origin nor origin_city
  expect_error(
    fa_define_query_range(
      dest = "JFK",
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "Must specify at least one of 'origin' or 'origin_city'"
  )
})

test_that("fa_define_query_range validates at least one dest specified", {
  # Cannot specify neither dest nor dest_city
  expect_error(
    fa_define_query_range(
      origin = "BOM",
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "Must specify at least one of 'dest' or 'dest_city'"
  )
})

test_that("fa_define_query_range rejects multiple destinations", {
  # Multiple destinations not yet supported
  expect_error(
    fa_define_query_range(
      origin = "BOM",
      dest = c("JFK", "LGA"),
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "Multiple destinations are not yet supported"
  )
})

