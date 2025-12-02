#' Define Flight Query Range
#'
#' @description
#' Creates flight queries for multiple origin and/or destination airports/cities 
#' across a date range. This helper function generates all permutations of 
#' origins, destinations, and dates without actually fetching data. Each 
#' origin-destination pair gets its own query object.
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
#' @param dest Character vector of airport codes, city codes, or full city names
#'   to search to. Can mix formats. Multiple destinations are supported;
#'   separate query objects will be created for each origin-destination pair.
#' @param date_min Character or Date. Start date in "YYYY-MM-DD" format.
#' @param date_max Character or Date. End date in "YYYY-MM-DD" format.
#'
#' @return If single origin and destination: A flight query object containing all dates.
#'   If multiple origins and/or destinations: A named list of flight query objects, 
#'   one per origin-destination pair (named as "ORIGIN-DEST").
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
#'
#' # Multiple destinations
#' fa_define_query_range(
#'   origin = "BOM",
#'   dest = c("JFK", "LON"),
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

  # Normalize origin (convert city names to metropolitan codes when available)
  # Use expand_cities=FALSE to prefer metropolitan codes (e.g., "New York" -> "NYC")
  # Google Flights supports these codes and will search all airports in the area
  origin <- normalize_location_codes(origin, expand_cities = FALSE)

  # Normalize dest (convert city names to codes)
  # Also prefer metropolitan codes for destinations
  dest <- normalize_location_codes(dest, expand_cities = FALSE)

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

  # If single origin AND single destination, create one query object
  if (length(origin) == 1 && length(dest) == 1) {
    # Build chain-trip arguments: origin, dest, date1, origin, dest, date2, ...
    args <- list()
    for (date in dates_char) {
      args <- c(args, list(origin, dest, date))
    }

    query <- do.call(fa_define_query, args)
    return(query)
  }

  # If multiple origins and/or destinations, create separate query object for each pair
  query_list <- list()

  for (orig in origin) {
    for (d in dest) {
      # Build chain-trip arguments for this origin-destination pair
      args <- list()
      for (date in dates_char) {
        args <- c(args, list(orig, d, date))
      }

      # Name the query as "ORIGIN-DEST" for multiple origins/destinations
      # or just "ORIGIN" for multiple origins with single destination (backwards compat)
      if (length(dest) == 1) {
        query_name <- orig
      } else if (length(origin) == 1) {
        query_name <- d
      } else {
        query_name <- paste(orig, d, sep = "-")
      }

      query_list[[query_name]] <- do.call(fa_define_query, args)
    }
  }

  return(query_list)
}
