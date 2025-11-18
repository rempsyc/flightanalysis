test_that("Flight object is created", {
  flight <- flight_record(
    "2025-07-20",
    "JFKIST",
    "9:00AM",
    "5:00PM",
    "8 hr 0 min",
    "Nonstop",
    "150 kg CO2",
    "10% emissions",
    "$450"
  )

  expect_true(inherits(flight, "flight_record"))
  expect_equal(flight$date, "2025-07-20")
})

test_that("Flight parses origin and destination", {
  flight <- flight_record("2025-07-20", "JFKIST")

  expect_equal(flight$origin, "JFK")
  expect_equal(flight$dest, "IST")
})

test_that("Flight parses price correctly", {
  flight <- flight_record("2025-07-20", "JFKIST", "$450")

  expect_equal(flight$price, 450)

  flight2 <- flight_record("2025-07-20", "JFKIST", "$1,250")
  expect_equal(flight2$price, 1250)
})

test_that("Flight parses stops correctly", {
  flight1 <- flight_record("2025-07-20", "JFKIST", "Nonstop")
  expect_equal(flight1$num_stops, 0)

  flight2 <- flight_record("2025-07-20", "JFKIST", "1 stop")
  expect_equal(flight2$num_stops, 1)

  flight3 <- flight_record("2025-07-20", "JFKIST", "2 stops")
  expect_equal(flight3$num_stops, 2)
})

test_that("Flight parses CO2 emissions", {
  flight <- flight_record("2025-07-20", "JFKIST", "150 kg CO2", "10% emissions")

  expect_equal(flight$co2, 150)
  expect_equal(flight$emissions, 10)
})

test_that("Flight parses flight time", {
  flight <- flight_record("2025-07-20", "JFKIST", "8 hr 30 min")

  expect_equal(flight$flight_time, "8 hr 30 min")
})

test_that("flights_to_dataframe creates data frame", {
  flight1 <- flight_record("2025-07-20", "JFKIST", "$450", "Nonstop")
  flight2 <- flight_record("2025-07-21", "ISTCDG", "$300", "1 stop")

  df <- flights_to_dataframe(list(flight1, flight2))

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2)
  expect_true("origin" %in% names(df))
  expect_true("destination" %in% names(df))
  expect_true("price" %in% names(df))
})

test_that("Print method works for Flight", {
  flight <- flight_record("2025-07-20", "JFKIST")
  expect_output(print(flight), "flight_record|Flight")
  expect_output(print(flight), "JFK-->IST")
})

test_that("Flight parses without coercion warnings", {
  # Test that parsing various flight data doesn't produce warnings about NAs
  # Using expect_silent which fails if there are any warnings
  expect_silent({
    flight <- flight_record(
      "2025-07-20",
      "JFKIST",
      "9:00AM",
      "5:00PM",
      "8 hr 0 min",
      "Nonstop",
      "150 kg CO2",
      "10% emissions",
      "$450",
      "Some airline text",
      "Random garbage",
      "More text"
    )
  })
})

test_that("Flight parses invalid numeric data without coercion warnings", {
  # Test that invalid data that can't be coerced doesn't produce warnings
  # The safe_as_integer helper validates input before conversion
  expect_silent({
    flight <- flight_record(
      "2025-07-20",
      "JFKIST",
      "Invalid price $ABC",
      "XYZ kg CO2",
      "??% emissions"
    )
  })

  # Values should be NA when invalid
  flight2 <- flight_record("2025-07-20", "JFKIST", "$ABC")
  expect_true(is.na(flight2$price) || is.null(flight2$price))
})

test_that("Flight parses fused airline names correctly", {
  # Test case 1: Mixed-case word followed by capitalized word (no space)
  flight1 <- flight_record("2025-07-20", "JFKIST", "UnitedLufthansa")
  expect_equal(flight1$airline, "United, Lufthansa")
  
  # Test case 2: Space-separated words followed by capitalized word (no comma)
  flight2 <- flight_record("2025-07-20", "JFKIST", "Air CanadaUnited")
  expect_equal(flight2$airline, "Air Canada, United")
  
  # Test case 3: All-caps acronym followed by capitalized word (already working)
  flight3 <- flight_record("2025-07-20", "JFKIST", "KLMDelta")
  expect_equal(flight3$airline, "KLM, Delta")
  
  # Test case 4: Multiple fused names
  flight4 <- flight_record("2025-07-20", "JFKIST", "Virgin AtlanticDelta")
  expect_equal(flight4$airline, "Virgin Atlantic, Delta")
  
  # Test case 5: Three airlines fused
  flight5 <- flight_record("2025-07-20", "JFKIST", "Aer LingusAmerican")
  expect_equal(flight5$airline, "Aer Lingus, American")
  
  # Test case 6: Already correctly formatted (with comma) should not change
  flight6 <- flight_record("2025-07-20", "JFKIST", "American, British Airways")
  expect_equal(flight6$airline, "American, British Airways")
  
  # Test case 7: Multiple airlines already with commas (should preserve)
  flight7 <- flight_record("2025-07-20", "JFKIST", "Lufthansa, Austrian, Brussels Airlines")
  expect_equal(flight7$airline, "Lufthansa, Austrian, Brussels Airlines")
  
  # Test case 8: Fused at the beginning
  flight8 <- flight_record("2025-07-20", "JFKIST", "UnitedLufthansa, Austrian, Brussels Airlines")
  expect_equal(flight8$airline, "United, Lufthansa, Austrian, Brussels Airlines")
})
