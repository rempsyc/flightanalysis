test_that("filter_placeholder_rows removes placeholder entries", {
  # Create sample data with placeholder rows
  sample_data <- data.frame(
    airlines = c(
      "Air India",
      "Price graph",
      "Emirates",
      "Price unavailable",
      "   ",
      "Delta"
    ),
    price = c(500, 600, 700, NA, 800, 900),
    stringsAsFactors = FALSE
  )

  # Filter
  filtered <- flightanalysis:::filter_placeholder_rows(sample_data)

  # Should only keep Air India, Emirates, and Delta (3 rows)
  expect_equal(nrow(filtered), 3)
  expect_true(all(filtered$airlines %in% c("Air India", "Emirates", "Delta")))
  expect_false(any(is.na(filtered$price)))
})

test_that("filter_placeholder_rows handles empty data", {
  empty_data <- data.frame(
    airlines = character(0),
    price = numeric(0),
    stringsAsFactors = FALSE
  )

  filtered <- flightanalysis:::filter_placeholder_rows(empty_data)
  expect_equal(nrow(filtered), 0)
})

test_that("fa_flex_table creates correct structure", {
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
  table <- fa_flex_table(results, include_comment = TRUE, round_prices = TRUE)

  # Check structure
  expect_true(is.data.frame(table))
  expect_true("City" %in% names(table))
  expect_true("Airport" %in% names(table))
  expect_true("Comment" %in% names(table))
  expect_true("Average_Price" %in% names(table))

  # Check that we have date columns
  date_cols <- grep("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", names(table))
  expect_true(length(date_cols) >= 3)

  # Check number of rows (one per unique City-Airport combination)
  expect_equal(nrow(table), 2)
})

test_that("fa_flex_table handles missing Comment column", {
  results <- data.frame(
    City = c("Mumbai", "Delhi"),
    Airport = c("BOM", "DEL"),
    Dest = c("JFK", "JFK"),
    Date = c("2025-12-18", "2025-12-18"),
    Price = c(334, 315),
    stringsAsFactors = FALSE
  )

  # Should work without Comment column
  table <- fa_flex_table(results, include_comment = FALSE)
  expect_true(is.data.frame(table))
  expect_false("Comment" %in% names(table))
})

test_that("fa_best_dates returns top dates by mean", {
  results <- data.frame(
    City = rep(c("Mumbai", "Delhi"), each = 3),
    Airport = rep(c("BOM", "DEL"), each = 3),
    Dest = rep("JFK", 6),
    Date = rep(c("2025-12-18", "2025-12-19", "2025-12-20"), 2),
    Price = c(334, 388, 400, 315, 353, 370),
    stringsAsFactors = FALSE
  )

  best <- fa_best_dates(results, n = 2, by = "mean")

  expect_true(is.data.frame(best))
  expect_equal(nrow(best), 2)
  expect_true("Date" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))

  # First date should be the cheapest (mean of 334 and 315 = 324.5)
  expect_equal(best$Date[1], "2025-12-18")
  expect_true(best$Price[1] < best$Price[2])
})

test_that("fa_best_dates works with different aggregation methods", {
  results <- data.frame(
    City = c("Mumbai", "Delhi", "Varanasi"),
    Airport = c("BOM", "DEL", "VNS"),
    Dest = rep("JFK", 3),
    Date = rep("2025-12-18", 3),
    Price = c(500, 300, 400),
    stringsAsFactors = FALSE
  )

  # Test mean
  best_mean <- fa_best_dates(results, n = 1, by = "mean")
  expect_equal(best_mean$Price[1], 400) # (500 + 300 + 400) / 3

  # Test median
  best_median <- fa_best_dates(results, n = 1, by = "median")
  expect_equal(best_median$Price[1], 400) # median of 300, 400, 500

  # Test min
  best_min <- fa_best_dates(results, n = 1, by = "min")
  expect_equal(best_min$Price[1], 300) # min of 300, 400, 500
})

test_that("fa_create_date_range_scrape creates valid Scrape object for single origin", {
  # Single origin - should return one Scrape object
  scrape <- fa_create_date_range_scrape(
    origin = "BOM",
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  # Check it's a Scrape object
  expect_s3_class(scrape, "Scrape")

  # Check type
  expect_equal(scrape$type, "chain-trip")

  # Should have 3 dates for 1 airport = 3 segments
  expect_equal(length(scrape$origin), 3)
  expect_equal(length(scrape$dest), 3)
  expect_equal(length(scrape$date), 3)

  # All destinations should be JFK
  expect_true(all(unlist(scrape$dest) == "JFK"))

  # All origins should be BOM
  expect_true(all(unlist(scrape$origin) == "BOM"))
  
  # Dates should be in increasing order
  dates <- unlist(scrape$date)
  expect_true(all(dates == sort(dates)))
})

test_that("fa_create_date_range_scrape creates list for multiple origins", {
  # Multiple origins - should return list of Scrape objects
  scrapes <- fa_create_date_range_scrape(
    origin = c("BOM", "DEL"),
    dest = "JFK",
    date_min = "2025-12-18",
    date_max = "2025-12-20"
  )

  # Check it's a list
  expect_true(is.list(scrapes))
  expect_equal(length(scrapes), 2)
  expect_equal(names(scrapes), c("BOM", "DEL"))

  # Check each element is a Scrape object
  expect_s3_class(scrapes$BOM, "Scrape")
  expect_s3_class(scrapes$DEL, "Scrape")

  # Check BOM scrape
  expect_equal(scrapes$BOM$type, "chain-trip")
  expect_equal(length(scrapes$BOM$origin), 3)  # 3 dates
  expect_true(all(unlist(scrapes$BOM$origin) == "BOM"))
  expect_true(all(unlist(scrapes$BOM$dest) == "JFK"))
  
  # Check DEL scrape
  expect_equal(scrapes$DEL$type, "chain-trip")
  expect_equal(length(scrapes$DEL$origin), 3)  # 3 dates
  expect_true(all(unlist(scrapes$DEL$origin) == "DEL"))
  expect_true(all(unlist(scrapes$DEL$dest) == "JFK"))
  
  # Dates should be in increasing order for each
  bom_dates <- unlist(scrapes$BOM$date)
  expect_true(all(bom_dates == sort(bom_dates)))
  
  del_dates <- unlist(scrapes$DEL$date)
  expect_true(all(del_dates == sort(del_dates)))
})

test_that("fa_create_date_range_scrape validates inputs", {
  # Invalid airport code
  expect_error(
    fa_create_date_range_scrape(
      origin = c("BO"),
      dest = "JFK",
      date_min = "2025-12-18",
      date_max = "2025-12-20"
    ),
    "All airport codes must be 3 characters"
  )

  # Invalid date order
  expect_error(
    fa_create_date_range_scrape(
      origin = "BOM",
      dest = "JFK",
      date_min = "2025-12-20",
      date_max = "2025-12-18"
    ),
    "date_min must be before or equal to date_max"
  )
})

test_that("extract_data_from_scrapes processes Scrape objects correctly", {
  # Create mock Scrape objects with data (using real structure)
  scrape1 <- list(
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
  class(scrape1) <- "Scrape"
  
  scrape2 <- list(
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
  class(scrape2) <- "Scrape"
  
  scrapes <- list(BOM = scrape1, DEL = scrape2)
  
  # Extract data
  result <- flightanalysis:::extract_data_from_scrapes(scrapes)
  
  # Check structure
  expect_true(is.data.frame(result))
  expect_true(all(c("City", "Airport", "Date", "Price") %in% names(result)))
  expect_equal(nrow(result), 4)
  expect_equal(sort(unique(result$Airport)), c("BOM", "DEL"))
  expect_equal(sort(unique(result$City)), c("BOM", "DEL"))
})

test_that("fa_flex_table accepts list of Scrape objects", {
  # Create mock Scrape objects (using real structure)
  scrape1 <- list(
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
  class(scrape1) <- "Scrape"
  
  scrape2 <- list(
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
  class(scrape2) <- "Scrape"
  
  scrapes <- list(BOM = scrape1, DEL = scrape2)
  
  # Create table directly from Scrape objects
  table <- fa_flex_table(scrapes, round_prices = TRUE)
  
  # Check structure
  expect_true(is.data.frame(table))
  expect_true("City" %in% names(table))
  expect_true("Airport" %in% names(table))
  expect_true("Average_Price" %in% names(table))
  expect_equal(nrow(table), 2) # One row per airport
})

test_that("fa_best_dates accepts list of Scrape objects", {
  # Create mock Scrape objects (using real structure)
  scrape1 <- list(
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
  class(scrape1) <- "Scrape"
  
  scrape2 <- list(
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
  class(scrape2) <- "Scrape"
  
  scrapes <- list(BOM = scrape1, DEL = scrape2)
  
  # Get best dates directly from Scrape objects
  best <- fa_best_dates(scrapes, n = 2, by = "mean")
  
  # Check structure
  expect_true(is.data.frame(best))
  expect_true("Date" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))
  expect_equal(nrow(best), 2)
})

test_that("fa_flex_table accepts single Scrape object", {
  # Create mock single Scrape object (using real structure)
  scrape <- list(
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
  class(scrape) <- "Scrape"
  
  # Create table directly from single Scrape object
  table <- fa_flex_table(scrape, round_prices = TRUE)
  
  # Check structure
  expect_true(is.data.frame(table))
  expect_true("City" %in% names(table))
  expect_true("Airport" %in% names(table))
  expect_true("Average_Price" %in% names(table))
  expect_equal(nrow(table), 1) # One row for single airport
  expect_equal(table$Airport[1], "BOM")
  expect_equal(table$City[1], "BOM")
})

test_that("fa_best_dates accepts single Scrape object", {
  # Create mock single Scrape object (using real structure)
  scrape <- list(
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
  class(scrape) <- "Scrape"
  
  # Get best dates directly from single Scrape object
  best <- fa_best_dates(scrape, n = 2, by = "mean")
  
  # Check structure
  expect_true(is.data.frame(best))
  expect_true("Date" %in% names(best))
  expect_true("Price" %in% names(best))
  expect_true("N_Routes" %in% names(best))
  expect_equal(nrow(best), 2)
})
