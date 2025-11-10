#' Extract Best Dates from Flight Search Results
#'
#' @description
#' Identifies and returns the top N dates with the cheapest average prices
#' across all routes. This helps quickly identify the best travel dates
#' when planning a flexible trip.
#'
#' @param results Either:
#'   - A data frame with columns: Date and Price
#'   - A list of Scrape objects (from fa_create_date_range_scrape with multiple origins)
#'   - A single Scrape object (from fa_create_date_range_scrape with single origin)
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
#' # Option 1: Pass list of Scrape objects directly
#' scrapes <- fa_create_date_range_scrape(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
#' for (code in names(scrapes)) {
#'   scrapes[[code]] <- ScrapeObjects(scrapes[[code]])
#' }
#' best_dates <- fa_best_dates(scrapes, n = 5, by = "mean")
#' 
#' # Option 2: Pass processed data frame
#' best_dates <- fa_best_dates(my_data_frame, n = 5, by = "mean")
#' }
fa_best_dates <- function(results, n = 10, by = "mean") {
  # Handle different input types
  if (is.list(results) && !is.data.frame(results)) {
    # Check if it's a list of Scrape objects
    if (all(sapply(results, function(x) inherits(x, "Scrape")))) {
      # Extract and combine data from list of Scrape objects
      results <- extract_data_from_scrapes(results)
    } else {
      stop("results must be a data frame, a Scrape object, or a list of Scrape objects")
    }
  } else if (inherits(results, "Scrape")) {
    # Single Scrape object
    results <- extract_data_from_scrapes(list(results))
  } else if (!is.data.frame(results)) {
    stop("results must be a data frame, a Scrape object, or a list of Scrape objects")
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
