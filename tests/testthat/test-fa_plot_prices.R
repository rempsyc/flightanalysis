test_that("fa_plot_prices works with summary table input", {
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
  
  # Should run without error
  expect_silent({
    result <- fa_plot_prices(summary)
  })
  
  # Should return the summary invisibly
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 2)
})

test_that("fa_plot_prices works with raw flight data", {
  # Create mock flight data
  results <- data.frame(
    City = rep(c("Mumbai", "Delhi"), each = 3),
    Airport = rep(c("BOM", "DEL"), each = 3),
    Date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 2),
    Price = c(334, 388, 400, 315, 353, 370),
    stringsAsFactors = FALSE
  )
  
  # Should create summary and plot
  expect_silent({
    result <- fa_plot_prices(results)
  })
  
  expect_true(is.data.frame(result))
})

test_that("fa_plot_prices handles custom title", {
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
  expect_silent({
    fa_plot_prices(summary, title = "Custom Title")
  })
})

test_that("fa_plot_prices handles highlight_best parameter", {
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
  expect_silent({
    fa_plot_prices(summary, highlight_best = FALSE)
  })
  
  # Should work with highlight_best = TRUE
  expect_silent({
    fa_plot_prices(summary, highlight_best = TRUE)
  })
})

test_that("fa_plot_prices handles single date", {
  summary <- data.frame(
    City = c("Mumbai", "Delhi"),
    Origin = c("BOM", "DEL"),
    `2025-12-18` = c("$334", "$315"),
    Average_Price = c("$334", "$315"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  
  # Should work with single date
  expect_silent({
    result <- fa_plot_prices(summary)
  })
  
  expect_true(is.data.frame(result))
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
