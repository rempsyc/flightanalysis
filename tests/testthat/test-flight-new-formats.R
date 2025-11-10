test_that("Flight parses CO2e format (new Google Flights format)", {
  flight <- Flight("2025-07-20", "JFKIST", "593 kg CO2e", "18% emissions")
  
  expect_equal(flight$co2, 593)
  expect_equal(flight$emissions, 18)
})

test_that("Flight handles price without dollar sign", {
  # Price should be recognized when flight time is already set
  flight <- Flight("2025-07-20", "JFKIST", "8 hr 30 min", "450")
  
  expect_equal(flight$price, 450)
  expect_equal(flight$flight_time, "8 hr 30 min")
})

test_that("Flight filters out CO2-related text from airlines", {
  # These strings should not be set as airline names
  flight1 <- Flight("2025-07-20", "JFKIST", "593 kg CO2e")
  expect_null(flight1$airline)
  expect_equal(flight1$co2, 593)
  
  flight2 <- Flight("2025-07-20", "JFKIST", "Avoids as much CO2e as 7,731 trees absorb in a day")
  expect_null(flight2$airline)
  
  flight3 <- Flight("2025-07-20", "JFKIST", "Other flights")
  expect_null(flight3$airline)
})

test_that("Flight handles missing times gracefully", {
  # When times are not provided, they should be NULL/NA
  flight <- Flight("2025-07-20", "JFKIST", "593 kg CO2e", "8 hr 30 min", "450", "Nonstop")
  
  expect_null(flight$time_leave)
  expect_null(flight$time_arrive)
  expect_equal(flight$co2, 593)
  expect_equal(flight$price, 450)
})

test_that("flights_to_dataframe handles flights without times", {
  flight1 <- Flight("2025-07-20", "JFKIST", "593 kg CO2e", "8 hr 30 min", "450", "Nonstop", "18% emissions")
  flight2 <- Flight("2025-07-21", "ISTCDG", "479 kg CO2e", "10 hr 55 min", "648", "Nonstop", "0% emissions")
  
  df <- flights_to_dataframe(list(flight1, flight2))
  
  expect_equal(nrow(df), 2)
  expect_true(is.na(df$departure_datetime[1]))
  expect_true(is.na(df$arrival_datetime[1]))
  expect_equal(df$co2_emission_kg[1], 593)
  expect_equal(df$co2_emission_kg[2], 479)
  expect_equal(df$price[1], 450)
  expect_equal(df$price[2], 648)
})

test_that("Flight with both times and new CO2e format", {
  flight <- Flight(
    "2025-07-20",
    "JFKIST",
    "9:00AM",
    "5:00PM",
    "Turkish Airlines",
    "593 kg CO2e",
    "8 hr 0 min",
    "450",
    "Nonstop",
    "18% emissions"
  )
  
  expect_equal(flight$co2, 593)
  expect_equal(flight$emissions, 18)
  expect_equal(flight$price, 450)
  expect_equal(flight$airline, "Turkish Airlines")
  expect_false(is.null(flight$time_leave))
  expect_false(is.null(flight$time_arrive))
})
