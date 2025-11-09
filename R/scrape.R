#' Create a Scrape Object
#'
#' @description
#' Creates a Scrape object representing a Google Flights query. Supports one-way,
#' round-trip, chain-trip, and perfect-chain trip types.
#'
#' @param ... Arguments defining the trip. Format depends on trip type:
#'   - One-way: origin, dest, date
#'   - Round-trip: origin, dest, date_leave, date_return
#'   - Chain-trip: org1, dest1, date1, org2, dest2, date2, ...
#'   - Perfect-chain: org1, date1, org2, date2, ..., final_dest
#'
#' @return A Scrape object (S3 class)
#' @export
#'
#' @examples
#' \dontrun{
#' # One-way trip
#' scrape1 <- Scrape("JFK", "IST", "2023-07-20")
#' 
#' # Round-trip
#' scrape2 <- Scrape("JFK", "IST", "2023-07-20", "2023-08-20")
#' 
#' # Chain-trip
#' scrape3 <- Scrape("JFK", "IST", "2023-08-20", "RDU", "LGA", "2023-12-25")
#' }
Scrape <- function(...) {
  args <- list(...)
  
  # Initialize Scrape object
  scrape <- list(
    origin = NULL,
    dest = NULL,
    date = NULL,
    data = data.frame(),
    url = NULL,
    type = NULL
  )
  
  # Set properties based on arguments
  scrape <- set_properties(scrape, args)
  
  class(scrape) <- "Scrape"
  return(scrape)
}

#' Set Scrape Properties
#' 
#' @param scrape Scrape object being constructed
#' @param args List of arguments
#' @keywords internal
set_properties <- function(scrape, args) {
  n_args <- length(args)
  date_format <- "%Y-%m-%d"
  
  # One-way trip (3 arguments)
  if (n_args == 3) {
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("Origin must be 3-character string")
    }
    if (!(nchar(args[[2]]) == 3 && is.character(args[[2]]))) {
      stop("Destination must be 3-character string")
    }
    if (!(nchar(args[[3]]) == 10 && is.character(args[[3]]))) {
      stop("Date must be in YYYY-MM-DD format")
    }
    
    scrape$origin <- list(args[[1]])
    scrape$dest <- list(args[[2]])
    scrape$date <- list(args[[3]])
    scrape$url <- make_url(scrape$origin, scrape$dest, scrape$date)
    scrape$type <- "one-way"
  }
  # Round-trip (4 arguments)
  else if (n_args == 4) {
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("Origin must be 3-character string")
    }
    if (!(nchar(args[[2]]) == 3 && is.character(args[[2]]))) {
      stop("Destination must be 3-character string")
    }
    if (!(nchar(args[[3]]) == 10 && is.character(args[[3]]))) {
      stop("Date leave must be in YYYY-MM-DD format")
    }
    if (!(nchar(args[[4]]) == 10 && is.character(args[[4]]))) {
      stop("Date return must be in YYYY-MM-DD format")
    }
    
    date1 <- as.Date(args[[3]], date_format)
    date2 <- as.Date(args[[4]], date_format)
    if (!(date1 < date2)) {
      stop("Dates must be in increasing order")
    }
    
    scrape$origin <- list(args[[1]], args[[2]])
    scrape$dest <- list(args[[2]], args[[1]])
    scrape$date <- list(args[[3]], args[[4]])
    scrape$url <- make_url(scrape$origin, scrape$dest, scrape$date)
    scrape$type <- "round-trip"
  }
  # Chain-trip (multiples of 3, last element is a date)
  else if (n_args >= 3 && n_args %% 3 == 0 && 
           nchar(args[[n_args]]) == 10 && is.character(args[[n_args]])) {
    scrape$origin <- list()
    scrape$dest <- list()
    scrape$date <- list()
    
    for (i in seq(1, n_args, by = 3)) {
      if (!(nchar(args[[i]]) == 3 && is.character(args[[i]]))) {
        stop(sprintf("Argument %d must be 3-character string", i))
      }
      if (!(nchar(args[[i+1]]) == 3 && is.character(args[[i+1]]))) {
        stop(sprintf("Argument %d must be 3-character string", i+1))
      }
      if (!(nchar(args[[i+2]]) == 10 && is.character(args[[i+2]]))) {
        stop(sprintf("Argument %d must be in YYYY-MM-DD format", i+2))
      }
      
      if (length(scrape$date) > 0) {
        prev_date <- as.Date(scrape$date[[length(scrape$date)]], date_format)
        curr_date <- as.Date(args[[i+2]], date_format)
        if (!(prev_date < curr_date)) {
          stop("Dates must be in increasing order")
        }
      }
      
      scrape$origin <- c(scrape$origin, args[[i]])
      scrape$dest <- c(scrape$dest, args[[i+1]])
      scrape$date <- c(scrape$date, args[[i+2]])
    }
    
    scrape$url <- make_url(scrape$origin, scrape$dest, scrape$date)
    scrape$type <- "chain-trip"
  }
  # Perfect-chain (odd number >= 5, last element is 3-character string)
  else if (n_args >= 5 && n_args %% 2 == 1 && 
           nchar(args[[n_args]]) == 3 && is.character(args[[n_args]])) {
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("First argument must be 3-character string")
    }
    if (!(nchar(args[[2]]) == 10 && is.character(args[[2]]))) {
      stop("Second argument must be in YYYY-MM-DD format")
    }
    
    scrape$origin <- list(args[[1]])
    scrape$dest <- list()
    scrape$date <- list(args[[2]])
    
    for (i in seq(3, n_args - 1, by = 2)) {
      if (!(nchar(args[[i]]) == 3 && is.character(args[[i]]))) {
        stop(sprintf("Argument %d must be 3-character string", i))
      }
      if (!(nchar(args[[i+1]]) == 10 && is.character(args[[i+1]]))) {
        stop(sprintf("Argument %d must be in YYYY-MM-DD format", i+1))
      }
      
      prev_date <- as.Date(scrape$date[[length(scrape$date)]], date_format)
      curr_date <- as.Date(args[[i+1]], date_format)
      if (!(prev_date < curr_date)) {
        stop("Dates must be in increasing order")
      }
      
      scrape$origin <- c(scrape$origin, args[[i]])
      scrape$dest <- c(scrape$dest, args[[i]])
      scrape$date <- c(scrape$date, args[[i+1]])
    }
    
    if (!(nchar(args[[n_args]]) == 3 && is.character(args[[n_args]]))) {
      stop("Last argument must be 3-character string")
    }
    scrape$dest <- c(scrape$dest, args[[n_args]])
    
    scrape$url <- make_url(scrape$origin, scrape$dest, scrape$date)
    scrape$type <- "perfect-chain"
  }
  else {
    stop("Invalid arguments. See documentation for proper formats.")
  }
  
  return(scrape)
}

#' Make URL for Google Flights Query
#' 
#' @param origins List of origin airports
#' @param dests List of destination airports
#' @param dates List of dates
#' @keywords internal
make_url <- function(origins, dests, dates) {
  urls <- list()
  for (i in seq_along(dates)) {
    url <- sprintf(
      "https://www.google.com/travel/flights?hl=en&q=Flights%%20to%%20%s%%20from%%20%s%%20on%%20%s%%20oneway",
      origins[[i]], dests[[i]], dates[[i]]
    )
    urls <- c(urls, url)
  }
  return(urls)
}

#' Print method for Scrape objects
#' @param x A Scrape object
#' @param ... Additional arguments (ignored)
#' @export
print.Scrape <- function(x, ...) {
  cat("Scrape( ")
  
  if (nrow(x$data) == 0) {
    cat("{Query Not Yet Used}\n")
  } else {
    cat(sprintf("{%d} RESULTS FOR:\n", nrow(x$data)))
  }
  
  for (i in seq_along(x$date)) {
    cat(sprintf("%s: %s --> %s\n", x$date[[i]], x$origin[[i]], x$dest[[i]]))
  }
  
  cat(")")
  invisible(x)
}

#' Scrape Flight Objects
#'
#' @description
#' Scrapes flight data from Google Flights using RSelenium. This function will
#' automatically set up a Chrome browser, navigate to Google Flights URLs, and
#' extract flight information.
#'
#' @param objs A Scrape object or list of Scrape objects
#' @param deep_copy Logical. If TRUE, returns a copy of the objects
#' @param headless Logical. If TRUE, runs browser in headless mode (no GUI)
#'
#' @return Modified Scrape object(s) with scraped data
#' @export
#'
#' @examples
#' \dontrun{
#' scrape <- Scrape("JFK", "IST", "2023-07-20", "2023-08-20")
#' ScrapeObjects(scrape)
#' }
ScrapeObjects <- function(objs, deep_copy = FALSE, headless = TRUE) {
  # Check if RSelenium is available
  if (!requireNamespace("RSelenium", quietly = TRUE)) {
    stop("RSelenium package is required. Install it with: install.packages('RSelenium')")
  }
  
  # Ensure objs is a list
  if (inherits(objs, "Scrape")) {
    objs <- list(objs)
  }
  
  # Initialize RSelenium driver
  cat("Initializing Chrome driver...\n")
  
  tryCatch({
    # Try to start Chrome driver with wdman
    if (requireNamespace("wdman", quietly = TRUE)) {
      driver <- start_chrome_driver(headless = headless)
    } else {
      # Fallback to rsDriver
      driver <- start_chrome_driver_fallback(headless = headless)
    }
    
    # Scrape each object
    if (requireNamespace("progress", quietly = TRUE)) {
      pb <- progress::progress_bar$new(
        format = "Scraping [:bar] :percent eta: :eta",
        total = length(objs), clear = FALSE
      )
      
      for (obj in objs) {
        scrape_data(obj, driver)
        pb$tick()
      }
    } else {
      cat("Scraping objects...\n")
      for (i in seq_along(objs)) {
        cat(sprintf("  Processing %d of %d...\n", i, length(objs)))
        scrape_data(objs[[i]], driver)
      }
    }
    
    # Close driver
    cat("Closing browser...\n")
    tryCatch({
      driver$client$close()
      if (!is.null(driver$server)) {
        driver$server$stop()
      }
    }, error = function(e) {
      # Ignore errors on close
    })
    
  }, error = function(e) {
    stop(sprintf("Error during web scraping: %s\n\nMake sure Chrome/Chromium is installed and accessible.", e$message))
  })
  
  if (deep_copy) {
    return(objs)
  }
  
  invisible(objs)
}

#' Start Chrome Driver using wdman
#' @keywords internal
start_chrome_driver <- function(headless = TRUE) {
  chrome_driver <- wdman::chrome(check = TRUE)
  
  chrome_options <- list(
    chromeOptions = list(
      args = if (headless) c('--headless', '--disable-gpu', '--no-sandbox') else c()
    )
  )
  
  driver <- RSelenium::remoteDriver(
    browserName = "chrome",
    port = chrome_driver$port,
    extraCapabilities = chrome_options
  )
  
  driver$open()
  driver$maxWindowSize()
  
  list(client = driver, server = chrome_driver)
}

#' Start Chrome Driver fallback method
#' @keywords internal
start_chrome_driver_fallback <- function(headless = TRUE) {
  extra_caps <- list(
    chromeOptions = list(
      args = if (headless) c('--headless', '--disable-gpu', '--no-sandbox') else c()
    )
  )
  
  rD <- RSelenium::rsDriver(
    browser = "chrome",
    chromever = "latest",
    extraCapabilities = extra_caps,
    verbose = FALSE
  )
  
  rD$client$maxWindowSize()
  
  rD
}

#' Scrape data for a single Scrape object
#' @keywords internal
scrape_data <- function(obj, driver) {
  results_list <- list()
  
  for (i in seq_along(obj$url)) {
    result <- get_results(obj$url[[i]], obj$date[[i]], driver$client)
    if (!is.null(result) && nrow(result) > 0) {
      results_list[[i]] <- result
    }
  }
  
  if (length(results_list) > 0) {
    obj$data <- do.call(rbind, results_list)
    rownames(obj$data) <- NULL
  }
  
  invisible(obj)
}

#' Get results from a single URL
#' @keywords internal
get_results <- function(url, date, driver) {
  tryCatch({
    results <- make_url_request(url, driver)
    flights <- clean_results(results, date)
    flights_to_dataframe(flights)
  }, error = function(e) {
    warning(sprintf("Failed to scrape %s: %s", url, e$message))
    return(data.frame())
  })
}

#' Make URL request and wait for content
#' @keywords internal
make_url_request <- function(url, driver) {
  driver$navigate(url)
  
  # Wait for page to load - check that we have enough content
  max_attempts <- 20
  for (attempt in 1:max_attempts) {
    Sys.sleep(0.5)
    results <- get_flight_elements(driver)
    if (length(results) > 100) {
      break
    }
  }
  
  if (length(results) <= 100) {
    stop("Timeout: Page did not load sufficient content. Check your internet connection or verify flights exist for this query.")
  }
  
  results
}

#' Get flight elements from page
#' @keywords internal
get_flight_elements <- function(driver) {
  tryCatch({
    body_element <- driver$findElement(using = "xpath", value = '//body[@id = "yDmH0d"]')
    text <- body_element$getElementText()[[1]]
    strsplit(text, "\n")[[1]]
  }, error = function(e) {
    character(0)
  })
}

#' Clean and parse results from scraped page
#' @keywords internal
clean_results <- function(result, date) {
  # Clean results - remove non-ASCII and strip whitespace
  res2 <- sapply(result, function(x) {
    iconv(x, from = "UTF-8", to = "ASCII", sub = "")
  })
  res2 <- trimws(res2)
  
  # Find section boundaries
  start_idx <- which(res2 == "Sort by:")
  if (length(start_idx) == 0) {
    warning("Could not find 'Sort by:' marker in results")
    return(list())
  }
  start_idx <- start_idx[1] + 1
  
  mid_start_idx <- which(res2 == "Price insights")
  if (length(mid_start_idx) == 0) {
    mid_start_idx <- length(res2)
  } else {
    mid_start_idx <- mid_start_idx[1]
  }
  
  # Find "Other departing flights" or "Other flights"
  mid_end_idx <- which(res2 == "Other departing flights")
  if (length(mid_end_idx) == 0) {
    mid_end_idx <- which(res2 == "Other flights")
  }
  if (length(mid_end_idx) == 0) {
    mid_end_idx <- mid_start_idx + 1
  } else {
    mid_end_idx <- mid_end_idx[1] + 1
  }
  
  # Find end marker
  end_idx <- which(grepl("more flights$", res2))
  if (length(end_idx) == 0) {
    end_idx <- length(res2)
  } else {
    end_idx <- end_idx[1]
  }
  
  # Extract flight data section
  res3 <- c(res2[start_idx:(mid_start_idx-1)], res2[mid_end_idx:(end_idx-1)])
  
  # Find flight time markers (entries ending with AM or PM, or with + offset)
  is_time_marker <- function(x) {
    if (nchar(x) <= 2) return(FALSE)
    has_colon <- grepl(":", x)
    ends_ampm <- grepl("(AM|PM)$", x)
    has_plus <- substr(x, nchar(x)-1, nchar(x)-1) == "+"
    return(has_colon && (ends_ampm || has_plus))
  }
  
  matches <- which(sapply(res3, is_time_marker))
  # Take every other match (departure times, not arrival times shown separately)
  matches <- matches[seq(1, length(matches), by = 2)]
  
  # Create Flight objects from matched sections
  flights <- list()
  for (i in seq_along(matches[-length(matches)])) {
    start <- matches[i]
    end <- matches[i + 1] - 1
    flight_data <- res3[start:end]
    flights[[i]] <- Flight(date, flight_data)
  }
  
  flights
}
