test_that("the search window includes today and day 330, but excludes its neighbours", {
  today <- as.Date("2026-11-02")
  expect_silent(validate_flight_date_window(c(today, today + 330), today))
  expect_error(validate_flight_date_window(today - 1, today),
               "2026-11-01.*2026-11-02 through 2027-09-28")
  expect_error(validate_flight_date_window(today + 331, today),
               "2027-09-29.*330 days ahead")
  # Day arithmetic handles leap years and year boundaries without month rounding.
  leap_day <- as.Date("2028-02-29")
  expect_silent(validate_flight_date_window(leap_day + 330, leap_day))
  expect_error(validate_flight_date_window(leap_day + 331, leap_day), "outside")
})

test_that("invalid calendar dates and malformed inputs have useful errors", {
  for (date in c("2026-02-30", "2026-13-01", "2026-2-01", "2026-12-20junk",
                 "2026/12/20", "tomorrow", "", NA_character_)) {
    expect_error(parse_flight_dates(date), "YYYY-MM-DD")
    expect_error(fa_define_query_range("JFK", "LHR", date, "2026-12-25"), "YYYY-MM-DD")
  }
  expect_error(parse_flight_dates(as.Date(NA)), "non-missing")
  expect_error(parse_flight_dates(20261220), "YYYY-MM-DD")
  expect_error(fa_define_query("JFK", "LHR", "2026-02-30"), "valid dates")
  expect_error(fa_define_query("JFK", "LHR", "tomorrow"), "YYYY-MM-DD")
  expect_error(fa_define_query_range("JFK", "LHR", c("2026-12-20", "2026-12-21"),
                                    "2026-12-25"), "single date")
})

test_that("Date objects work in every supported trip layout", {
  d <- as.Date("2026-12-20")
  expect_equal(fa_define_query("JFK", "LHR", d)$date[[1]], "2026-12-20")
  expect_equal(unlist(fa_define_query("JFK", "LHR", d, d + 7)$date),
               c("2026-12-20", "2026-12-27"))
  expect_equal(unlist(fa_define_query("JFK", "LHR", d, "LHR", "CDG", d + 7)$date),
               c("2026-12-20", "2026-12-27"))
  expect_equal(unlist(fa_define_query("JFK", d, "LHR", d + 7, "CDG")$date),
               c("2026-12-20", "2026-12-27"))
})

test_that("fetching revalidates every saved segment before starting Chrome", {
  today <- Sys.Date()
  saved <- fa_define_query("JFK", "LHR", today, today + 331)
  expect_error(fa_fetch_flights(saved), "outside.*330 days ahead")
  saved$date[[2]] <- "not-a-date"
  expect_error(fa_fetch_flights(saved), "YYYY-MM-DD")
  saved <- fa_define_query("JFK", "LHR", today)
  saved$date[[1]] <- as.character(today - 1)
  expect_error(fa_fetch_flights(saved), "past departure dates")
})
