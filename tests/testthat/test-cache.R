test_that("check_scrape validates Scrape objects", {
  scrape <- Scrape("JFK", "IST", "2023-07-20")
  expect_true(flightanalysis:::check_scrape(scrape))

  not_scrape <- list(a = 1, b = 2)
  expect_false(flightanalysis:::check_scrape(not_scrape))
})

test_that("get_file_name generates correct filenames", {
  fname <- flightanalysis:::get_file_name("JFK", "IST", access = FALSE)
  expect_equal(fname, "IST-JFK.csv") # Alphabetically sorted

  fname2 <- flightanalysis:::get_file_name("RDU", "LGA", access = FALSE)
  expect_equal(fname2, "LGA-RDU.csv")

  fname_access <- flightanalysis:::get_file_name("JFK", "IST", access = TRUE)
  expect_equal(fname_access, "IST-JFK.txt")
})

test_that("check_dir handles directory paths correctly", {
  dir_info <- flightanalysis:::check_dir("/tmp/test_cache")

  expect_true(grepl("/$", dir_info$directory))
  expect_true(grepl("\\.access/$", dir_info$access_dir))
})

test_that("check_dir handles database paths correctly", {
  dir_info <- flightanalysis:::check_dir("/tmp/flights.db")

  expect_true(grepl("\\.db$", dir_info$directory))
})
