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
