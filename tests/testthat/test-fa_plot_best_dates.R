test_that("fa_plot_best_dates works with best_dates input", {
  # Create mock best_dates result
  best_dates <- data.frame(
    departure_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
    departure_time = c("10:00", "12:00", "14:00"),
    origin = c("BOM", "DEL", "BOM"),
    price = c(334, 315, 353),
    n_routes = c(3, 3, 3),
    stringsAsFactors = FALSE
  )
  
  # Should run without error
  expect_silent({
    result <- fa_plot_best_dates(best_dates)
  })
  
  # Should return the data invisibly
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 3)
})

test_that("fa_plot_best_dates works with raw flight data", {
  # Create mock flight data
  results <- data.frame(
    Airport = rep(c("BOM", "DEL"), each = 3),
    Date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 2),
    Price = c(334, 388, 400, 315, 353, 370),
    stringsAsFactors = FALSE
  )
  
  # Should create best_dates and plot
  expect_silent({
    result <- fa_plot_best_dates(results, n = 3)
  })
  
  expect_true(is.data.frame(result))
})

test_that("fa_plot_best_dates handles custom title", {
  best_dates <- data.frame(
    departure_date = c("2025-12-18"),
    departure_time = c("10:00"),
    origin = c("BOM"),
    price = c(334),
    n_routes = c(3),
    stringsAsFactors = FALSE
  )
  
  # Should accept custom title
  expect_silent({
    fa_plot_best_dates(best_dates, title = "Custom Title")
  })
})

test_that("fa_plot_best_dates handles data without origin", {
  # Create data without origin column
  best_dates <- data.frame(
    date = c("2025-12-18", "2025-12-19"),
    price = c(334, 315),
    n_routes = c(3, 3),
    stringsAsFactors = FALSE
  )
  
  # Should work without origin column
  expect_silent({
    result <- fa_plot_best_dates(best_dates)
  })
  
  expect_true(is.data.frame(result))
})

test_that("fa_plot_best_dates handles single date", {
  best_dates <- data.frame(
    departure_date = c("2025-12-18"),
    departure_time = c("10:00"),
    origin = c("BOM"),
    price = c(334),
    n_routes = c(3),
    stringsAsFactors = FALSE
  )
  
  # Should work with single date
  expect_silent({
    result <- fa_plot_best_dates(best_dates)
  })
  
  expect_true(is.data.frame(result))
})

test_that("fa_plot_best_dates errors on empty data", {
  # Create empty data frame
  best_dates <- data.frame(
    departure_date = character(0),
    price = numeric(0),
    stringsAsFactors = FALSE
  )
  
  # Should error with appropriate message
  expect_error(
    fa_plot_best_dates(best_dates),
    "No data to plot after filtering"
  )
})

test_that("fa_plot_best_dates handles multiple origins", {
  # Create data with multiple origins
  best_dates <- data.frame(
    departure_date = rep(c("2025-12-18", "2025-12-19"), each = 2),
    departure_time = c("10:00", "12:00", "14:00", "16:00"),
    origin = c("BOM", "DEL", "BOM", "DEL"),
    price = c(334, 315, 353, 370),
    n_routes = c(3, 3, 3, 3),
    stringsAsFactors = FALSE
  )
  
  # Should work with multiple origins
  expect_silent({
    result <- fa_plot_best_dates(best_dates)
  })
  
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 4)
})
