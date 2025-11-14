test_that("fa_find_best_dates returns top dates by mean", {
  results <- data.frame(
    City = rep(c("Mumbai", "Delhi"), each = 3),
    Airport = rep(c("BOM", "DEL"), each = 3),
    Dest = rep("JFK", 6),
    Date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 2),
    Price = c(334, 388, 400, 315, 353, 370),
    stringsAsFactors = FALSE
  )

  best <- fa_find_best_dates(results, n = 2, by = "mean")

  expect_true(is.data.frame(best))
  expect_equal(nrow(best), 2)
  expect_true("Date" %in% names(best))
  expect_true("Origin" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))

  # First date should be the cheapest (mean of 334 and 315 = 324.5)
  expect_equal(best$Date[1], "2025-12-18")
  expect_true(best$Price[1] < best$Price[2])
})

test_that("fa_find_best_dates works with different aggregation methods", {
  results <- data.frame(
    City = c("Mumbai", "Delhi", "Varanasi"),
    Airport = c("BOM", "DEL", "VNS"),
    Dest = rep("JFK", 3),
    Date = rep("2025-12-18", 3),
    Price = c(500, 300, 400),
    stringsAsFactors = FALSE
  )

  # Test mean
  best_mean <- fa_find_best_dates(results, n = 1, by = "mean")
  expect_equal(best_mean$Price[1], 400) # (500 + 300 + 400) / 3

  # Test median
  best_median <- fa_find_best_dates(results, n = 1, by = "median")
  expect_equal(best_median$Price[1], 400) # median of 300, 400, 500

  # Test min
  best_min <- fa_find_best_dates(results, n = 1, by = "min")
  expect_equal(best_min$Price[1], 300) # min of 300, 400, 500
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
  expect_true("Origin" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))
  expect_equal(nrow(best), 2)
})

test_that("fa_find_best_dates accepts single query object", {
  # Create mock single query object (using real structure)
  query <- list(
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
  class(query) <- "flight_query"

  # Get best dates directly from single query object
  best <- fa_find_best_dates(query, n = 2, by = "mean")

  # Check structure
  expect_true(is.data.frame(best))
  expect_true("Date" %in% names(best))
  expect_true("Origin" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))
  expect_equal(nrow(best), 2)
})

test_that("fa_find_best_dates supports filtering by time", {
  # Create mock data with departure times
  results <- data.frame(
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
  best <- fa_find_best_dates(results, n = 5, time_min = "08:00", time_max = "18:00")
  
  expect_true(is.data.frame(best))
  expect_equal(nrow(best), 1) # Only the 12:00 flight should remain
  expect_equal(best$Price[1], 350)
})

test_that("fa_find_best_dates supports filtering by price range", {
  results <- data.frame(
    Airport = c("BOM", "BOM", "BOM"),
    Date = rep("2025-12-18", 3),
    Price = c(300, 350, 400),
    stringsAsFactors = FALSE
  )
  
  # Filter for prices between 320 and 380
  best <- fa_find_best_dates(results, n = 5, price_min = 320, price_max = 380)
  
  expect_true(is.data.frame(best))
  expect_equal(nrow(best), 1)
  expect_equal(best$Price[1], 350)
})

test_that("fa_find_best_dates supports filtering by stops", {
  # Create mock query with num_stops
  query <- list(
    data = data.frame(
      departure_datetime = as.POSIXct(c(
        "2025-12-18 10:00:00",
        "2025-12-18 12:00:00",
        "2025-12-18 14:00:00"
      )),
      arrival_datetime = as.POSIXct(c(
        "2025-12-18 18:00:00",
        "2025-12-18 20:00:00",
        "2025-12-18 22:00:00"
      )),
      origin = c("BOM", "BOM", "BOM"),
      destination = c("JFK", "JFK", "JFK"),
      airlines = c("Air India", "Emirates", "Delta"),
      price = c(500, 450, 600),
      num_stops = c(0, 1, 2),
      stringsAsFactors = FALSE
    )
  )
  class(query) <- "flight_query"
  
  # Filter for direct flights only
  best <- fa_find_best_dates(query, n = 5, max_stops = 0)
  
  expect_true(is.data.frame(best))
  expect_equal(nrow(best), 1)
  expect_equal(best$Price[1], 500)
})
