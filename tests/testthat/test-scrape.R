test_that("One-way trip is created correctly", {
  res <- Scrape("FCO", "IST", "2023-12-05")
  
  expect_s3_class(res, "Scrape")
  expect_equal(res$origin[[1]], "FCO")
  expect_equal(res$dest[[1]], "IST")
  expect_equal(res$date[[1]], "2023-12-05")
  expect_equal(res$type, "one-way")
})

test_that("Round-trip is created correctly", {
  res <- Scrape("LGA", "RDU", "2023-05-15", "2023-06-15")
  
  expect_s3_class(res, "Scrape")
  expect_equal(res$origin[[1]], "LGA")
  expect_equal(res$dest[[1]], "RDU")
  expect_equal(res$origin[[2]], "RDU")
  expect_equal(res$dest[[2]], "LGA")
  expect_equal(res$date[[1]], "2023-05-15")
  expect_equal(res$date[[2]], "2023-06-15")
  expect_equal(res$type, "round-trip")
})

test_that("Chain-trip is created correctly", {
  res <- Scrape("JFK", "AMS", "2023-11-10", "CDG", "AMS", "2023-11-17", "AMS", "IST", "2023-11-25")
  
  expect_s3_class(res, "Scrape")
  expect_equal(unlist(res$origin), c("JFK", "CDG", "AMS"))
  expect_equal(unlist(res$dest), c("AMS", "AMS", "IST"))
  expect_equal(unlist(res$date), c("2023-11-10", "2023-11-17", "2023-11-25"))
  expect_equal(res$type, "chain-trip")
})

test_that("Perfect-chain is created correctly", {
  res <- Scrape("JFK", "2023-11-10", "AMS", "2023-11-17", "CDG", "2023-11-20", "IST", "2023-11-25", "JFK")
  
  expect_s3_class(res, "Scrape")
  expect_equal(unlist(res$origin), c("JFK", "AMS", "CDG", "IST"))
  expect_equal(unlist(res$dest), c("AMS", "CDG", "IST", "JFK"))
  expect_equal(unlist(res$date), c("2023-11-10", "2023-11-17", "2023-11-20", "2023-11-25"))
  expect_equal(res$type, "perfect-chain")
})

test_that("Invalid date order throws error", {
  expect_error(Scrape("JFK", "IST", "2023-08-20", "2023-07-20"))
})

test_that("Invalid argument format throws error", {
  expect_error(Scrape("JFKK", "IST", "2023-07-20"))
  expect_error(Scrape("JFK", "IST", "07-20-2023"))
})

test_that("Print method works", {
  res <- Scrape("JFK", "IST", "2023-07-20")
  expect_output(print(res), "Scrape")
  expect_output(print(res), "Query Not Yet Used")
})
