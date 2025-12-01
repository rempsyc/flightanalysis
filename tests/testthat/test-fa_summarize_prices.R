test_that("fa_summarize_prices creates correct structure with flight_results", {
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
  
  # Create flight_results object
  results <- list(
    data = rbind(query1$data, query2$data),
    BOM = query1,
    DEL = query2
  )
  class(results) <- "flight_results"

  # Create table
  table <- fa_summarize_prices(
    results,
    include_comment = FALSE,
    round_prices = TRUE
  )

  # Check structure
  expect_true(is.data.frame(table))
  expect_true("City" %in% names(table))
  expect_true("Origin" %in% names(table))
  expect_true("Average_Price" %in% names(table))

  # Check that we have date columns
  date_cols <- grep("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", names(table))
  expect_true(length(date_cols) >= 3)

  # Check number of rows (one per unique City-Origin combination, plus Best row)
  expect_equal(nrow(table), 3) # 2 airports + 1 Best row

  # Verify Best row exists
  expect_true("Best" %in% table$City)
  expect_true("Day" %in% table$Origin)
})

test_that("fa_summarize_prices rejects data frame input", {
  results <- data.frame(
    City = c("Mumbai", "Delhi"),
    Airport = c("BOM", "DEL"),
    Dest = c("JFK", "JFK"),
    Date = c("2025-12-18", "2025-12-18"),
    Price = c(334, 315),
    stringsAsFactors = FALSE
  )

  # Should error with clear message
  expect_error(
    fa_summarize_prices(results, include_comment = FALSE),
    "flight_results must be a flight_results object"
  )
})

test_that("fa_summarize_prices rejects list of query objects", {
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

  # Should error with clear message
  expect_error(
    fa_summarize_prices(queries, round_prices = TRUE),
    "flight_results must be a flight_results object"
  )
})

test_that("fa_find_best_dates rejects list of query objects", {
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

  # Should error with clear message
  expect_error(
    fa_find_best_dates(queries, n = 2, by = "mean"),
    "flight_results must be a flight_results object"
  )
})


test_that("fa_summarize_prices supports filtering by time", {
  # Create mock flight_results with departure times
  query <- list(
    data = data.frame(
      departure_date = rep("2025-12-18", 3),
      departure_time = c("06:00", "12:00", "20:00"),
      arrival_date = rep("2025-12-18", 3),
      arrival_time = c("14:00", "20:00", "04:00"),
      origin = rep("BOM", 3),
      destination = rep("JFK", 3),
      airlines = rep("Air India", 3),
      price = c(300, 350, 400),
      stringsAsFactors = FALSE
    )
  )
  class(query) <- "flight_query"
  
  results <- list(
    data = query$data,
    BOM = query
  )
  class(results) <- "flight_results"

  # Filter for flights between 08:00 and 18:00
  summary <- fa_summarize_prices(
    results,
    time_min = "08:00",
    time_max = "18:00"
  )

  expect_true(is.data.frame(summary))
  expect_equal(nrow(summary), 2) # 1 airport + Best row
  # The price for 2025-12-18 should be from the 12:00 flight (350) - check first row (before Best)
  expect_equal(gsub("[^0-9]", "", summary$`2025-12-18`[1]), "350")
})

test_that("fa_summarize_prices supports filtering by stops", {
  # Create mock flight_results with num_stops
  query <- list(
    data = data.frame(
      departure_date = rep("2025-12-18", 2),
      departure_time = c("10:00", "12:00"),
      arrival_date = rep("2025-12-18", 2),
      arrival_time = c("18:00", "20:00"),
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      airlines = c("Air India", "Emirates"),
      price = c(500, 450),
      num_stops = c(0, 1),
      stringsAsFactors = FALSE
    )
  )
  class(query) <- "flight_query"
  
  results <- list(
    data = query$data,
    BOM = query
  )
  class(results) <- "flight_results"

  # Filter for direct flights only
  summary <- fa_summarize_prices(results, max_stops = 0)

  expect_true(is.data.frame(summary))
  expect_equal(nrow(summary), 2) # 1 airport + Best row
  # Should only include the direct flight
  expect_equal(gsub("[^0-9]", "", summary$`2025-12-18`[1]), "500")
})

test_that("fa_summarize_prices supports excluded_airports parameter", {
  # Create mock flight_results with multiple airports
  query <- list(
    data = data.frame(
      departure_date = rep("2025-12-18", 3),
      departure_time = c("10:00", "12:00", "14:00"),
      arrival_date = rep("2025-12-18", 3),
      arrival_time = c("18:00", "20:00", "22:00"),
      origin = c("BOM", "DEL", "CXH"),
      destination = c("JFK", "JFK", "JFK"),
      airlines = c("Air India", "Vistara", "Seaplane"),
      price = c(500, 450, 600),
      stringsAsFactors = FALSE
    )
  )
  class(query) <- "flight_query"
  
  results <- list(
    data = query$data,
    BOM = query
  )
  class(results) <- "flight_results"

  # Exclude CXH airport
  summary <- fa_summarize_prices(results, excluded_airports = c("CXH"))

  expect_true(is.data.frame(summary))
  # Should have 2 airports + Best row (CXH excluded)
  expect_equal(nrow(summary), 3)
  # CXH should not be in the Origin column
  expect_false("CXH" %in% summary$Origin)
  # BOM and DEL should still be present
  expect_true("BOM" %in% summary$Origin)
  expect_true("DEL" %in% summary$Origin)
})
