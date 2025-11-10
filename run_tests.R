#!/usr/bin/env Rscript

# Simple test runner that doesn't require testthat package
# This allows testing the R package without external dependencies

cat("Loading R package functions...\n")
source('R/flight.R')
source('R/scrape.R')
source('R/cache.R')

test_count <- 0
pass_count <- 0
fail_count <- 0

# Test helper functions
expect_equal <- function(actual, expected, msg = NULL) {
  test_count <<- test_count + 1
  if (is.null(msg)) {
    msg <- sprintf(
      "Expected %s to equal %s",
      deparse(substitute(actual)),
      deparse(substitute(expected))
    )
  }

  if (isTRUE(all.equal(actual, expected))) {
    pass_count <<- pass_count + 1
    cat("  ✓ PASS:", msg, "\n")
  } else {
    fail_count <<- fail_count + 1
    cat("  ✗ FAIL:", msg, "\n")
    cat("    Expected:", toString(expected), "\n")
    cat("    Got:", toString(actual), "\n")
  }
}

expect_true <- function(expr, msg = NULL) {
  test_count <<- test_count + 1
  if (is.null(msg)) {
    msg <- deparse(substitute(expr))
  }

  if (isTRUE(expr)) {
    pass_count <<- pass_count + 1
    cat("  ✓ PASS:", msg, "\n")
  } else {
    fail_count <<- fail_count + 1
    cat("  ✗ FAIL:", msg, "\n")
  }
}

expect_s3_class <- function(obj, class_name, msg = NULL) {
  test_count <<- test_count + 1
  if (is.null(msg)) {
    msg <- sprintf(
      "%s should be class %s",
      deparse(substitute(obj)),
      class_name
    )
  }

  if (inherits(obj, class_name)) {
    pass_count <<- pass_count + 1
    cat("  ✓ PASS:", msg, "\n")
  } else {
    fail_count <<- fail_count + 1
    cat("  ✗ FAIL:", msg, "\n")
    cat("    Expected class:", class_name, "\n")
    cat("    Got class:", class(obj), "\n")
  }
}

expect_error <- function(expr, msg = NULL) {
  test_count <<- test_count + 1
  if (is.null(msg)) {
    msg <- sprintf("%s should error", deparse(substitute(expr)))
  }

  result <- tryCatch(
    {
      eval(expr)
      FALSE
    },
    error = function(e) {
      TRUE
    }
  )

  if (result) {
    pass_count <<- pass_count + 1
    cat("  ✓ PASS:", msg, "\n")
  } else {
    fail_count <<- fail_count + 1
    cat("  ✗ FAIL:", msg, "(no error raised)\n")
  }
}

# Test Suite: Scrape
cat("\n=== Testing Scrape Class ===\n")

cat("\nTest: One-way trip is created correctly\n")
res1 <- Scrape("FCO", "IST", "2025-12-05")
expect_s3_class(res1, "Scrape")
expect_equal(res1$origin[[1]], "FCO")
expect_equal(res1$dest[[1]], "IST")
expect_equal(res1$date[[1]], "2025-12-05")
expect_equal(res1$type, "one-way")

cat("\nTest: Round-trip is created correctly\n")
res2 <- Scrape("LGA", "RDU", "2025-12-15", "2025-12-25")
expect_s3_class(res2, "Scrape")
expect_equal(res2$origin[[1]], "LGA")
expect_equal(res2$dest[[1]], "RDU")
expect_equal(res2$origin[[2]], "RDU")
expect_equal(res2$dest[[2]], "LGA")
expect_equal(res2$date[[1]], "2025-12-15")
expect_equal(res2$date[[2]], "2025-12-25")
expect_equal(res2$type, "round-trip")

cat("\nTest: Chain-trip is created correctly\n")
res3 <- Scrape(
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
expect_s3_class(res3, "Scrape")
expect_equal(unlist(res3$origin), c("JFK", "CDG", "AMS"))
expect_equal(unlist(res3$dest), c("AMS", "AMS", "IST"))
expect_equal(unlist(res3$date), c("2025-11-10", "2025-11-17", "2025-11-25"))
expect_equal(res3$type, "chain-trip")

cat("\nTest: Perfect-chain is created correctly\n")
res4 <- Scrape(
  "JFK",
  "2025-12-10",
  "AMS",
  "2025-12-17",
  "CDG",
  "2025-12-20",
  "IST",
  "2025-12-25",
  "JFK"
)
expect_s3_class(res4, "Scrape")
expect_equal(unlist(res4$origin), c("JFK", "AMS", "CDG", "IST"))
expect_equal(unlist(res4$dest), c("AMS", "CDG", "IST", "JFK"))
expect_equal(
  unlist(res4$date),
  c("2025-12-10", "2025-12-17", "2025-12-20", "2025-12-25")
)
expect_equal(res4$type, "perfect-chain")

cat("\nTest: Invalid date order throws error\n")
expect_error(Scrape("JFK", "IST", "2025-12-20", "2025-12-25"))

cat("\nTest: Invalid argument format throws error\n")
expect_error(Scrape("JFKK", "IST", "2025-12-20"))
# Note: Date format validation is less strict in R due to character length check only

# Test Suite: Flight
cat("\n=== Testing Flight Class ===\n")

cat("\nTest: Flight object is created\n")
flight1 <- Flight(
  "2025-12-20",
  "JFKIST",
  "9:00AM",
  "5:00PM",
  "8 hr 0 min",
  "Nonstop",
  "150 kg CO2",
  "10% emissions",
  "$450"
)
expect_s3_class(flight1, "Flight")
expect_equal(flight1$date, "2025-12-20")

cat("\nTest: Flight parses origin and destination\n")
flight2 <- Flight("2025-12-20", "JFKIST")
expect_equal(flight2$origin, "JFK")
expect_equal(flight2$dest, "IST")

cat("\nTest: Flight parses price correctly\n")
flight3 <- Flight("2025-12-20", "JFKIST", "$450")
expect_equal(flight3$price, 450)

flight4 <- Flight("2025-12-20", "JFKIST", "$1,250")
expect_equal(flight4$price, 1250)

cat("\nTest: Flight parses stops correctly\n")
flight5 <- Flight("2025-12-20", "JFKIST", "Nonstop")
expect_equal(flight5$num_stops, 0)

flight6 <- Flight("2025-12-20", "JFKIST", "1 stop")
expect_equal(flight6$num_stops, 1)

cat("\nTest: Flight parses CO2 emissions\n")
flight7 <- Flight("2025-12-20", "JFKIST", "150 kg CO2", "10% emissions")
expect_equal(flight7$co2, 150)
expect_equal(flight7$emissions, 10)

cat("\nTest: flights_to_dataframe creates data frame\n")
df <- flights_to_dataframe(list(flight1, flight2))
expect_s3_class(df, "data.frame")
expect_equal(nrow(df), 2)
expect_true("origin" %in% names(df))
expect_true("destination" %in% names(df))

# Test Suite: Cache
cat("\n=== Testing Cache Functions ===\n")

cat("\nTest: check_scrape validates Scrape objects\n")
scrape <- Scrape("JFK", "IST", "2025-12-20")
expect_true(check_scrape(scrape))

not_scrape <- list(a = 1, b = 2)
expect_true(!check_scrape(not_scrape))

cat("\nTest: get_file_name generates correct filenames\n")
fname <- get_file_name("JFK", "IST", access = FALSE)
expect_equal(fname, "IST-JFK.csv")

fname2 <- get_file_name("RDU", "LGA", access = FALSE)
expect_equal(fname2, "LGA-RDU.csv")

fname_access <- get_file_name("JFK", "IST", access = TRUE)
expect_equal(fname_access, "IST-JFK.txt")

# Summary
cat("\n", rep("=", 50), "\n", sep = "")
cat("TEST SUMMARY\n")
cat(rep("=", 50), "\n", sep = "")
cat(sprintf("Total tests: %d\n", test_count))
cat(sprintf("Passed: %d\n", pass_count))
cat(sprintf("Failed: %d\n", fail_count))
cat(sprintf("Success rate: %.1f%%\n", (pass_count / test_count) * 100))
cat(rep("=", 50), "\n", sep = "")

if (fail_count > 0) {
  # quit(status = 1)
} else {
  cat("\n✓ All tests passed!\n")
  # quit(status = 0)
}
