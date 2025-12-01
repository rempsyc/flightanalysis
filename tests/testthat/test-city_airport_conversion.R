test_that("excluded_airports filters out specified airport codes", {
  # Test that CXH (Vancouver seaplane terminal) is filtered out
  # CXH should be in the excluded_airports list by default
  expect_true("CXH" %in% flightanalysis:::excluded_airports)
})

test_that("city_name_to_code filters out excluded airports", {
  # Skip if airportr package is not available
  skip_if_not_installed("airportr")
  
  # Vancouver should return YVR but not CXH (which is in excluded_airports)
  codes <- city_name_to_code("Vancouver")
  
  # Should not include CXH (seaplane terminal)
  expect_false("CXH" %in% codes)
  
  # Should include YVR (main airport)
  expect_true("YVR" %in% codes)
})

test_that("excluded airports filtering works with cities that have multiple airports", {
  # Skip if airportr package is not available
  skip_if_not_installed("airportr")
  
  # Test with a city that has both excluded and non-excluded airports
  # Vancouver has YVR (included) and CXH (excluded)
  codes <- city_name_to_code("Vancouver")
  
  # At least one code should be returned (YVR)
  expect_true(length(codes) >= 1)
  
  # None of the returned codes should be in the excluded list
  expect_false(any(codes %in% flightanalysis:::excluded_airports))
})
