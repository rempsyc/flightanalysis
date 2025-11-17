#' Define Flight Query Range
#'
#' @description
#' Creates flight queries for multiple origin airports/cities across a date range.
#' This helper function generates all permutations of origins and dates
#' without actually fetching data. Each origin gets its own query object.
#' Similar to fa_define_query but for date ranges.
#'
#' Supports both airport codes (e.g., "JFK", "LGA") and city codes (e.g., "NYC" for
#' all New York City airports). City codes allow searching across multiple airports
#' in a metropolitan area, similar to Google Flights.
#'
#' @param origin Character vector of 3-letter airport codes to search from.
#'   Use NULL if specifying origin_city instead.
#' @param dest Character. 3-letter destination airport code.
#'   Use NULL if specifying dest_city instead.
#' @param date_min Character or Date. Start date in "YYYY-MM-DD" format.
#' @param date_max Character or Date. End date in "YYYY-MM-DD" format.
#' @param origin_city Character vector of 3-letter city/metropolitan codes to search from.
#'   Examples: "NYC" (New York area), "LON" (London area), "PAR" (Paris area).
#'   Use NULL if specifying origin instead. Default is NULL.
#' @param dest_city Character. 3-letter destination city/metropolitan code.
#'   Use NULL if specifying dest instead. Default is NULL.
#'
#' @return If single origin/origin_city: A flight query object containing all dates.
#'   If multiple origins/origin_cities: A named list of flight query objects, one per origin.
#'
#' @export
#'
#' @examples
#' # Single airport origin - returns one query object
#' fa_define_query_range(
#'   origin = "BOM",
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2025-12-20"
#' )
#'
#' # Multiple airport origins - returns named list of query objects
#' fa_define_query_range(
#'   origin = c("BOM", "DEL"),
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2025-12-20"
#' )
#'
#' # City-level search - searches all airports in New York City area
#' fa_define_query_range(
#'   origin = "BOM",
#'   dest_city = "NYC",
#'   date_min = "2025-12-18",
#'   date_max = "2025-12-20"
#' )
#'
#' # Multiple city origins to city destination
#' fa_define_query_range(
#'   origin_city = c("NYC", "BOS"),
#'   dest_city = "LON",
#'   date_min = "2025-12-18",
#'   date_max = "2025-12-20"
#' )
fa_define_query_range <- function(origin = NULL, dest = NULL, date_min, date_max,
                                  origin_city = NULL, dest_city = NULL) {
  # Validate inputs - must specify either origin or origin_city (not both)
  if (is.null(origin) && is.null(origin_city)) {
    stop("Must specify either 'origin' or 'origin_city'")
  }
  
  if (!is.null(origin) && !is.null(origin_city)) {
    stop("Cannot specify both 'origin' and 'origin_city'. Use one or the other.")
  }
  
  # Must specify either dest or dest_city (not both)
  if (is.null(dest) && is.null(dest_city)) {
    stop("Must specify either 'dest' or 'dest_city'")
  }
  
  if (!is.null(dest) && !is.null(dest_city)) {
    stop("Cannot specify both 'dest' and 'dest_city'. Use one or the other.")
  }
  
  # Use whichever was specified
  if (!is.null(origin_city)) {
    origin <- origin_city
  }
  
  if (!is.null(dest_city)) {
    dest <- dest_city
  }
  
  # Validate origin
  if (!is.character(origin) || length(origin) == 0) {
    stop("origin/origin_city must be a non-empty character vector")
  }

  if (any(nchar(origin) != 3)) {
    stop("All airport/city codes must be 3 characters")
  }

  # Validate dest
  if (!is.character(dest) || length(dest) != 1 || nchar(dest) != 3) {
    stop("dest/dest_city must be a single 3-character string")
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
