test_that("filter_placeholder_rows removes placeholder entries", {
  # Create sample data with placeholder rows
  sample_data <- data.frame(
    airlines = c(
      "Air India",
      "Price graph",
      "Emirates",
      "Price unavailable",
      "   ",
      "Delta"
    ),
    price = c(500, 600, 700, NA, 800, 900),
    stringsAsFactors = FALSE
  )

  # Filter
  filtered <- flightanalysis:::filter_placeholder_rows(sample_data)

  # Should only keep Air India, Emirates, and Delta (3 rows)
  expect_equal(nrow(filtered), 3)
  expect_true(all(filtered$airlines %in% c("Air India", "Emirates", "Delta")))
  expect_false(any(is.na(filtered$price)))
})

test_that("filter_placeholder_rows handles empty data", {
  empty_data <- data.frame(
    airlines = character(0),
    price = numeric(0),
    stringsAsFactors = FALSE
  )

  filtered <- flightanalysis:::filter_placeholder_rows(empty_data)
  expect_equal(nrow(filtered), 0)
})

test_that("fa_summarize_prices creates correct structure", {
  # Create mock results data
  results <- data.frame(
    City = rep(c("Mumbai", "Delhi"), each = 3),
    Airport = rep(c("BOM", "DEL"), each = 3),
    Dest = rep("JFK", 6),
    Date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 2),
    Price = c(334, 388, 400, 315, 353, 370),
    Comment = rep(c("Original flight", ""), each = 3),
    stringsAsFactors = FALSE
  )

  # Create table
  table <- fa_summarize_prices(
    results,
    include_comment = TRUE,
    round_prices = TRUE
  )

  # Check structure
  expect_true(is.data.frame(table))
  expect_true("City" %in% names(table))
  expect_true("Airport" %in% names(table))
  expect_true("Comment" %in% names(table))
  expect_true("Average_Price" %in% names(table))

  # Check that we have date columns
  date_cols <- grep("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", names(table))
  expect_true(length(date_cols) >= 3)

  # Check number of rows (one per unique City-Airport combination)
  expect_equal(nrow(table), 2)
})

test_that("fa_summarize_prices handles missing Comment column", {
  results <- data.frame(
    City = c("Mumbai", "Delhi"),
    Airport = c("BOM", "DEL"),
    Dest = c("JFK", "JFK"),
    Date = c("2025-12-18", "2025-12-18"),
    Price = c(334, 315),
    stringsAsFactors = FALSE
  )

  # Should work without Comment column
  table <- fa_summarize_prices(results, include_comment = FALSE)
  expect_true(is.data.frame(table))
  expect_false("Comment" %in% names(table))
})

test_that("fa_find_best_dates returns top dates by mean", {
  results <- data.frame(
    City = rep(c("Mumbai", "Delhi"), each = 3),
    Airport = rep(c("BOM", "DEL"), each = 3),
    Dest = rep("JFK", 6),
    Date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 2),
    Price = c(334, 388, 400, 315, 353, 370),
    stringsAsFactors = FALSE
  )

  best <- fa_find_best_dates(results, n = 2, by = "mean")

  expect_true(is.data.frame(best))
  expect_equal(nrow(best), 2)
  expect_true("Date" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))

  # First date should be the cheapest (mean of 334 and 315 = 324.5)
  expect_equal(best$Date[1], "2025-12-18")
  expect_true(best$Price[1] < best$Price[2])
})

test_that("fa_find_best_dates works with different aggregation methods", {
  results <- data.frame(
    City = c("Mumbai", "Delhi", "Varanasi"),
    Airport = c("BOM", "DEL", "VNS"),
    Dest = rep("JFK", 3),
    Date = rep("2025-12-18", 3),
    Price = c(500, 300, 400),
    stringsAsFactors = FALSE
  )

  # Test mean
  best_mean <- fa_find_best_dates(results, n = 1, by = "mean")
  expect_equal(best_mean$Price[1], 400) # (500 + 300 + 400) / 3

  # Test median
  best_median <- fa_find_best_dates(results, n = 1, by = "median")
  expect_equal(best_median$Price[1], 400) # median of 300, 400, 500

  # Test min
  best_min <- fa_find_best_dates(results, n = 1, by = "min")
  expect_equal(best_min$Price[1], 300) # min of 300, 400, 500
})

test_that("fa_create_date_range creates valid query object for single origin", {
  # Single origin - should return one query object
  query <- fa_create_date_range(
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

test_that("fa_create_date_range creates list for multiple origins", {
  # Multiple origins - should return list of query objects
  queries <- fa_create_date_range(
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

test_that("fa_create_date_range validates inputs", {
  # Invalid airport code
  expect_error(
    fa_create_date_range(
      origin = c("BO"),
      dest = "JFK",
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "All airport codes must be 3 characters"
  )

  # Invalid date order
  expect_error(
    fa_create_date_range(
      origin = "BOM",
      dest = "JFK",
      date_min = "2025-12-20",
      date_max = "2025-12-18"
    ),
    "date_min must be before or equal to date_max"
  )
})

test_that("extract_data_from_scrapes processes query objects correctly", {
  # Create mock query objects with data (using real structure)
  query1 <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 10:00:00",
        "2025-12-19 11:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 18:00:00",
        "2025-12-19 19:00:00"
      )),
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      airlines = c("Air India", "Emirates"),
      price = c(500, 550),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"

  query2 <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 12:00:00",
        "2025-12-19 13:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 20:00:00",
        "2025-12-19 21:00:00"
      )),
      origin = c("DEL", "DEL"),
      destination = c("JFK", "JFK"),
      airlines = c("Vistara", "IndiGo"),
      price = c(450, 480),
      stringsAsFactors = FALSE
    )
  )
  class(query2) <- "flight_query"

  queries <- list(BOM = query1, DEL = query2)

  # Extract data
  result <- flightanalysis:::extract_data_from_scrapes(queries)

  # Check structure
  expect_true(is.data.frame(result))
  expect_true(all(c("City", "Airport", "Date", "Price") %in% names(result)))
  expect_equal(nrow(result), 4)
  expect_equal(sort(unique(result$Airport)), c("BOM", "DEL"))
  # City names should be converted from airport codes (if airportr is available)
  # Accept either airport codes or city names
  expect_true(all(
    sort(unique(result$City)) %in% c("BOM", "DEL", "Mumbai", "Delhi")
  ))
})

test_that("fa_summarize_prices accepts list of query objects", {
  # Create mock query objects (using real structure)
  query1 <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 10:00:00",
        "2025-12-19 11:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 18:00:00",
        "2025-12-19 19:00:00"
      )),
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      airlines = c("Air India", "Emirates"),
      price = c(500, 550),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"

  query2 <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 12:00:00",
        "2025-12-19 13:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 20:00:00",
        "2025-12-19 21:00:00"
      )),
      origin = c("DEL", "DEL"),
      destination = c("JFK", "JFK"),
      airlines = c("Vistara", "IndiGo"),
      price = c(450, 480),
      stringsAsFactors = FALSE
    )
  )
  class(query2) <- "flight_query"

  queries <- list(BOM = query1, DEL = query2)

  # Create table directly from query objects
  table <- fa_summarize_prices(queries, round_prices = TRUE)

  # Check structure
  expect_true(is.data.frame(table))
  expect_true("City" %in% names(table))
  expect_true("Airport" %in% names(table))
  expect_true("Average_Price" %in% names(table))
  expect_equal(nrow(table), 2) # One row per airport
})

test_that("fa_find_best_dates accepts list of query objects", {
  # Create mock query objects (using real structure)
  query1 <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 10:00:00",
        "2025-12-19 11:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 18:00:00",
        "2025-12-19 19:00:00"
      )),
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      airlines = c("Air India", "Emirates"),
      price = c(500, 550),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"

  query2 <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 12:00:00",
        "2025-12-19 13:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 20:00:00",
        "2025-12-19 21:00:00"
      )),
      origin = c("DEL", "DEL"),
      destination = c("JFK", "JFK"),
      airlines = c("Vistara", "IndiGo"),
      price = c(450, 480),
      stringsAsFactors = FALSE
    )
  )
  class(query2) <- "flight_query"

  queries <- list(BOM = query1, DEL = query2)

  # Get best dates directly from query objects
  best <- fa_find_best_dates(queries, n = 2, by = "mean")

  # Check structure
  expect_true(is.data.frame(best))
  expect_true("Date" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))
  expect_equal(nrow(best), 2)
})

test_that("fa_summarize_prices accepts single query object", {
  # Create mock single query object (using real structure)
  query <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 10:00:00",
        "2025-12-19 11:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 18:00:00",
        "2025-12-19 19:00:00"
      )),
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      airlines = c("Air India", "Emirates"),
      price = c(500, 550),
      stringsAsFactors = FALSE
    )
  )
  class(query) <- "flight_query"

  # Create table directly from single query object
  table <- fa_summarize_prices(query, round_prices = TRUE)

  # Check structure
  expect_true(is.data.frame(table))
  expect_true("City" %in% names(table))
  expect_true("Airport" %in% names(table))
  expect_true("Average_Price" %in% names(table))
  expect_equal(nrow(table), 1) # One row for single airport
  expect_equal(table$Airport[1], "BOM")
  # City name should be converted from airport code (if airportr is available)
  # Accept either airport code or city name
  expect_true(table$City[1] %in% c("BOM", "Mumbai"))
})

test_that("fa_find_best_dates accepts single query object", {
  # Create mock single query object (using real structure)
  query <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 10:00:00",
        "2025-12-19 11:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 18:00:00",
        "2025-12-19 19:00:00"
      )),
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      airlines = c("Air India", "Emirates"),
      price = c(500, 550),
      stringsAsFactors = FALSE
    )
  )
  class(query) <- "flight_query"

  # Get best dates directly from single query object
  best <- fa_find_best_dates(query, n = 2, by = "mean")

  # Check structure
  expect_true(is.data.frame(best))
  expect_true("Date" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))
  expect_equal(nrow(best), 2)
})
