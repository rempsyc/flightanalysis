test_that("flight_results object is created with merged data", {
  # Create mock query objects
  query1 <- list(
    data = data.frame(
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      price = c(500, 550),
      stringsAsFactors = FALSE
    ),
    origin = list("BOM", "BOM"),
    dest = list("JFK", "JFK"),
    date = list("2025-12-18", "2025-12-19")
  )
  class(query1) <- "flight_query"
  
  query2 <- list(
    data = data.frame(
      origin = c("DEL", "DEL"),
      destination = c("JFK", "JFK"),
      price = c(450, 480),
      stringsAsFactors = FALSE
    ),
    origin = list("DEL", "DEL"),
    dest = list("JFK", "JFK"),
    date = list("2025-12-18", "2025-12-19")
  )
  class(query2) <- "flight_query"
  
  queries <- list(BOM = query1, DEL = query2)
  
  # Manually create flight_results object as fa_fetch_flights would
  result <- flightanalysis:::create_flight_results(queries)
  
  # Check that it's a flight_results object
  expect_true(inherits(result, "flight_results"))
  
  # Check that merged data exists and has all rows
  expect_true("data" %in% names(result))
  expect_equal(nrow(result$data), 4) # 2 from BOM + 2 from DEL
  
  # Check that individual query objects are preserved
  expect_true("BOM" %in% names(result))
  expect_true("DEL" %in% names(result))
  expect_true(inherits(result$BOM, "flight_query"))
  expect_true(inherits(result$DEL, "flight_query"))
  
  # Check that merged data has all origins
  expect_true(all(c("BOM", "DEL") %in% result$data$origin))
})

test_that("flight_results print method works", {
  # Create a simple flight_results object
  query1 <- list(
    data = data.frame(
      origin = c("BOM"),
      destination = c("JFK"),
      price = c(500),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"
  
  queries <- list(BOM = query1)
  result <- flightanalysis:::create_flight_results(queries)
  
  # Test that print doesn't error
  expect_output(print(result), "Flight Results")
  expect_output(print(result), "Total flights: 1")
})

test_that("flight_results handles empty data", {
  # Create query with no data
  query1 <- list(data = data.frame())
  class(query1) <- "flight_query"
  
  queries <- list(BOM = query1)
  result <- flightanalysis:::create_flight_results(queries)
  
  # Check structure
  expect_true(inherits(result, "flight_results"))
  expect_true("data" %in% names(result))
  expect_equal(nrow(result$data), 0)
})

test_that("fa_summarize_prices accepts flight_results object", {
  # Create mock flight_results object
  query1 <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c("2025-12-18 10:00:00", "2025-12-19 11:00:00")),
      arrival_datetime = as.POSIXct(c("2025-12-18 18:00:00", "2025-12-19 19:00:00")),
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
      departure_datetime = as.POSIXct(c("2025-12-18 12:00:00", "2025-12-19 13:00:00")),
      arrival_datetime = as.POSIXct(c("2025-12-18 20:00:00", "2025-12-19 21:00:00")),
      origin = c("DEL", "DEL"),
      destination = c("JFK", "JFK"),
      airlines = c("Vistara", "IndiGo"),
      price = c(450, 480),
      stringsAsFactors = FALSE
    )
  )
  class(query2) <- "flight_query"
  
  queries <- list(BOM = query1, DEL = query2)
  flight_results <- flightanalysis:::create_flight_results(queries)
  
  # Should work with flight_results object
  summary <- fa_summarize_prices(flight_results)
  
  expect_true(is.data.frame(summary))
  expect_true("City" %in% names(summary))
  expect_true("Origin" %in% names(summary))
})

test_that("fa_find_best_dates accepts flight_results object", {
  # Create mock flight_results object
  query1 <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c("2025-12-18 10:00:00", "2025-12-19 11:00:00")),
      arrival_datetime = as.POSIXct(c("2025-12-18 18:00:00", "2025-12-19 19:00:00")),
      origin = c("BOM", "BOM"),
      destination = c("JFK", "JFK"),
      airlines = c("Air India", "Emirates"),
      price = c(500, 550),
      stringsAsFactors = FALSE
    )
  )
  class(query1) <- "flight_query"
  
  queries <- list(BOM = query1)
  flight_results <- flightanalysis:::create_flight_results(queries)
  
  # Should work with flight_results object
  best <- fa_find_best_dates(flight_results, n = 2)
  
  expect_true(is.data.frame(best))
  expect_true("departure_date" %in% names(best) || "date" %in% names(best))
  expect_true("price" %in% names(best))
})
