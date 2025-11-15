#' Create Date Range Queries (Deprecated)
#'
#' @description
#' **Deprecated:** Use [fa_define_query_range()] instead.
#' 
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
#' # Use fa_define_query_range() instead
#' query <- fa_define_query_range(
#'   origin = "BOM",
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2026-01-05"
#' )
#' }
fa_create_date_range <- function(origin, dest, date_min, date_max) {
  .Deprecated("fa_define_query_range")
  # Call the new function
  fa_define_query_range(origin, dest, date_min, date_max)
}
