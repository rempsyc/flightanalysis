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
  expect_true("Origin" %in% names(table))
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
  expect_true("Origin" %in% names(table))
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


test_that("fa_summarize_prices supports filtering by time", {
  # Create mock data with departure times
  results <- data.frame(
    City = c("Mumbai", "Mumbai", "Mumbai"),
    Airport = c("BOM", "BOM", "BOM"),
    Date = rep("2025-12-18", 3),
    Price = c(300, 350, 400),
    departure_datetime = as.POSIXct(c(
      "2025-12-18 06:00:00",
      "2025-12-18 12:00:00",
      "2025-12-18 20:00:00"
    )),
    stringsAsFactors = FALSE
  )
  
  # Filter for flights between 08:00 and 18:00
  summary <- fa_summarize_prices(results, time_min = "08:00", time_max = "18:00")
  
  expect_true(is.data.frame(summary))
  expect_equal(nrow(summary), 1)
  # The price for 2025-12-18 should be from the 12:00 flight (350)
  expect_equal(gsub("[^0-9]", "", summary$`2025-12-18`[1]), "350")
})

test_that("fa_summarize_prices supports filtering by stops", {
  # Create mock query with num_stops
  query <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 10:00:00",
        "2025-12-18 12:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 18:00:00",
        "2025-12-18 20:00:00"
      )),
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      airlines = c("Air India", "Emirates"),
      price = c(500, 450),
      num_stops = c(0, 1),
      stringsAsFactors = FALSE
    )
  )
  class(query) <- "flight_query"
  
  # Filter for direct flights only
  summary <- fa_summarize_prices(query, max_stops = 0)
  
  expect_true(is.data.frame(summary))
  expect_equal(nrow(summary), 1)
  # Should only include the direct flight
  expect_equal(gsub("[^0-9]", "", summary$`2025-12-18`[1]), "500")
})
