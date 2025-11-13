#' Find Best Travel Dates
#'
#' @description
#' Identifies and returns the top N dates with the cheapest average prices
#' across all routes. This helps quickly identify the best travel dates
#' when planning a flexible trip.
#'
#' @param results Either:
#'   - A data frame with columns: Date and Price
#'   - A list of flight querys (from fa_create_date_range with multiple origins)
#'   - A single flight query (from fa_create_date_range with single origin)
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
#' # Option 1: Pass list of flight querys directly
#' queries <- fa_create_date_range(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
#' for (code in names(queries)) {
#'   queries[[code]] <- fa_fetch_flights(queries[[code]])
#' }
#' best_dates <- fa_find_best_dates(queries, n = 5, by = "mean")
#'
#' # Option 2: Pass processed data frame
#' best_dates <- fa_find_best_dates(my_data_frame, n = 5, by = "mean")
#' }
fa_find_best_dates <- function(results, n = 10, by = "min") {
  # Handle different input types
  # Check for flight query FIRST (before is.list, since flight queries are lists)
  if (inherits(results, "flight_query")) {
    # Validate flight query has data
    if (is.null(results$data) || nrow(results$data) == 0) {
      stop("flight query contains no data. Please run fa_fetch_flights() first to fetch flight data.")
    }
    # Single flight query - pass directly to extract_data_from_scrapes
    results <- extract_data_from_scrapes(results)
  } else if (is.list(results) && !is.data.frame(results)) {
    # Check if it's a list of flight queries
    if (all(sapply(results, function(x) inherits(x, "flight_query")))) {
      # Extract and combine data from list of flight queries
      results <- extract_data_from_scrapes(results)
    } else {
      stop(
        "results must be a data frame, a flight query, or a list of flight queries"
      )
    }
  } else if (!is.data.frame(results)) {
    stop(
      "results must be a data frame, a flight query, or a list of flight queries"
    )
  }

  required_cols <- c("Date", "Price")
  if (!all(required_cols %in% names(results))) {
    stop(sprintf(
      "results must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }
  
  # Check if we have any data after filtering
  if (nrow(results) == 0) {
    stop("No data available after filtering. The flight query may contain only placeholder rows or no valid flight data.")
  }

  if (!by %in% c("mean", "median", "min")) {
    stop("by must be one of: 'mean', 'median', 'min'")
  }

  # Aggregate by date
  date_summary <- stats::aggregate(
    Price ~ Date,
    data = results,
    FUN = function(x) {
      switch(
        by,
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
