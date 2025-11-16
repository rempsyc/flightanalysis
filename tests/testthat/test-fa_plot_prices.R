test_that("fa_plot_prices works with summary table input", {
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
  
  # Should run without error and return a ggplot object
  result <- fa_plot_prices(summary)
  expect_s3_class(result, "gg")
  expect_s3_class(result, "ggplot")
})

test_that("fa_plot_prices works with raw flight data", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  # Create mock flight data
  results <- data.frame(
    City = rep(c("Mumbai", "Delhi"), each = 3),
    Airport = rep(c("BOM", "DEL"), each = 3),
    Date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 2),
    Price = c(334, 388, 400, 315, 353, 370),
    stringsAsFactors = FALSE
  )
  
  # Should create summary and plot
  result <- fa_plot_prices(results)
  expect_s3_class(result, "gg")
  expect_s3_class(result, "ggplot")
})

test_that("fa_plot_prices handles custom title", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  summary <- data.frame(
    City = c("Mumbai"),
    Origin = c("BOM"),
    `2025-12-18` = c("$334"),
    `2025-12-19` = c("$388"),
    Average_Price = c("$361"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  
  # Should accept custom title
  result <- fa_plot_prices(summary, title = "Custom Title")
  expect_s3_class(result, "gg")
  expect_equal(result$labels$title, "Custom Title")
})

test_that("fa_plot_prices handles highlight_best parameter", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  summary <- data.frame(
    City = c("Mumbai"),
    Origin = c("BOM"),
    `2025-12-18` = c("$334"),
    `2025-12-19` = c("$388"),
    Average_Price = c("$361"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  
  # Should work with highlight_best = FALSE
  result1 <- fa_plot_prices(summary, highlight_best = FALSE)
  expect_s3_class(result1, "gg")
  
  # Should work with highlight_best = TRUE
  result2 <- fa_plot_prices(summary, highlight_best = TRUE)
  expect_s3_class(result2, "gg")
})

test_that("fa_plot_prices handles single date", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")
  
  summary <- data.frame(
    City = c("Mumbai", "Delhi"),
    Origin = c("BOM", "DEL"),
    `2025-12-18` = c("$334", "$315"),
    Average_Price = c("$334", "$315"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  
  # Should work with single date
  result <- fa_plot_prices(summary)
  expect_s3_class(result, "gg")
})

test_that("fa_plot_prices errors on empty data", {
  # Create data that becomes empty after filtering (only Best row)
  summary <- data.frame(
    City = c("Best"),
    Origin = c("Day"),
    `2025-12-18` = c("X"),
    Average_Price = c(""),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  
  # Should error with appropriate message
  expect_error(
    fa_plot_prices(summary),
    "No data to plot after filtering"
  )
})
