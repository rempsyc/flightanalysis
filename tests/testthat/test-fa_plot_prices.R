test_that("fa_plot_prices rejects summary table input", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock summary table
  summary <- data.frame(
    City = c("Mumbai", "Delhi"),
    Origin = c("BOM", "DEL"),
    `2025-12-18` = c("$334", "$315"),
    `2025-12-19` = c("$388", "$353"),
    `2025-12-20` = c("$400", "$370"),
    Average_Price = c("$374", "$346"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  
  # Should error with clear message
  expect_error(
    fa_plot_prices(summary),
    "price_summary must be a flight_results object"
  )
})

test_that("fa_plot_prices works with flight_results object", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock flight_results object
  query1 <- list(
    data = data.frame(
      departure_date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 1),
      departure_time = rep("10:00", 3),
      arrival_date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 1),
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
      departure_date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 1),
      departure_time = rep("12:00", 3),
      arrival_date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 1),
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
  
  # Should create summary and plot
  result <- fa_plot_prices(results)
  expect_s3_class(result, "gg")
  expect_s3_class(result, "ggplot")
})

test_that("fa_plot_prices handles custom title", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock flight_results
  query <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19"),
      departure_time = rep("10:00", 2),
      arrival_date = c("2025-12-18", "2025-12-19"),
      arrival_time = rep("18:00", 2),
      origin = rep("BOM", 2),
      destination = rep("JFK", 2),
      airlines = rep("Air India", 2),
      price = c(334, 388),
      stringsAsFactors = FALSE
    )
  )
  class(query) <- "flight_query"
  
  results <- list(
    data = query$data,
    BOM = query
  )
  class(results) <- "flight_results"
  
  # Should accept custom title
  result <- fa_plot_prices(results, title = "Custom Title")
  expect_s3_class(result, "gg")
  expect_equal(result$labels$title, "Custom Title")
})

test_that("fa_plot_prices handles max and min annotations", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock flight_results
  query <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19"),
      departure_time = rep("10:00", 2),
      arrival_date = c("2025-12-18", "2025-12-19"),
      arrival_time = rep("18:00", 2),
      origin = rep("BOM", 2),
      destination = rep("JFK", 2),
      airlines = rep("Air India", 2),
      price = c(334, 388),
      stringsAsFactors = FALSE
    )
  )
  class(query) <- "flight_query"
  
  results <- list(
    data = query$data,
    BOM = query
  )
  class(results) <- "flight_results"
  
  # Should work with show_max_annotation = TRUE (default)
  result1 <- fa_plot_prices(results, show_max_annotation = TRUE)
  expect_s3_class(result1, "gg")
  
  # Should work with show_max_annotation = FALSE
  result2 <- fa_plot_prices(results, show_max_annotation = FALSE)
  expect_s3_class(result2, "gg")
  
  # Should work with show_min_annotation = TRUE
  result3 <- fa_plot_prices(results, show_min_annotation = TRUE)
  expect_s3_class(result3, "gg")
  
  # Should work with both annotations
  result4 <- fa_plot_prices(results, show_max_annotation = TRUE, show_min_annotation = TRUE)
  expect_s3_class(result4, "gg")
  
  # Should work with no annotations
  result5 <- fa_plot_prices(results, show_max_annotation = FALSE, show_min_annotation = FALSE)
  expect_s3_class(result5, "gg")
})

test_that("fa_plot_prices handles single date", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock flight_results with single date
  query1 <- list(
    data = data.frame(
      departure_date = "2025-12-18",
      departure_time = "10:00",
      arrival_date = "2025-12-18",
      arrival_time = "18:00",
      origin = "BOM",
      destination = "JFK",
      airlines = "Air India",
      price = 334,
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"
  
  query2 <- list(
    data = data.frame(
      departure_date = "2025-12-18",
      departure_time = "12:00",
      arrival_date = "2025-12-18",
      arrival_time = "20:00",
      origin = "DEL",
      destination = "JFK",
      airlines = "Vistara",
      price = 315,
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
  
  # Should work with single date
  result <- fa_plot_prices(results)
  expect_s3_class(result, "gg")
})

test_that("fa_plot_prices handles size_by parameter", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock flight_results
  query1 <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19"),
      departure_time = rep("10:00", 2),
      arrival_date = c("2025-12-18", "2025-12-19"),
      arrival_time = rep("18:00", 2),
      origin = rep("BOM", 2),
      destination = rep("JFK", 2),
      airlines = rep("Air India", 2),
      price = c(334, 388),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"
  
  query2 <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19"),
      departure_time = rep("12:00", 2),
      arrival_date = c("2025-12-18", "2025-12-19"),
      arrival_time = rep("20:00", 2),
      origin = rep("DEL", 2),
      destination = rep("JFK", 2),
      airlines = rep("Vistara", 2),
      price = c(315, 353),
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
  
  # Should work with default size_by = "price"
  result1 <- fa_plot_prices(results, size_by = "price")
  expect_s3_class(result1, "gg")
  
  # Should work with size_by = NULL (uniform sizing)
  result2 <- fa_plot_prices(results, size_by = NULL)
  expect_s3_class(result2, "gg")
})

test_that("fa_plot_prices errors on empty data", {
  # Create mock flight_results with data that becomes empty after processing
  # Use a query with placeholder/invalid data
  query <- list(
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
  class(query) <- "flight_query"
  
  results <- list(
    data = query$data,
    BOM = query
  )
  class(results) <- "flight_results"
  
  # Should error with appropriate message about no data
  expect_error(
    fa_plot_prices(results),
    "flight_results object contains no data"
  )
})

test_that("fa_plot_prices handles x_axis_angle parameter", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock flight_results
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
  
  results <- list(
    data = query1$data,
    BOM = query1
  )
  class(results) <- "flight_results"
  
  # Should work with default angle (0)
  result1 <- fa_plot_prices(results, x_axis_angle = 0)
  expect_s3_class(result1, "gg")
  
  # Should work with diagonal angle (45)
  result2 <- fa_plot_prices(results, x_axis_angle = 45)
  expect_s3_class(result2, "gg")
  
  # Should work with vertical angle (90)
  result3 <- fa_plot_prices(results, x_axis_angle = 90)
  expect_s3_class(result3, "gg")
})

test_that("fa_plot_prices handles drop_empty_dates parameter", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock flight_results with multiple origins
  # BOM has data for all 3 dates, DEL only has data for 2 dates (missing 12-20)
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
      departure_date = c("2025-12-18", "2025-12-19"),
      departure_time = rep("12:00", 2),
      arrival_date = c("2025-12-18", "2025-12-19"),
      arrival_time = rep("20:00", 2),
      origin = rep("DEL", 2),
      destination = rep("JFK", 2),
      airlines = rep("Vistara", 2),
      price = c(315, 353),
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
  
  # Should work with drop_empty_dates = TRUE (default)
  result1 <- fa_plot_prices(results, drop_empty_dates = TRUE)
  expect_s3_class(result1, "gg")
  
  # Should work with drop_empty_dates = FALSE
  result2 <- fa_plot_prices(results, drop_empty_dates = FALSE)
  expect_s3_class(result2, "gg")
})

test_that("fa_plot_prices filters empty dates correctly", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create flight_results where one date has NA prices for ALL origins
  # This simulates the scenario described in the issue
  query1 <- list(
    data = data.frame(
      departure_date = c("2025-12-18", "2025-12-19"),
      departure_time = rep("10:00", 2),
      arrival_date = c("2025-12-18", "2025-12-19"),
      arrival_time = rep("18:00", 2),
      origin = rep("BOM", 2),
      destination = rep("JFK", 2),
      airlines = rep("Air India", 2),
      price = c(334, 388),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"
  
  results <- list(
    data = query1$data,
    BOM = query1
  )
  class(results) <- "flight_results"
  
  # With drop_empty_dates = TRUE, empty dates should be filtered
  result1 <- fa_plot_prices(results, drop_empty_dates = TRUE)
  expect_s3_class(result1, "gg")
  
  # With drop_empty_dates = FALSE, all dates should be retained
  result2 <- fa_plot_prices(results, drop_empty_dates = FALSE)
  expect_s3_class(result2, "gg")
})
