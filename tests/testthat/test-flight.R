test_that("Flight object is created", {
  flight <- Flight("2023-07-20", "JFKIST", "9:00AM", "5:00PM", 
                   "8 hr 0 min", "Nonstop", "150 kg CO2", "10% emissions", "$450")
  
  expect_s3_class(flight, "Flight")
  expect_equal(flight$date, "2023-07-20")
})

test_that("Flight parses origin and destination", {
  flight <- Flight("2023-07-20", "JFKIST")
  
  expect_equal(flight$origin, "JFK")
  expect_equal(flight$dest, "IST")
})

test_that("Flight parses price correctly", {
  flight <- Flight("2023-07-20", "JFKIST", "$450")
  
  expect_equal(flight$price, 450)
  
  flight2 <- Flight("2023-07-20", "JFKIST", "$1,250")
  expect_equal(flight2$price, 1250)
})

test_that("Flight parses stops correctly", {
  flight1 <- Flight("2023-07-20", "JFKIST", "Nonstop")
  expect_equal(flight1$num_stops, 0)
  
  flight2 <- Flight("2023-07-20", "JFKIST", "1 stop")
  expect_equal(flight2$num_stops, 1)
  
  flight3 <- Flight("2023-07-20", "JFKIST", "2 stops")
  expect_equal(flight3$num_stops, 2)
})

test_that("Flight parses CO2 emissions", {
  flight <- Flight("2023-07-20", "JFKIST", "150 kg CO2", "10% emissions")
  
  expect_equal(flight$co2, 150)
  expect_equal(flight$emissions, 10)
})

test_that("Flight parses flight time", {
  flight <- Flight("2023-07-20", "JFKIST", "8 hr 30 min")
  
  expect_equal(flight$flight_time, "8 hr 30 min")
})

test_that("flights_to_dataframe creates data frame", {
  flight1 <- Flight("2023-07-20", "JFKIST", "$450", "Nonstop")
  flight2 <- Flight("2023-07-21", "ISTCDG", "$300", "1 stop")
  
  df <- flights_to_dataframe(list(flight1, flight2))
  
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2)
  expect_true("origin" %in% names(df))
  expect_true("destination" %in% names(df))
  expect_true("price" %in% names(df))
})

test_that("Print method works for Flight", {
  flight <- Flight("2023-07-20", "JFKIST")
  expect_output(print(flight), "Flight")
  expect_output(print(flight), "JFK-->IST")
})
