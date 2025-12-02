test_that("fa_plot_best_dates works with flight_results input", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  # Create mock flight_results object
  query1 <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
      departure_time = c("10:00", "12:00", "14:00"),
      arrival_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
      arrival_time = rep("18:00", 3),
      origin = rep("BOM", 3),
      destination = rep("JFK", 3),
      airlines = rep("Air India", 3),
      price = c(334, 315, 353),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"

  results <- list(
    data = query1$data,
    BOM = query1
  )
  class(results) <- "flight_results"

  # Should run without error and return a ggplot object
  result <- fa_plot_best_dates(results)
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

  # Create mock flight_results object
  query1 <- list(
    data = data.frame(
      departure_date = c("2025-12-18"),
      departure_time = c("10:00"),
      arrival_date = c("2025-12-18"),
      arrival_time = c("18:00"),
      origin = c("BOM"),
      destination = c("JFK"),
      airlines = c("Air India"),
      price = c(334),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"

  results <- list(
    data = query1$data,
    BOM = query1
  )
  class(results) <- "flight_results"

  # Should accept custom title
  result <- fa_plot_best_dates(results, title = "Custom Title")
  expect_s3_class(result, "gg")
  expect_equal(result$labels$title, "Custom Title")
})

test_that("fa_plot_best_dates handles single date", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  # Create mock flight_results object
  query1 <- list(
    data = data.frame(
      departure_date = c("2025-12-18"),
      departure_time = c("10:00"),
      arrival_date = c("2025-12-18"),
      arrival_time = c("18:00"),
      origin = c("BOM"),
      destination = c("JFK"),
      airlines = c("Air India"),
      price = c(334),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"

  results <- list(
    data = query1$data,
    BOM = query1
  )
  class(results) <- "flight_results"

  # Should work with single date
  result <- fa_plot_best_dates(results)
  expect_s3_class(result, "gg")
})

test_that("fa_plot_best_dates errors on empty data", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  # Create mock flight_results with empty data
  query1 <- list(
    data = data.frame(
      departure_date = character(0),
      departure_time = character(0),
      arrival_date = character(0),
      arrival_time = character(0),
      origin = character(0),
      destination = character(0),
      airlines = character(0),
      price = numeric(0),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"

  results <- list(
    data = query1$data,
    BOM = query1
  )
  class(results) <- "flight_results"

  # Should error with appropriate message
  expect_error(
    fa_plot_best_dates(results),
    "No data to plot after filtering"
  )
})

test_that("fa_plot_best_dates handles multiple origins", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  # Create flight_results with multiple origins
  query1 <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19"),
      departure_time = c("10:00", "14:00"),
      arrival_date = c("2025-12-18", "2025-12-19"),
      arrival_time = c("18:00", "22:00"),
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      airlines = c("Air India", "Air India"),
      price = c(334, 353),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"

  query2 <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19"),
      departure_time = c("12:00", "16:00"),
      arrival_date = c("2025-12-18", "2025-12-19"),
      arrival_time = c("20:00", "00:00"),
      origin = c("DEL", "DEL"),
      destination = c("JFK", "JFK"),
      airlines = c("Vistara", "Vistara"),
      price = c(315, 370),
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

  # Should work with multiple origins
  result <- fa_plot_best_dates(results)
  expect_s3_class(result, "gg")
})

test_that("fa_plot_best_dates handles x_axis_angle parameter", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  # Create mock flight_results object
  query1 <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
      departure_time = c("10:00", "12:00", "14:00"),
      arrival_date = c("2025-12-18", "2025-12-19", "2025-12-20"),
      arrival_time = rep("18:00", 3),
      origin = rep("BOM", 3),
      destination = rep("JFK", 3),
      airlines = rep("Air India", 3),
      price = c(334, 315, 353),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"

  results <- list(
    data = query1$data,
    BOM = query1
  )
  class(results) <- "flight_results"

  # Should work with default angle (0)
  result1 <- fa_plot_best_dates(results, x_axis_angle = 0)
  expect_s3_class(result1, "gg")

  # Should work with diagonal angle (45)
  result2 <- fa_plot_best_dates(results, x_axis_angle = 45)
  expect_s3_class(result2, "gg")

  # Should work with vertical angle (90)
  result3 <- fa_plot_best_dates(results, x_axis_angle = 90)
  expect_s3_class(result3, "gg")
})
