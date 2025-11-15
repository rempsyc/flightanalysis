#' Fetch Flight Data
#'
#' @description
#' Fetches flight data from Google Flights using chromote. This function will
#' automatically set up a Chrome browser connection, navigate to Google Flights
#' URLs, and extract flight information. Uses the Chrome DevTools Protocol for
#' reliable, driver-free browser automation. The browser runs in headless mode
#' by default (no visible GUI).
#'
#' @param queries A flight query object or list of query objects (from fa_define_query())
#' @param verbose Logical. If TRUE, shows detailed progress information (default)
#'
#' @return Modified query object(s) with flight data. **Important:** You must
#'   capture the return value to get the flight data: `result <- fa_fetch_flights(query)`
#' @export
#'
#' @examples
#' \dontrun{
#' query <- fa_define_query("JFK", "IST", "2025-12-20", "2025-12-25")
#' flights <- fa_fetch_flights(query)
#' flights$data
#' }
fa_fetch_flights <- function(
  queries,
  verbose = TRUE
) {
  # Track if input was a single query object
  single_object <- inherits(queries, "flight_query")

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
      if (!verbose) {
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
  # Otherwise return a flight_results object with merged data
  if (single_object) {
    return(queries[[1]])
  } else {
    # Create a flight_results object with merged data
    result <- create_flight_results(queries)
    return(result)
  }
}

#' Create Flight Results Object
#'
#' @description
#' Creates a flight_results object from a list of flight queries.
#' Merges data from all queries into a single data frame accessible via $data,
#' while preserving individual query objects in named list elements.
#'
#' @param queries Named list of flight_query objects
#'
#' @return A flight_results object (S3 class) containing:
#'   - $data: Merged data frame from all queries
#'   - Named elements for each origin query (e.g., $BOM, $DEL)
#'
#' @keywords internal
create_flight_results <- function(queries) {
  # Merge all data from queries
  all_data <- list()
  
  for (i in seq_along(queries)) {
    if (!is.null(queries[[i]]$data) && nrow(queries[[i]]$data) > 0) {
      all_data[[i]] <- queries[[i]]$data
    }
  }
  
  # Combine all data into single data frame
  if (length(all_data) > 0) {
    merged_data <- do.call(rbind, all_data)
    rownames(merged_data) <- NULL
  } else {
    merged_data <- data.frame()
  }
  
  # Create result object
  result <- c(list(data = merged_data), queries)
  class(result) <- "flight_results"
  
  return(result)
}

#' Print method for flight_results objects
#' @param x A flight_results object
#' @param ... Additional arguments (ignored)
#' @export
print.flight_results <- function(x, ...) {
  cat("Flight Results\n")
  cat("==============\n\n")
  
  # Show merged data summary
  if (!is.null(x$data) && nrow(x$data) > 0) {
    cat(sprintf("Total flights: %d\n", nrow(x$data)))
    
    # Show origins if available
    if ("origin" %in% names(x$data)) {
      origins <- unique(x$data$origin)
      cat(sprintf("Origins: %s\n", paste(origins, collapse = ", ")))
    }
    
    # Show destinations if available
    if ("destination" %in% names(x$data)) {
      dests <- unique(x$data$destination)
      cat(sprintf("Destinations: %s\n", paste(dests, collapse = ", ")))
    }
  } else {
    cat("No flight data available\n")
  }
  
  # Show individual queries
  query_names <- setdiff(names(x), "data")
  if (length(query_names) > 0) {
    cat(sprintf("\nIndividual queries: %s\n", paste(query_names, collapse = ", ")))
  }
  
  invisible(x)
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

  return(obj)
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

#' Clean and parse results from page
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
        flights[[i]] <- do.call(
          flight_record,
          c(list(date), as.list(flight_data))
        )
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
