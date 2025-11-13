#' Define Flight Query
#'
#' @description
#' Defines a flight query for Google Flights. Supports one-way,
#' round-trip, chain-trip, and perfect-chain trip types.
#'
#' @param ... Arguments defining the trip. Format depends on trip type:
#'   - One-way: origin, dest, date
#'   - Round-trip: origin, dest, date_leave, date_return
#'   - Chain-trip: org1, dest1, date1, org2, dest2, date2, ...
#'   - Perfect-chain: org1, date1, org2, date2, ..., final_dest
#'
#' @return A flight query object (S3 class "flight_query")
#' @export
#'
#' @examples
#' \dontrun{
#' # One-way trip
#' query1 <- define_query("JFK", "BOS", "2025-12-20")
#'
#' # Round-trip
#' query2 <- define_query("JFK", "YUL", "2025-12-20", "2025-12-25")
#'
#' # Chain-trip
#' query3 <- define_query("JFK", "YYZ", "2025-12-20", "RDU", "LGA", "2025-12-25")
#' }
define_query <- function(...) {
  args <- list(...)

  # Initialize query object
  query <- list(
    origin = NULL,
    dest = NULL,
    date = NULL,
    data = data.frame(),
    url = NULL,
    type = NULL
  )

  # Set properties based on arguments
  query <- set_properties(query, args)

  class(query) <- "flight_query"
  return(query)
}

#' Set Scrape Properties
#'
#' @param scrape Scrape object being constructed
#' @param args List of arguments
#' @keywords internal
set_properties <- function(scrape, args) {
  n_args <- length(args)
  date_format <- "%Y-%m-%d"

  # Helper function to validate date format
  validate_date <- function(date_str, arg_name = "Date") {
    if (!(nchar(date_str) == 10 && is.character(date_str))) {
      stop(sprintf("%s must be in YYYY-MM-DD format", arg_name))
    }
    # Try to parse the date
    parsed_date <- tryCatch(
      {
        as.Date(date_str, date_format)
      },
      error = function(e) {
        stop(sprintf(
          "%s '%s' is not a valid date in YYYY-MM-DD format",
          arg_name,
          date_str
        ))
      }
    )
    # Check if parsed successfully
    if (is.na(parsed_date)) {
      stop(sprintf(
        "%s '%s' is not a valid date in YYYY-MM-DD format",
        arg_name,
        date_str
      ))
    }
    return(parsed_date)
  }

  # One-way trip (3 arguments)
  if (n_args == 3) {
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("Origin must be 3-character string")
    }
    if (!(nchar(args[[2]]) == 3 && is.character(args[[2]]))) {
      stop("Destination must be 3-character string")
    }
    validate_date(args[[3]], "Date")

    query$origin <- list(args[[1]])
    query$dest <- list(args[[2]])
    query$date <- list(args[[3]])
    query$url <- make_url(query$origin, query$dest, query$date)
    query$type <- "one-way"
  } else if (n_args == 4) {
    # Round-trip (4 arguments)
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("Origin must be 3-character string")
    }
    if (!(nchar(args[[2]]) == 3 && is.character(args[[2]]))) {
      stop("Destination must be 3-character string")
    }
    date1 <- validate_date(args[[3]], "Date leave")
    date2 <- validate_date(args[[4]], "Date return")

    if (!(date1 < date2)) {
      stop("Dates must be in increasing order")
    }

    query$origin <- list(args[[1]], args[[2]])
    query$dest <- list(args[[2]], args[[1]])
    query$date <- list(args[[3]], args[[4]])
    query$url <- make_url(query$origin, query$dest, query$date)
    query$type <- "round-trip"
  } else if (
    n_args >= 3 &&
      n_args %% 3 == 0 &&
      nchar(args[[n_args]]) == 10 &&
      is.character(args[[n_args]])
  ) {
    # Chain-trip (multiples of 3, last element is a date)
    query$origin <- list()
    query$dest <- list()
    query$date <- list()

    for (i in seq(1, n_args, by = 3)) {
      if (!(nchar(args[[i]]) == 3 && is.character(args[[i]]))) {
        stop(sprintf("Argument %d must be 3-character string", i))
      }
      if (!(nchar(args[[i + 1]]) == 3 && is.character(args[[i + 1]]))) {
        stop(sprintf("Argument %d must be 3-character string", i + 1))
      }
      curr_date <- validate_date(
        args[[i + 2]],
        sprintf("Argument %d (date)", i + 2)
      )

      if (length(query$date) > 0) {
        prev_date <- as.Date(query$date[[length(query$date)]], date_format)
        if (!(prev_date < curr_date)) {
          stop("Dates must be in increasing order")
        }
      }

      query$origin <- c(query$origin, args[[i]])
      query$dest <- c(query$dest, args[[i + 1]])
      query$date <- c(query$date, args[[i + 2]])
    }

    query$url <- make_url(query$origin, query$dest, query$date)
    query$type <- "chain-trip"
  } else if (
    n_args >= 5 &&
      n_args %% 2 == 1 &&
      nchar(args[[n_args]]) == 3 &&
      is.character(args[[n_args]])
  ) {
    # Perfect-chain (odd number >= 5, last element is 3-character string)
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("First argument must be 3-character string")
    }
    validate_date(args[[2]], "Second argument (date)")

    query$origin <- list(args[[1]])
    query$dest <- list()
    query$date <- list(args[[2]])

    for (i in seq(3, n_args - 1, by = 2)) {
      if (!(nchar(args[[i]]) == 3 && is.character(args[[i]]))) {
        stop(sprintf("Argument %d must be 3-character string", i))
      }
      curr_date <- validate_date(
        args[[i + 1]],
        sprintf("Argument %d (date)", i + 1)
      )

      prev_date <- as.Date(query$date[[length(query$date)]], date_format)
      if (!(prev_date < curr_date)) {
        stop("Dates must be in increasing order")
      }

      query$origin <- c(query$origin, args[[i]])
      query$dest <- c(query$dest, args[[i]])
      query$date <- c(query$date, args[[i + 1]])
    }

    if (!(nchar(args[[n_args]]) == 3 && is.character(args[[n_args]]))) {
      stop("Last argument must be 3-character string")
    }
    query$dest <- c(query$dest, args[[n_args]])

    query$url <- make_url(query$origin, query$dest, query$date)
    query$type <- "perfect-chain"
  } else {
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
      dests[[i]],
      origins[[i]],
      dates[[i]]
    )
    urls <- c(urls, url)
  }
  return(urls)
}

#' Print method for flight query objects
#' @param x A flight query object
#' @param ... Additional arguments (ignored)
#' @export
print.flight_query <- function(x, ...) {
  cat("Flight Query( ")

  if (nrow(x$data) == 0) {
    cat("{Not Yet Fetched}\n")
  } else {
    cat(sprintf("{%d} RESULTS FOR:\n", nrow(x$data)))
  }

  for (i in seq_along(x$date)) {
    cat(sprintf("%s: %s --> %s\n", x$date[[i]], x$origin[[i]], x$dest[[i]]))
  }

  cat(")")
  invisible(x)
}

#' @export
print.Scrape <- print.flight_query

#' Fetch Flight Data
#'
#' @description
#' Fetches flight data from Google Flights using chromote. This function will
#' automatically set up a Chrome browser connection, navigate to Google Flights
#' URLs, and extract flight information. Uses the Chrome DevTools Protocol for
#' reliable, driver-free browser automation. The browser runs in headless mode
#' by default (no visible GUI).
#'
#' @param queries A flight query object or list of query objects (from define_query())
#' @param verbose Logical. If TRUE, shows detailed progress information (default)
#'
#' @return Modified query object(s) with scraped data. **Important:** You must
#'   capture the return value to get the scraped data: `result <- fetch_flights(query)`
#' @export
#'
#' @examples
#' \dontrun{
#' query <- define_query("JFK", "IST", "2025-12-20", "2025-12-25")
#' result <- fetch_flights(query)
#' result$data
#' }
fetch_flights <- function(
  queries,
  verbose = TRUE
) {
  # Check if chromote is available
  if (!requireNamespace("chromote", quietly = TRUE)) {
    stop(
      "chromote package is required for web scraping.\n",
      "Install it with: install.packages('chromote')\n\n",
      "chromote is a modern Chrome automation package that:\n",
      "  - Works without external drivers (no chromedriver needed)\n",
      "  - Is more reliable and easier to use\n",
      "  - Runs fully headless by default\n",
      "  - Uses the Chrome DevTools Protocol directly",
      call. = FALSE
    )
  }

  # Track if input was a single query object
  # Accept both new "flight_query" and legacy "Scrape" classes
  single_object <- inherits(queries, "flight_query") || inherits(queries, "Scrape")

  # Ensure queries is a list
  if (single_object) {
    queries <- list(queries)
  }

  # Pre-flight checks
  check_chrome_installation(verbose = FALSE)
  check_internet_connection(verbose = FALSE)

  # Initialize chromote browser
  browser <- NULL

  tryCatch(
    {
      # Create a Chromote session
      browser <- initialize_chromote_browser()

      if (is.null(browser)) {
        stop(
          "Failed to initialize Chrome browser. Please check Chrome installation."
        )
      }

      # Scrape each object
      if (requireNamespace("progress", quietly = TRUE) && !verbose) {
        pb <- progress::progress_bar$new(
          format = "Scraping [:bar] :percent eta: :eta",
          total = length(queries),
          clear = FALSE
        )

        for (i in seq_along(queries)) {
          queries[[i]] <- scrape_data_chromote(
            queries[[i]],
            browser,
            verbose = verbose
          )
          pb$tick()
        }
      } else {
        if (verbose && length(queries) > 1) {
          cat(sprintf("Scraping %d objects...\n\n", length(queries)))
        }
        for (i in seq_along(queries)) {
          if (verbose && length(queries) > 1) {
            cat(sprintf("[%d/%d] ", i, length(queries)))
          }
          queries[[i]] <- scrape_data_chromote(
            queries[[i]],
            browser,
            verbose = verbose
          )
        }
      }

      # Close browser
      close_chromote_safely(browser)
    },
    error = function(e) {
      # Try to close browser if it was initialized
      if (!is.null(browser)) {
        tryCatch(close_chromote_safely(browser), error = function(e2) {})
      }

      # Provide detailed error message
      error_msg <- sprintf(
        "Error during web scraping: %s\n\nTroubleshooting:\n%s",
        e$message,
        get_troubleshooting_tips_chromote()
      )
      stop(error_msg, call. = FALSE)
    }
  )

  # Return the result
  # If a single Scrape object was passed in, return just that object
  # Otherwise return the list
  if (single_object) {
    return(queries[[1]])
  } else {
    return(queries)
  }
}

#' Check if Chrome/Chromium is installed
#' @keywords internal
check_chrome_installation <- function(verbose = TRUE) {
  # chromote will find Chrome automatically, but we can still warn users
  chrome_paths <- c(
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "C:/Program Files/Google/Chrome/Application/chrome.exe",
    "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"
  )

  chrome_found <- any(file.exists(chrome_paths))

  # Also check if chrome/chromium is in PATH
  if (!chrome_found) {
    chrome_in_path <- tryCatch(
      {
        if (.Platform$OS.type == "windows") {
          system2("where", "chrome", stdout = TRUE, stderr = FALSE)
        } else {
          system2(
            "which",
            c("google-chrome", "chromium", "chromium-browser"),
            stdout = TRUE,
            stderr = FALSE
          )
        }
        TRUE
      },
      error = function(e) FALSE,
      warning = function(w) FALSE
    )

    chrome_found <- chrome_in_path
  }

  if (!chrome_found) {
    if (verbose) {
      message(
        "Note: Chrome/Chromium not found in common locations. chromote will try to find it automatically."
      )
    }
  } else {
    if (verbose) {
      cat("[OK] Chrome/Chromium detected\n")
    }
  }

  invisible(chrome_found)
}

#' Check internet connection
#' @keywords internal
check_internet_connection <- function(verbose = TRUE) {
  connected <- tryCatch(
    {
      con <- url("https://www.google.com", open = "rb")
      close(con)
      TRUE
    },
    error = function(e) FALSE
  )

  if (!connected) {
    if (verbose) {
      cat(
        "[!] Could not verify internet connection via curl (may be blocked by firewall)\n"
      )
      cat("  The browser will attempt to connect anyway...\n")
    }
  } else {
    if (verbose) {
      cat("[OK] Internet connection verified\n")
    }
  }

  invisible(connected)
}

#' Initialize chromote browser
#' @keywords internal
initialize_chromote_browser <- function() {
  tryCatch(
    {
      # Create a new Chromote session
      # chromote automatically finds Chrome and handles everything
      # Runs in headless mode by default
      browser <- chromote::ChromoteSession$new()

      # Give it a moment to fully initialize
      Sys.sleep(1)

      browser
    },
    error = function(e) {
      stop(
        sprintf(
          "Failed to initialize Chrome browser: %s\n\n%s",
          e$message,
          "Please ensure Chrome or Chromium is installed and accessible."
        ),
        call. = FALSE
      )
    }
  )
}

#' Close chromote browser safely
#' @keywords internal
close_chromote_safely <- function(browser) {
  if (is.null(browser)) {
    return(invisible(NULL))
  }

  tryCatch(
    {
      browser$close()
    },
    error = function(e) {
      # Ignore close errors
    }
  )

  invisible(NULL)
}

#' Get troubleshooting tips for chromote
#' @keywords internal
get_troubleshooting_tips_chromote <- function() {
  tips <- c(
    "1. Verify Chrome/Chromium is installed:",
    "   - Ubuntu/Debian: sudo apt-get install chromium-browser",
    "   - macOS: brew install --cask google-chrome",
    "   - Windows: Download from https://www.google.com/chrome/",
    "",
    "2. Check your internet connection:",
    "   - Make sure you can access https://www.google.com/travel/flights",
    "",
    "3. Install/update required packages:",
    "   install.packages(c('chromote', 'progress'))",
    "",
    "4. If issues persist, try:",
    "   - Restart R session",
    "   - Clear browser cache",
    "   - Check firewall settings"
  )
  paste(tips, collapse = "\n")
}

#' Scrape data for a single Scrape object using chromote
#' @keywords internal
scrape_data_chromote <- function(obj, browser, verbose = TRUE) {
  results_list <- list()

  for (i in seq_along(obj$url)) {
    if (verbose) {
      if (length(obj$url) > 1) {
        cat(sprintf(
          "  Segment %d/%d: %s -> %s on %s\n",
          i,
          length(obj$url),
          obj$origin[[i]],
          obj$dest[[i]],
          obj$date[[i]]
        ))
      } else {
        cat(sprintf(
          "Route: %s -> %s on %s\n",
          obj$origin[[i]],
          obj$dest[[i]],
          obj$date[[i]]
        ))
      }
    }

    result <- get_results_chromote(
      obj$url[[i]],
      obj$date[[i]],
      browser,
      verbose = verbose
    )
    if (!is.null(result) && nrow(result) > 0) {
      results_list[[i]] <- result
    }
  }

  if (length(results_list) > 0) {
    obj$data <- do.call(rbind, results_list)
    rownames(obj$data) <- NULL
    if (verbose && length(obj$url) > 1) {
      cat(sprintf("  [OK] Total flights retrieved: %d\n", nrow(obj$data)))
    }
  } else {
    if (verbose) {
      cat("  [!] No flights retrieved\n")
    }
  }

  invisible(obj)
}

#' Get results from a single URL using chromote
#' @keywords internal
get_results_chromote <- function(url, date, browser, verbose = TRUE) {
  tryCatch(
    {
      results <- make_url_request_chromote(url, browser, verbose = verbose)
      flights <- clean_results(results, date, verbose = verbose)
      flights_to_dataframe(flights)
    },
    error = function(e) {
      if (verbose) {
        cat(sprintf("  [X] Failed to scrape: %s\n", e$message))
      } else {
        warning(sprintf("Failed to scrape %s: %s", url, e$message))
      }
      return(data.frame())
    }
  )
}

#' Make URL request and wait for content using chromote
#' @keywords internal
make_url_request_chromote <- function(url, browser, verbose = TRUE) {
  # Navigate to URL
  browser$Page$navigate(url, wait_ = TRUE)

  # Wait for page load event
  browser$Page$loadEventFired(timeout_ = 10000)

  # Wait for network to be idle (important for dynamic content)
  Sys.sleep(2)

  # Wait for specific content to appear (retry logic)
  max_attempts <- 10
  results <- character(0)

  for (attempt in 1:max_attempts) {
    results <- get_flight_elements_chromote(browser)

    # Check if we have substantial content
    if (length(results) > 100) {
      break
    }

    # Wait a bit more for content to load
    Sys.sleep(1)
  }

  if (length(results) <= 100) {
    stop(
      "Page did not load sufficient content. Check your internet connection or verify flights exist for this query."
    )
  }

  results
}

#' Get flight elements from page using chromote
#' @keywords internal
get_flight_elements_chromote <- function(browser) {
  tryCatch(
    {
      # Get the body text using JavaScript
      result <- browser$Runtime$evaluate(
        expression = "document.body.innerText",
        returnByValue = TRUE
      )

      text <- result$result$value
      strsplit(text, "\n")[[1]]
    },
    error = function(e) {
      character(0)
    }
  )
}

#' Clean and parse results from scraped page
#' @keywords internal
clean_results <- function(result, date, verbose = TRUE) {
  # Clean results - remove non-ASCII and strip whitespace
  res2 <- sapply(result, function(x) {
    iconv(x, from = "UTF-8", to = "ASCII", sub = "")
  })
  res2 <- trimws(res2)

  # Find flight time markers (entries ending with AM or PM, or with + offset)
  # These are more stable than UI text markers
  # Support both uppercase (AM/PM) and lowercase (am/pm) formats
  is_time_marker <- function(x) {
    if (nchar(x) <= 2) {
      return(FALSE)
    }
    has_colon <- grepl(":", x)
    ends_ampm <- grepl("(AM|PM|am|pm)$", x)
    has_plus <- substr(x, nchar(x) - 1, nchar(x) - 1) == "+"
    return(has_colon && (ends_ampm || has_plus))
  }

  matches <- which(sapply(res2, is_time_marker))

  if (length(matches) == 0) {
    if (verbose) {
      cat("  [!] No flight time markers found in page content\n")
    }
    warning(
      "Could not find any flight data. Page may not have loaded properly or no flights available."
    )
    return(list())
  }

  # Take every other match (departure times, not arrival times shown separately)
  matches <- matches[seq(1, length(matches), by = 2)]

  if (length(matches) <= 1) {
    if (verbose) {
      cat("  [!] Not enough flight data to parse\n")
    }
    warning("Insufficient flight data found")
    return(list())
  }

  # Create Flight objects from matched sections
  flights <- list()
  for (i in seq_along(matches[-length(matches)])) {
    start <- matches[i]
    end <- matches[i + 1] - 1
    flight_data <- res2[start:end]

    tryCatch(
      {
        # Use do.call to unpack the vector so each element becomes a separate argument
        flights[[i]] <- do.call(Flight, c(list(date), as.list(flight_data)))
      },
      error = function(e) {
        # Silent failure for individual flights - they'll be filtered out
      }
    )
  }

  # Remove NULL entries (failed parses)
  flights <- flights[!sapply(flights, is.null)]

  if (verbose) {
    cat(sprintf("  [OK] Successfully parsed %d flights\n", length(flights)))
  }

  flights
}

#' @rdname define_query
#' @export
Scrape <- function(...) {
  .Deprecated("define_query", package = "flightanalysis",
              msg = "'Scrape()' is deprecated. Use 'define_query()' instead.")
  define_query(...)
}

#' @rdname fetch_flights
#' @export
ScrapeObjects <- function(queries, verbose = TRUE) {
  .Deprecated("fetch_flights", package = "flightanalysis",
              msg = "'ScrapeObjects()' is deprecated. Use 'fetch_flights()' instead.")
  fetch_flights(queries, verbose)
}

#' @rdname fetch_flights
#' @export
scrape_objects <- function(queries, verbose = TRUE) {
  .Deprecated("fetch_flights", package = "flightanalysis",
              msg = "'scrape_objects()' is deprecated. Use 'fetch_flights()' instead.")
  fetch_flights(queries, verbose)
}
