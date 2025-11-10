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

test_that("fa_flex_table creates correct structure", {
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
  table <- fa_flex_table(results, include_comment = TRUE, round_prices = TRUE)

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

test_that("fa_flex_table handles missing Comment column", {
  results <- data.frame(
    City = c("Mumbai", "Delhi"),
    Airport = c("BOM", "DEL"),
    Dest = c("JFK", "JFK"),
    Date = c("2025-12-18", "2025-12-18"),
    Price = c(334, 315),
    stringsAsFactors = FALSE
  )

  # Should work without Comment column
  table <- fa_flex_table(results, include_comment = FALSE)
  expect_true(is.data.frame(table))
  expect_false("Comment" %in% names(table))
})

test_that("fa_best_dates returns top dates by mean", {
  results <- data.frame(
    City = rep(c("Mumbai", "Delhi"), each = 3),
    Airport = rep(c("BOM", "DEL"), each = 3),
    Dest = rep("JFK", 6),
    Date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 2),
    Price = c(334, 388, 400, 315, 353, 370),
    stringsAsFactors = FALSE
  )

  best <- fa_best_dates(results, n = 2, by = "mean")

  expect_true(is.data.frame(best))
  expect_equal(nrow(best), 2)
  expect_true("Date" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))

  # First date should be the cheapest (mean of 334 and 315 = 324.5)
  expect_equal(best$Date[1], "2025-12-18")
  expect_true(best$Price[1] < best$Price[2])
})

test_that("fa_best_dates works with different aggregation methods", {
  results <- data.frame(
    City = c("Mumbai", "Delhi", "Varanasi"),
    Airport = c("BOM", "DEL", "VNS"),
    Dest = rep("JFK", 3),
    Date = rep("2025-12-18", 3),
    Price = c(500, 300, 400),
    stringsAsFactors = FALSE
  )

  # Test mean
  best_mean <- fa_best_dates(results, n = 1, by = "mean")
  expect_equal(best_mean$Price[1], 400) # (500 + 300 + 400) / 3

  # Test median
  best_median <- fa_best_dates(results, n = 1, by = "median")
  expect_equal(best_median$Price[1], 400) # median of 300, 400, 500

  # Test min
  best_min <- fa_best_dates(results, n = 1, by = "min")
  expect_equal(best_min$Price[1], 300) # min of 300, 400, 500
})

test_that("fa_scrape_best_oneway validates inputs", {
  # Missing required columns
  bad_routes <- data.frame(
    City = "Mumbai",
    Airport = "BOM"
  )

  expect_error(
    fa_scrape_best_oneway(bad_routes, "2025-12-18"),
    "routes must contain columns"
  )

  # Not a data frame
  expect_error(
    fa_scrape_best_oneway(list(), "2025-12-18"),
    "routes must be a data frame"
  )
})
