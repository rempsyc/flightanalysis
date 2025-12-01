test_that("fa_plot_best_dates works with best_dates input", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock best_dates result
  best_dates <- data.frame(
    departure_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
    departure_time = c("10:00", "12:00", "14:00"),
    origin = c("BOM", "DEL", "BOM"),
    price = c(334, 315, 353),
    n_routes = c(3, 3, 3),
    stringsAsFactors = FALSE
  )
  
  # Should run without error and return a ggplot object
  result <- fa_plot_best_dates(best_dates)
  expect_s3_class(result, "gg")
  expect_s3_class(result, "ggplot")
})

test_that("fa_plot_best_dates works with flight_results object", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock flight_results object
  query1 <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
      departure_time = rep("10:00", 3),
      arrival_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
      arrival_time = rep("18:00", 3),
      origin = rep("BOM", 3),
      destination = rep("JFK", 3),
      airlines = rep("Air India", 3),
      price = c(334, 388, 400),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"
  
  query2 <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
      departure_time = rep("12:00", 3),
      arrival_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
      arrival_time = rep("20:00", 3),
      origin = rep("DEL", 3),
      destination = rep("JFK", 3),
      airlines = rep("Vistara", 3),
      price = c(315, 353, 370),
      stringsAsFactors = FALSE
    )
  )
  class(query2) <- "flight_query"
  
  results <- list(
    data = rbind(query1$data, query2$data),
    BOM = query1,
    DEL = query2
  )
  class(results) <- "flight_results"
  
  # Should create best_dates and plot
  result <- fa_plot_best_dates(results, n = 3)
  expect_s3_class(result, "gg")
})

test_that("fa_plot_best_dates handles custom title", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  best_dates <- data.frame(
    departure_date = c("2025-12-18"),
    departure_time = c("10:00"),
    origin = c("BOM"),
    price = c(334),
    n_routes = c(3),
    stringsAsFactors = FALSE
  )
  
  # Should accept custom title
  result <- fa_plot_best_dates(best_dates, title = "Custom Title")
  expect_s3_class(result, "gg")
  expect_equal(result$labels$title, "Custom Title")
})

test_that("fa_plot_best_dates handles data without origin", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create data without origin column
  best_dates <- data.frame(
    date = c("2025-12-18", "2025-12-19"),
    price = c(334, 315),
    n_routes = c(3, 3),
    stringsAsFactors = FALSE
  )
  
  # Should work without origin column
  result <- fa_plot_best_dates(best_dates)
  expect_s3_class(result, "gg")
})

test_that("fa_plot_best_dates handles single date", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  best_dates <- data.frame(
    departure_date = c("2025-12-18"),
    departure_time = c("10:00"),
    origin = c("BOM"),
    price = c(334),
    n_routes = c(3),
    stringsAsFactors = FALSE
  )
  
  # Should work with single date
  result <- fa_plot_best_dates(best_dates)
  expect_s3_class(result, "gg")
})

test_that("fa_plot_best_dates errors on empty data", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
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
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
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
  result <- fa_plot_best_dates(best_dates)
  expect_s3_class(result, "gg")
})

test_that("fa_plot_best_dates handles x_axis_angle parameter", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock best_dates result
  best_dates <- data.frame(
    departure_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
    departure_time = c("10:00", "12:00", "14:00"),
    origin = c("BOM", "DEL", "BOM"),
    price = c(334, 315, 353),
    n_routes = c(3, 3, 3),
    stringsAsFactors = FALSE
  )
  
  # Should work with default angle (0)
  result1 <- fa_plot_best_dates(best_dates, x_axis_angle = 0)
  expect_s3_class(result1, "gg")
  
  # Should work with diagonal angle (45)
  result2 <- fa_plot_best_dates(best_dates, x_axis_angle = 45)
  expect_s3_class(result2, "gg")
  
  # Should work with vertical angle (90)
  result3 <- fa_plot_best_dates(best_dates, x_axis_angle = 90)
  expect_s3_class(result3, "gg")
})
