#' Scrape Best One-Way Flights Across Multiple Dates and Routes
#'
#' @description
#' Scrapes Google Flights for the cheapest one-way flights per day across
#' multiple origin-destination pairs and a range of dates. This function is
#' designed for flexible travel planning where you want to compare prices
#' across different airports and dates.
#'
#' @param routes A data frame with columns: City, Airport, Dest, and optionally Comment.
#'   Each row represents an origin airport to search from.
#' @param dates A vector of dates (Date objects or character strings in "YYYY-MM-DD" format)
#'   to search across.
#' @param keep_offers Logical. If TRUE, stores all flight offers in a list-column.
#'   If FALSE (default), only keeps the cheapest offer per day. Default is FALSE.
#' @param pause Numeric. Number of seconds to pause between scraping requests for
#'   rate limiting. Default is 2 seconds.
#' @param headless Logical. If TRUE, runs browser in headless mode (no GUI, default).
#' @param verbose Logical. If TRUE, shows detailed progress information (default).
#' @param currency_format Logical. If TRUE and scales package is available, formats
#'   prices with currency symbols. Default is FALSE.
#'
#' @return A data frame with columns: City, Airport, Dest, Date, Price, and
#'   optionally Comment and Offers (if keep_offers=TRUE). Each row represents
#'   the cheapest flight for a given route and date combination.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(tibble)
#' routes <- tribble(
#'   ~City,      ~Airport, ~Dest, ~Comment,
#'   "Mumbai",   "BOM",    "JFK", "Original flight",
#'   "Delhi",    "DEL",    "JFK", "",
#'   "Varanasi", "VNS",    "JFK", ""
#' )
#' dates <- seq(as.Date("2025-12-18"), as.Date("2026-01-05"), by = "day")
#'
#' results <- fa_scrape_best_oneway(routes, dates, pause = 3, verbose = TRUE)
#' }
fa_scrape_best_oneway <- function(
  routes,
  dates,
  keep_offers = FALSE,
  pause = 2,
  headless = TRUE,
  verbose = TRUE,
  currency_format = FALSE
) {
  # Validate inputs
  if (!is.data.frame(routes)) {
    stop("routes must be a data frame")
  }

  required_cols <- c("City", "Airport", "Dest")
  if (!all(required_cols %in% names(routes))) {
    stop(sprintf(
      "routes must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }

  # Convert dates to Date objects if they're character strings
  if (is.character(dates)) {
    dates <- as.Date(dates)
  }

  # Convert Date objects to character strings in YYYY-MM-DD format
  dates_char <- format(dates, "%Y-%m-%d")

  if (verbose) {
    cat(sprintf(
      "Searching %d routes across %d dates (%d total queries)...\n",
      nrow(routes),
      length(dates),
      nrow(routes) * length(dates)
    ))
  }

  # Create all combinations of routes and dates
  combinations <- expand.grid(
    route_idx = seq_len(nrow(routes)),
    date_idx = seq_len(length(dates)),
    stringsAsFactors = FALSE
  )

  # Pre-allocate results list
  results_list <- vector("list", nrow(combinations))

  # Initialize chromote browser once for all scraping
  browser <- NULL

  tryCatch(
    {
      browser <- initialize_chromote_browser(headless = headless)

      if (is.null(browser)) {
        stop("Failed to initialize Chrome browser")
      }

      # Iterate through all combinations
      for (i in seq_len(nrow(combinations))) {
        route_idx <- combinations$route_idx[i]
        date_idx <- combinations$date_idx[i]

        origin <- routes$Airport[route_idx]
        dest <- routes$Dest[route_idx]
        city <- routes$City[route_idx]
        date <- dates_char[date_idx]

        if (verbose) {
          cat(sprintf(
            "[%d/%d] %s (%s) -> %s on %s\n",
            i,
            nrow(combinations),
            city,
            origin,
            dest,
            date
          ))
        }

        # Create Scrape object
        scrape_obj <- tryCatch(
          {
            Scrape(origin, dest, date)
          },
          error = function(e) {
            if (verbose) {
              cat(sprintf("  [!] Error creating Scrape object: %s\n", e$message))
            }
            return(NULL)
          }
        )

        if (!is.null(scrape_obj)) {
          # Scrape data using existing browser
          scrape_obj <- tryCatch(
            {
              scrape_data_chromote(scrape_obj, browser, verbose = FALSE)
            },
            error = function(e) {
              if (verbose) {
                cat(sprintf("  [!] Error scraping: %s\n", e$message))
              }
              scrape_obj$data <- data.frame()
              scrape_obj
            }
          )

          # Filter out placeholder rows
          if (nrow(scrape_obj$data) > 0) {
            scrape_obj$data <- filter_placeholder_rows(scrape_obj$data)
          }

          # Extract cheapest flight or store all offers
          if (nrow(scrape_obj$data) > 0) {
            if (keep_offers) {
              # Store all offers
              results_list[[i]] <- data.frame(
                City = city,
                Airport = origin,
                Dest = dest,
                Date = date,
                Price = min(scrape_obj$data$price, na.rm = TRUE),
                Offers = I(list(scrape_obj$data)),
                stringsAsFactors = FALSE
              )
            } else {
              # Only keep cheapest
              min_price_idx <- which.min(scrape_obj$data$price)
              results_list[[i]] <- data.frame(
                City = city,
                Airport = origin,
                Dest = dest,
                Date = date,
                Price = scrape_obj$data$price[min_price_idx],
                stringsAsFactors = FALSE
              )
            }

            if (verbose) {
              cat(sprintf(
                "  [OK] Found %d flights, cheapest: $%d\n",
                nrow(scrape_obj$data),
                results_list[[i]]$Price
              ))
            }
          } else {
            if (verbose) {
              cat("  [!] No valid flights found\n")
            }
          }
        }

        # Rate limiting
        if (i < nrow(combinations)) {
          Sys.sleep(pause)
        }
      }

      # Close browser
      close_chromote_safely(browser)
    },
    error = function(e) {
      if (!is.null(browser)) {
        tryCatch(close_chromote_safely(browser), error = function(e2) {})
      }
      stop(sprintf("Error during scraping: %s", e$message), call. = FALSE)
    }
  )

  # Combine results
  results <- do.call(rbind, results_list[!sapply(results_list, is.null)])

  # Add Comment column if it exists in routes
  if ("Comment" %in% names(routes)) {
    results$Comment <- routes$Comment[match(
      paste(results$City, results$Airport),
      paste(routes$City, routes$Airport)
    )]
  }

  # Format currency if requested
  if (currency_format && requireNamespace("scales", quietly = TRUE)) {
    results$Price_Formatted <- scales::dollar(results$Price)
  }

  if (verbose) {
    cat(sprintf("\n[DONE] Retrieved %d results\n", nrow(results)))
  }

  return(results)
}

#' Filter Out Placeholder Rows from Flight Data
#'
#' @description
#' Removes placeholder rows from scraped flight data, such as "Price graph",
#' "Price unavailable", etc.
#'
#' @param data A data frame of flight data with an 'airlines' column
#'
#' @return A filtered data frame with placeholder rows removed
#'
#' @keywords internal
filter_placeholder_rows <- function(data) {
  if (nrow(data) == 0 || !"airlines" %in% names(data)) {
    return(data)
  }

  # Define patterns to filter out
  placeholder_patterns <- c(
    "Price graph",
    "Price unavailable",
    "^\\s*$" # Empty or whitespace-only
  )

  # Create filter condition
  keep_rows <- rep(TRUE, nrow(data))

  for (pattern in placeholder_patterns) {
    keep_rows <- keep_rows & !grepl(pattern, data$airlines, ignore.case = TRUE)
  }

  # Also filter out rows with NA prices
  if ("price" %in% names(data)) {
    keep_rows <- keep_rows & !is.na(data$price)
  }

  return(data[keep_rows, , drop = FALSE])
}

#' Create Flexible Date Summary Table
#'
#' @description
#' Creates a wide summary table showing prices by city/airport and date,
#' with an average price column. This is useful for visualizing price
#' patterns across multiple dates and comparing different origin airports.
#'
#' @param results A data frame returned by fa_scrape_best_oneway()
#' @param include_comment Logical. If TRUE and Comment column exists, includes
#'   it in the output. Default is TRUE.
#' @param currency_symbol Character. Currency symbol to use for formatting.
#'   Default is "$".
#' @param round_prices Logical. If TRUE, rounds prices to nearest integer.
#'   Default is TRUE.
#'
#' @return A wide data frame with columns: City, Airport, Comment (optional),
#'   one column per date with prices, and an Average_Price column.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # After running fa_scrape_best_oneway()
#' results <- fa_scrape_best_oneway(routes, dates)
#' summary_table <- fa_flex_table(results)
#' print(summary_table)
#' }
fa_flex_table <- function(
  results,
  include_comment = TRUE,
  currency_symbol = "$",
  round_prices = TRUE
) {
  if (!is.data.frame(results)) {
    stop("results must be a data frame")
  }

  required_cols <- c("City", "Airport", "Date", "Price")
  if (!all(required_cols %in% names(results))) {
    stop(sprintf(
      "results must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }

  # Convert Date to character if it's not already
  if (!is.character(results$Date)) {
    results$Date <- as.character(results$Date)
  }

  # Round prices if requested
  if (round_prices) {
    results$Price <- round(results$Price)
  }

  # Reshape to wide format
  # Use stats::reshape to avoid dependency on tidyr
  results_unique <- unique(results[, c("City", "Airport", "Date", "Price")])

  # Create a unique identifier for each City-Airport combination
  results_unique$ID <- paste(results_unique$City, results_unique$Airport, sep = "_")

  # Reshape
  wide_data <- stats::reshape(
    results_unique,
    idvar = "ID",
    timevar = "Date",
    v.names = "Price",
    direction = "wide",
    sep = "_"
  )

  # Extract City and Airport from ID
  id_parts <- strsplit(wide_data$ID, "_")
  wide_data$City <- sapply(id_parts, function(x) x[1])
  wide_data$Airport <- sapply(id_parts, function(x) x[2])

  # Remove ID column
  wide_data$ID <- NULL

  # Calculate average price
  price_cols <- grep("^Price_", names(wide_data))
  wide_data$Average_Price <- rowMeans(wide_data[, price_cols], na.rm = TRUE)

  if (round_prices) {
    wide_data$Average_Price <- round(wide_data$Average_Price)
  }

  # Reorder columns: City, Airport, Comment (if applicable), dates, Average_Price
  base_cols <- c("City", "Airport")

  # Add Comment column if it exists and is requested
  if (include_comment && "Comment" %in% names(results)) {
    # Get unique comments for each City-Airport pair
    comment_map <- unique(results[, c("City", "Airport", "Comment")])
    wide_data <- merge(
      wide_data,
      comment_map,
      by = c("City", "Airport"),
      all.x = TRUE
    )
    base_cols <- c(base_cols, "Comment")
  }

  # Format date column names (remove "Price_" prefix)
  date_cols <- grep("^Price_", names(wide_data))
  date_col_names <- names(wide_data)[date_cols]
  names(wide_data)[date_cols] <- gsub("^Price_", "", date_col_names)

  # Get updated date column positions
  date_cols <- grep("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", names(wide_data))

  # Sort date columns chronologically
  date_names_sorted <- sort(names(wide_data)[date_cols])

  # Reorder all columns
  final_cols <- c(base_cols, date_names_sorted, "Average_Price")
  wide_data <- wide_data[, final_cols]

  # Format prices with currency symbol if scales is available
  if (requireNamespace("scales", quietly = TRUE)) {
    price_format_cols <- c(date_names_sorted, "Average_Price")
    for (col in price_format_cols) {
      if (col %in% names(wide_data)) {
        # Format only non-NA values
        formatted_vals <- ifelse(
          is.na(wide_data[[col]]),
          NA_character_,
          paste0(currency_symbol, format(wide_data[[col]], big.mark = ",", scientific = FALSE))
        )
        wide_data[[col]] <- formatted_vals
      }
    }
  }

  return(wide_data)
}

#' Extract Best Dates from Flight Search Results
#'
#' @description
#' Identifies and returns the top N dates with the cheapest average prices
#' across all routes. This helps quickly identify the best travel dates
#' when planning a flexible trip.
#'
#' @param results A data frame returned by fa_scrape_best_oneway()
#' @param n Integer. Number of best dates to return. Default is 10.
#' @param by Character. How to calculate best dates: "mean" (average price
#'   across routes), "median", or "min" (lowest price on that date).
#'   Default is "mean".
#'
#' @return A data frame with columns: Date, Price (average/median/min),
#'   and N_Routes (number of routes with data for that date).
#'   Sorted by price (cheapest first).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # After running fa_scrape_best_oneway()
#' results <- fa_scrape_best_oneway(routes, dates)
#' best_dates <- fa_best_dates(results, n = 5, by = "mean")
#' print(best_dates)
#' }
fa_best_dates <- function(results, n = 10, by = "mean") {
  if (!is.data.frame(results)) {
    stop("results must be a data frame")
  }

  required_cols <- c("Date", "Price")
  if (!all(required_cols %in% names(results))) {
    stop(sprintf(
      "results must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }

  if (!by %in% c("mean", "median", "min")) {
    stop("by must be one of: 'mean', 'median', 'min'")
  }

  # Aggregate by date
  date_summary <- stats::aggregate(
    Price ~ Date,
    data = results,
    FUN = function(x) {
      switch(by,
        mean = mean(x, na.rm = TRUE),
        median = stats::median(x, na.rm = TRUE),
        min = min(x, na.rm = TRUE)
      )
    }
  )

  # Count number of routes per date
  route_counts <- stats::aggregate(
    Price ~ Date,
    data = results,
    FUN = function(x) sum(!is.na(x))
  )
  names(route_counts)[2] <- "N_Routes"

  # Combine
  date_summary <- merge(date_summary, route_counts, by = "Date")

  # Sort by price
  date_summary <- date_summary[order(date_summary$Price), ]

  # Return top n
  if (n < nrow(date_summary)) {
    date_summary <- date_summary[1:n, ]
  }

  rownames(date_summary) <- NULL

  return(date_summary)
}
