#' Define Flight Query Range
#'
#' @description
#' Creates flight queries for multiple origin airports/cities across a date range.
#' This helper function generates all permutations of origins and dates
#' without actually fetching data. Each origin gets its own query object.
#' Similar to fa_define_query but for date ranges.
#'
#' Supports airport codes (e.g., "JFK", "LGA"), city codes (e.g., "NYC" for
#' all New York City airports), and full city names (e.g., "New York").
#' Full city names are automatically converted to all associated airport codes
#' (excluding heliports). You can mix formats in the same vector.
#'
#' @param origin Character vector of airport codes, city codes, or full city names
#'   to search from. Can mix formats (e.g., c("JFK", "NYC", "New York")). 
#'   Automatically expands city names to all associated airports (excluding heliports)
#'   and removes duplicates.
#' @param dest Character or destination airport code, city code, or full city name.
#'   If a city name expands to multiple airports, only the first airport is used.
#'   Currently only single destination is supported.
#' @param date_min Character or Date. Start date in "YYYY-MM-DD" format.
#' @param date_max Character or Date. End date in "YYYY-MM-DD" format.
#'
#' @return If single origin: A flight query object containing all dates.
#'   If multiple origins: A named list of flight query objects, one per origin.
#'
#' @export
#'
#' @examples
#' # Airport codes
#' fa_define_query_range(
#'   origin = c("BOM", "DEL"),
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2025-12-20"
#' )
#'
#' # City codes
#' fa_define_query_range(
#'   origin = "NYC",
#'   dest = "LON",
#'   date_min = "2025-12-18",
#'   date_max = "2025-12-20"
#' )
#'
#' # Full city names (auto-converted to airport codes)
#' fa_define_query_range(
#'   origin = "New York",
#'   dest = "Istanbul",
#'   date_min = "2025-12-18",
#'   date_max = "2025-12-20"
#' )
#'
#' # Mix formats - codes and city names
#' fa_define_query_range(
#'   origin = c("New York", "JFK", "BOM", "Patna"),
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2025-12-20"
#' )
fa_define_query_range <- function(origin, dest, date_min, date_max) {
  # Validate inputs
  if (is.null(origin) || length(origin) == 0) {
    stop("origin must be specified")
  }

  if (is.null(dest) || length(dest) == 0) {
    stop("dest must be specified")
  }

  # Normalize origin (convert city names to codes, expand to all airports)
  # Use expand_cities=TRUE to get individual airports instead of metropolitan codes
  origin <- normalize_location_codes(origin, expand_cities = TRUE)

  # Normalize dest (convert city names to codes)
  # For destinations, expand to individual airports too so we can pick the first one
  dest <- normalize_location_codes(dest, expand_cities = TRUE)
  
  # For now, only support single destination (as per the original design)
  # If a city name was provided and expanded to multiple airports, use only the first one
  if (length(dest) > 1) {
    message(sprintf(
      "Destination '%s' has multiple airports. Using the first one: %s",
      paste(dest, collapse = ", "),
      dest[1]
    ))
    dest <- dest[1]
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
