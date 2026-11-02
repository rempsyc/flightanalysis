#' Define Flight Query
#'
#' @description
#' Defines a flight query for Google Flights. Supports one-way,
#' round-trip, chain-trip, and perfect-chain trip types.
#'
#' Accepts airport codes (e.g., "JFK", "LGA"), city codes (e.g., "NYC" for
#' all New York City airports), and full city names (e.g., "New York").
#' Full city names are automatically converted to their first associated airport code.
#' Common city codes include: "NYC" (New York), "LON" (London), "PAR" (Paris), 
#' "TYO" (Tokyo), "BUE" (Buenos Aires), etc.
#'
#' @param ... Arguments defining the trip. Locations can be 3-letter codes or full
#'   city names. Format depends on trip type:
#'   - One-way: origin, dest, date
#'   - Round-trip: origin, dest, date_leave, date_return
#'   - Chain-trip: org1, dest1, date1, org2, dest2, date2, ...
#'   - Perfect-chain: org1, date1, org2, date2, ..., final_dest
#'   Dates accept Date objects or strings in YYYY-MM-DD format. Query creation
#'   validates calendar dates; fa_fetch_flights() checks the current search
#'   window (today through 330 days ahead) before accessing Google Flights.
#'
#' @return A flight query object (S3 class "flight_query")
#' @export
#'
#' @examples
#' # One-way trip with airport codes
#' fa_define_query("JFK", "BOS", Sys.Date() + 32)
#'
#' # One-way trip with city codes
#' fa_define_query("NYC", "LON", Sys.Date() + 32)
#'
#' # One-way trip with full city names (auto-converted)
#' fa_define_query("New York", "Istanbul", Sys.Date() + 32)
#'
#' # Round-trip with mixed formats
#' fa_define_query("JFK", "Paris", Sys.Date() + 32, Sys.Date() + 39)
#'
#' # Chain-trip
#' fa_define_query("JFK", "YYZ", Sys.Date() + 32, "RDU", "LGA", Sys.Date() + 39)
fa_define_query <- function(...) {
  args <- list(...)

  # Pre-process arguments to normalize any city names to codes
  args <- normalize_query_args(args)

  # Initialize query object
  query <- list(
    origin = NULL,
    dest = NULL,
    date = NULL,
    data = data.frame(),
    url = NULL,
    type = NULL
  )

  # Set properties based on arguments
  query <- set_properties(query, args)

  class(query) <- "flight_query"
  return(query)
}

#' Normalize Query Arguments
#'
#' @description
#' Pre-processes query arguments to convert city names to airport codes.
#' Only processes string arguments that are not dates.
#'
#' @param args List of query arguments
#' @return List of normalized arguments
#' @keywords internal
normalize_query_args <- function(args) {
  n <- length(args)
  date_indices <- if (n == 3L) 3L else if (n == 4L) 3:4 else integer()
  
  for (i in seq_along(args)) {
    arg <- args[[i]]
    if (inherits(arg, "Date")) {
      arg <- as.character(arg)
      args[[i]] <- arg
    }
    if (!is.character(arg) || length(arg) != 1L || is.na(arg)) {
      stop("Each location or date must be a single non-missing character string or Date.",
           call. = FALSE)
    }
    
    # Only process character arguments
    if (is.character(arg)) {
      # Check if it's a date (10 characters in YYYY-MM-DD format)
      if (i %in% date_indices || grepl("^[0-9]{4}[-/]", arg)) {
        # It's a date, skip
        next
      }
      
      # If it's not a 3-character code, try to convert it
      if (nchar(arg) != 3) {
        # Check if there's a metropolitan code for this city
        metro_code <- get_metropolitan_code(arg)
        
        if (!is.null(metro_code)) {
          # Use the metropolitan area code (no message needed)
          args[[i]] <- metro_code
        } else {
          # Try to convert city name to airport codes (expand to individual airports)
          codes <- normalize_location_codes(arg, expand_cities = TRUE)
          
          # Show message if multiple airports found
          if (length(codes) > 1) {
            message(sprintf(
              "Location '%s' has multiple airports: %s. Using the first one: %s",
              arg,
              paste(codes, collapse = ", "),
              codes[1]
            ))
          }
          
          # Use the first code for single-location queries
          args[[i]] <- codes[1]
        }
      }
    }
  }
  
  return(args)
}

#' Set Query Properties
#'
#' @param query Query object being constructed
#' @param args List of arguments
#' @keywords internal
set_properties <- function(query, args) {
  n_args <- length(args)
  date_format <- "%Y-%m-%d"

  validate_date <- function(date_str, arg_name = "Date") {
    parse_flight_dates(date_str, arg_name)
  }
  # One-way trip (3 arguments)
  if (n_args == 3) {
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("Origin must be 3-character string (airport or city code)")
    }
    if (!(nchar(args[[2]]) == 3 && is.character(args[[2]]))) {
      stop("Destination must be 3-character string (airport or city code)")
    }
    validate_date(args[[3]], "Date")

    query$origin <- list(args[[1]])
    query$dest <- list(args[[2]])
    query$date <- list(args[[3]])
    query$url <- make_url(query$origin, query$dest, query$date)
    query$type <- "one-way"
  } else if (n_args == 4) {
    # Round-trip (4 arguments)
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("Origin must be 3-character string (airport or city code)")
    }
    if (!(nchar(args[[2]]) == 3 && is.character(args[[2]]))) {
      stop("Destination must be 3-character string (airport or city code)")
    }
    date1 <- validate_date(args[[3]], "Date leave")
    date2 <- validate_date(args[[4]], "Date return")

    if (!(date1 < date2)) {
      stop("Dates must be in increasing order")
    }

    query$origin <- list(args[[1]], args[[2]])
    query$dest <- list(args[[2]], args[[1]])
    query$date <- list(args[[3]], args[[4]])
    query$url <- make_url(query$origin, query$dest, query$date)
    query$type <- "round-trip"
  } else if (
    n_args >= 3 &&
      n_args %% 3 == 0 &&
      nchar(args[[n_args]]) == 10 &&
      is.character(args[[n_args]])
  ) {
    # Chain-trip (multiples of 3, last element is a date)
    query$origin <- list()
    query$dest <- list()
    query$date <- list()

    for (i in seq(1, n_args, by = 3)) {
      if (!(nchar(args[[i]]) == 3 && is.character(args[[i]]))) {
        stop(sprintf("Argument %d must be 3-character string (airport or city code)", i))
      }
      if (!(nchar(args[[i + 1]]) == 3 && is.character(args[[i + 1]]))) {
        stop(sprintf("Argument %d must be 3-character string (airport or city code)", i + 1))
      }
      curr_date <- validate_date(
        args[[i + 2]],
        sprintf("Argument %d (date)", i + 2)
      )

      if (length(query$date) > 0) {
        prev_date <- as.Date(query$date[[length(query$date)]], date_format)
        if (!(prev_date < curr_date)) {
          stop("Dates must be in increasing order")
        }
      }

      query$origin <- c(query$origin, args[[i]])
      query$dest <- c(query$dest, args[[i + 1]])
      query$date <- c(query$date, args[[i + 2]])
    }

    query$url <- make_url(query$origin, query$dest, query$date)
    query$type <- "chain-trip"
  } else if (
    n_args >= 5 &&
      n_args %% 2 == 1 &&
      nchar(args[[n_args]]) == 3 &&
      is.character(args[[n_args]])
  ) {
    # Perfect-chain (odd number >= 5, last element is 3-character string)
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("First argument must be 3-character string (airport or city code)")
    }
    validate_date(args[[2]], "Second argument (date)")

    query$origin <- list(args[[1]])
    query$dest <- list()
    query$date <- list(args[[2]])

    for (i in seq(3, n_args - 1, by = 2)) {
      if (!(nchar(args[[i]]) == 3 && is.character(args[[i]]))) {
        stop(sprintf("Argument %d must be 3-character string (airport or city code)", i))
      }
      curr_date <- validate_date(
        args[[i + 1]],
        sprintf("Argument %d (date)", i + 1)
      )

      prev_date <- as.Date(query$date[[length(query$date)]], date_format)
      if (!(prev_date < curr_date)) {
        stop("Dates must be in increasing order")
      }

      query$origin <- c(query$origin, args[[i]])
      query$dest <- c(query$dest, args[[i]])
      query$date <- c(query$date, args[[i + 1]])
    }

    if (!(nchar(args[[n_args]]) == 3 && is.character(args[[n_args]]))) {
      stop("Last argument must be 3-character string (airport or city code)")
    }
    query$dest <- c(query$dest, args[[n_args]])

    query$url <- make_url(query$origin, query$dest, query$date)
    query$type <- "perfect-chain"
  } else {
    stop("Invalid arguments. See documentation for proper formats.")
  }

  return(query)
}

#' Make URL for Google Flights Query
#'
#' @param origins List of origin airports
#' @param dests List of destination airports
#' @param dates List of dates
#' @keywords internal
make_url <- function(origins, dests, dates) {
  urls <- list()
  for (i in seq_along(dates)) {
    url <- sprintf(
      "https://www.google.com/travel/flights?hl=en&q=Flights%%20to%%20%s%%20from%%20%s%%20on%%20%s%%20oneway",
      dests[[i]],
      origins[[i]],
      dates[[i]]
    )
    urls <- c(urls, url)
  }
  return(urls)
}

#' Print method for flight query objects
#' @param x A flight query object
#' @param ... Additional arguments (ignored)
#' @export
print.flight_query <- function(x, ...) {
  cat("Flight Query( ")

  if (nrow(x$data) == 0) {
    cat("{Not Yet Fetched}\n")
  } else {
    cat(sprintf("{%d} RESULTS FOR:\n", nrow(x$data)))
  }

  for (i in seq_along(x$date)) {
    cat(sprintf("%s: %s --> %s\n", x$date[[i]], x$origin[[i]], x$dest[[i]]))
  }

  cat(")")
  invisible(x)
}
