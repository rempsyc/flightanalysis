#' Create Date Range Queries
#'
#' @description
#' Creates flight queries for multiple origin airports across a date range.
#' This helper function generates all permutations of origins and dates
#' without actually fetching data. Each origin gets its own query object.
#'
#' @param origin Character vector of 3-letter airport codes to search from.
#' @param dest Character. 3-letter destination airport code.
#' @param date_min Character or Date. Start date in "YYYY-MM-DD" format.
#' @param date_max Character or Date. End date in "YYYY-MM-DD" format.
#'
#' @return If single origin: A flight query object containing all dates.
#'   If multiple origins: A named list of flight query objects, one per origin.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Single origin - returns one query object
#' query <- fa_create_date_range(
#'   origin = "BOM",
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2026-01-05"
#' )
#' result <- fa_fetch_flights(query)
#'
#' # Multiple origins - returns list of query objects
#' queries <- fa_create_date_range(
#'   origin = c("BOM", "DEL", "VNS"),
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2026-01-05"
#' )
#'
#' # Fetch data for each origin
#' results <- list()
#' for (i in seq_along(queries)) {
#'   results[[i]] <- fa_fetch_flights(queries[[i]])
#' }
#'
#' # Combine all results
#' all_data <- do.call(rbind, lapply(results, function(x) x$data))
#' }
fa_create_date_range <- function(origin, dest, date_min, date_max) {
  # Validate inputs
  if (!is.character(origin) || length(origin) == 0) {
    stop("origin must be a non-empty character vector")
  }

  if (any(nchar(origin) != 3)) {
    stop("All airport codes must be 3 characters")
  }

  if (!is.character(dest) || length(dest) != 1 || nchar(dest) != 3) {
    stop("dest must be a single 3-character string")
  }

  # Convert dates to Date objects if needed
  if (is.character(date_min)) {
    date_min <- as.Date(date_min)
  }
  if (is.character(date_max)) {
    date_max <- as.Date(date_max)
  }

  if (!inherits(date_min, "Date") || !inherits(date_max, "Date")) {
    stop(
      "date_min and date_max must be Date objects or character strings in YYYY-MM-DD format"
    )
  }

  if (date_min > date_max) {
    stop("date_min must be before or equal to date_max")
  }

  # Generate date sequence
  dates <- seq(date_min, date_max, by = "day")
  dates_char <- format(dates, "%Y-%m-%d")

  # If single origin, create one query object
  if (length(origin) == 1) {
    # Build chain-trip arguments: origin, dest, date1, origin, dest, date2, ...
    args <- list()
    for (date in dates_char) {
      args <- c(args, list(origin, dest, date))
    }

    query <- do.call(fa_define_query, args)
    return(query)
  }

  # If multiple origins, create separate query object for each origin
  query_list <- list()

  for (orig in origin) {
    # Build chain-trip arguments for this origin
    args <- list()
    for (date in dates_char) {
      args <- c(args, list(orig, dest, date))
    }

    query_list[[orig]] <- do.call(fa_define_query, args)
  }

  return(query_list)
}
