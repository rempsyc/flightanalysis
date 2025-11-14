test_that("One-way trip is created correctly", {
  res <- fa_define_query("FCO", "IST", "2025-12-05")

  expect_true(inherits(res, "flight_query") || inherits(res, "Scrape"))
  expect_equal(res$origin[[1]], "FCO")
  expect_equal(res$dest[[1]], "IST")
  expect_equal(res$date[[1]], "2025-12-05")
  expect_equal(res$type, "one-way")
})

test_that("Round-trip is created correctly", {
  res <- fa_define_query("LGA", "RDU", "2025-05-15", "2025-06-15")

  expect_true(inherits(res, "flight_query") || inherits(res, "Scrape"))
  expect_equal(res$origin[[1]], "LGA")
  expect_equal(res$dest[[1]], "RDU")
  expect_equal(res$origin[[2]], "RDU")
  expect_equal(res$dest[[2]], "LGA")
  expect_equal(res$date[[1]], "2025-05-15")
  expect_equal(res$date[[2]], "2025-06-15")
  expect_equal(res$type, "round-trip")
})

test_that("Chain-trip is created correctly", {
  res <- fa_define_query(
    "JFK",
    "AMS",
    "2025-11-10",
    "CDG",
    "AMS",
    "2025-11-17",
    "AMS",
    "IST",
    "2025-11-25"
  )

  expect_true(inherits(res, "flight_query") || inherits(res, "Scrape"))
  expect_equal(unlist(res$origin), c("JFK", "CDG", "AMS"))
  expect_equal(unlist(res$dest), c("AMS", "AMS", "IST"))
  expect_equal(unlist(res$date), c("2025-11-10", "2025-11-17", "2025-11-25"))
  expect_equal(res$type, "chain-trip")
})

test_that("Perfect-chain is created correctly", {
  res <- fa_define_query(
    "JFK",
    "2025-11-10",
    "AMS",
    "2025-11-17",
    "CDG",
    "2025-11-20",
    "IST",
    "2025-11-25",
    "JFK"
  )

  expect_true(inherits(res, "flight_query") || inherits(res, "Scrape"))
  expect_equal(unlist(res$origin), c("JFK", "AMS", "CDG", "IST"))
  expect_equal(unlist(res$dest), c("AMS", "CDG", "IST", "JFK"))
  expect_equal(
    unlist(res$date),
    c("2025-11-10", "2025-11-17", "2025-11-20", "2025-11-25")
  )
  expect_equal(res$type, "perfect-chain")
})

test_that("Invalid date order throws error", {
  expect_error(fa_define_query("JFK", "IST", "2025-08-20", "2025-07-20"))
})

test_that("Invalid argument format throws error", {
  expect_error(fa_define_query("JFKK", "IST", "2025-07-20"))
  expect_error(fa_define_query("JFK", "IST", "07-20-2025"))
})

test_that("Print method works", {
  res <- fa_define_query("JFK", "IST", "2025-07-20")
  expect_output(print(res), "Flight Query")
  expect_output(print(res), "Not Yet Fetched")
})

test_that("URL generation has correct origin and destination order", {
  # One-way trip
  res <- fa_define_query("JFK", "IST", "2025-12-20")
  expected_url <- "https://www.google.com/travel/flights?hl=en&q=Flights%20to%20IST%20from%20JFK%20on%202025-12-20%20oneway"
  expect_equal(res$url[[1]], expected_url)

  # Chain-trip with multiple segments (issue example)
  res2 <- fa_define_query(
    "VNS",
    "JFK",
    "2025-12-20",
    "PAT",
    "JFK",
    "2025-12-25"
  )
  expect_true(inherits(res2, "flight_query") || inherits(res2, "Scrape"))
  expect_equal(res2$type, "chain-trip")
  expect_equal(length(res2$origin), 2)
  expect_equal(length(res2$dest), 2)

  # Verify origin/destination arrays
  expect_equal(unlist(res2$origin), c("VNS", "PAT"))
  expect_equal(unlist(res2$dest), c("JFK", "JFK"))

  # First segment: VNS -> JFK on 2025-12-20
  expect_equal(res2$origin[[1]], "VNS")
  expect_equal(res2$dest[[1]], "JFK")
  expect_equal(res2$date[[1]], "2025-12-20")
  expect_true(grepl("Flights%20to%20JFK%20from%20VNS", res2$url[[1]]))

  # Second segment: PAT -> JFK on 2025-12-25
  expect_equal(res2$origin[[2]], "PAT")
  expect_equal(res2$dest[[2]], "JFK")
  expect_equal(res2$date[[2]], "2025-12-25")
  expect_true(grepl("Flights%20to%20JFK%20from%20PAT", res2$url[[2]]))
})
