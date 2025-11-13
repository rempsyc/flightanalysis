#' Create Flexible Date Range Scrape Objects
#'
#' @description
#' Creates Scrape objects for multiple origin airports and date range.
#' This is a helper function that generates all permutations of origins and dates
#' without actually scraping. Each origin gets its own chain-trip Scrape object
#' (to satisfy the chain-trip requirement that dates must be strictly increasing).
#' The resulting list of Scrape objects can be passed to scrape_objects() one at a time.
#'
#' @param origin Character vector of 3-letter airport codes to search from.
#' @param dest Character. 3-letter destination airport code.
#' @param date_min Character or Date. Start date in "YYYY-MM-DD" format.
#' @param date_max Character or Date. End date in "YYYY-MM-DD" format.
#'
#' @return If single origin: A Scrape object of type "chain-trip" containing all dates.
#'   If multiple origins: A named list of Scrape objects, one per origin.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Single origin - returns one Scrape object
#' scrape <- fa_create_date_range_scrape(
#'   origin = "BOM",
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2026-01-05"
#' )
#' scrape <- scrape_objects(scrape)
#'
#' # Multiple origins - returns list of Scrape objects
#' scrapes <- fa_create_date_range_scrape(
#'   origin = c("BOM", "DEL", "VNS"),
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2026-01-05"
#' )
#'
#' # Scrape each origin
#' results <- list()
#' for (i in seq_along(scrapes)) {
#'   scrapes[[i]] <- scrape_objects(scrapes[[i]])
#'   results[[i]] <- scrapes[[i]]$data
#' }
#' 
#' # Combine all results
#' all_data <- do.call(rbind, results)
#' }
fa_create_date_range_scrape <- function(origin, dest, date_min, date_max) {
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
    stop("date_min and date_max must be Date objects or character strings in YYYY-MM-DD format")
  }

  if (date_min > date_max) {
    stop("date_min must be before or equal to date_max")
  }

  # Generate date sequence
  dates <- seq(date_min, date_max, by = "day")
  dates_char <- format(dates, "%Y-%m-%d")

  # If single origin, create one Scrape object
  if (length(origin) == 1) {
    # Build chain-trip arguments: origin, dest, date1, origin, dest, date2, ...
    args <- list()
    for (date in dates_char) {
      args <- c(args, list(origin, dest, date))
    }
    
    scrape <- do.call(Scrape, args)
    return(scrape)
  }
  
  # If multiple origins, create separate Scrape object for each origin
  # (chain-trip validation requires strictly increasing dates, which prevents
  # multiple origins with overlapping date ranges in a single Scrape object)
  scrape_list <- list()
  
  for (orig in origin) {
    # Build chain-trip arguments for this origin
    args <- list()
    for (date in dates_char) {
      args <- c(args, list(orig, dest, date))
    }
    
    scrape_list[[orig]] <- do.call(Scrape, args)
  }
  
  return(scrape_list)
}
