test_that("captured Google Flights results retain all fares and airline labels", {
  page <- readLines(test_path("fixtures", "nyc-lon.txt"), encoding = "UTF-8")
  flights <- clean_results(page, "2026-12-20", verbose = FALSE)
  expect_length(flights, 24)
  data <- flights_to_dataframe(flights)
  expect_false(anyNA(data$price))
  expect_equal(data$price[1:5], c(713, 837, 950, 1049, 1049))
  expect_equal(data$price[24], 1049)
  expect_equal(data$airlines[5], "British Airways, American, Iberia, Finnair, Alaska")
  expect_equal(data$airlines[24], "British Airways")
  expect_equal(data$origin[1], "JFK")
  expect_equal(data$arrival_date[1], "2026-12-21")
  results <- structure(list(data = data), class = "flight_results")
  expect_no_error(fa_summarize_prices(results))
})

test_that("one short flight card is sufficient and footer text is excluded", {
  card <- c("9:00 AM", "-", "11:00 AM", "Delta", "2 hr", "JFKBOS",
            "Nonstop", "CA$150", "Price insights", "Travel for CA$90",
            "Some unrelated history")
  flights <- clean_results(card, "2026-12-20", verbose = FALSE)
  expect_length(flights, 1)
  expect_equal(flights[[1]]$price, 150)
  expect_equal(flights[[1]]$airline, "Delta")
  expect_warning(clean_results(character(), "2026-12-20", FALSE), "Could not find")
})

test_that("currency prefixes parse without accepting prose as a fare", {
  for (price in c("$1,250", "CA$1,250", "US$1,250", "A$1,250")) {
    expect_equal(flight_record("2026-12-20", price)$price, 1250)
  }
  expect_true(is.na(flight_record("2026-12-20", "Travel for CA$90")$price))
})

test_that("unavailable fares remain missing without using price insights", {
  card <- c("6:30 AM", "-", "3:45 PM", "Scandinavian Airlines", "19 hr 45 min",
            "BOMJFK", "1 stop", "1 hr 15 min CPH", "985 kg CO2e",
            "Price unavailable", "Price insights", "CA$90")
  flights <- clean_results(card, "2026-12-18", verbose = FALSE)
  expect_length(flights, 1)
  expect_true(is.null(flights[[1]]$price) || is.na(flights[[1]]$price))
  expect_equal(flights[[1]]$airline, "Scandinavian Airlines")
})

test_that("past-date searches fail before starting a browser", {
  query <- fa_define_query("NYC", "LON", as.character(Sys.Date() - 1))
  expect_error(fa_fetch_flights(query), "past departure dates")
  future <- fa_define_query("NYC", "LON", as.character(Sys.Date() + 30))
  expect_error(fa_fetch_flights(list(future, query)), "past departure dates")
})
