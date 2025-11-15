#' Define Flight Query
#'
#' @description
#' Defines a flight query for Google Flights. Supports one-way,
#' round-trip, chain-trip, and perfect-chain trip types.
#'
#' @param ... Arguments defining the trip. Format depends on trip type:
#'   - One-way: origin, dest, date
#'   - Round-trip: origin, dest, date_leave, date_return
#'   - Chain-trip: org1, dest1, date1, org2, dest2, date2, ...
#'   - Perfect-chain: org1, date1, org2, date2, ..., final_dest
#'
#' @return A flight query object (S3 class "flight_query")
#' @export
#'
#' @examples
#' # One-way trip
#' fa_define_query("JFK", "BOS", "2025-12-20")
#'
#' # Round-trip
#' fa_define_query("JFK", "YUL", "2025-12-20", "2025-12-25")
#'
#' # Chain-trip
#' fa_define_query("JFK", "YYZ", "2025-12-20", "RDU", "LGA", "2025-12-25")
fa_define_query <- function(...) {
  args <- list(...)

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

#' Set Query Properties
#'
#' @param query Query object being constructed
#' @param args List of arguments
#' @keywords internal
set_properties <- function(query, args) {
  n_args <- length(args)
  date_format <- "%Y-%m-%d"

  # Helper function to validate date format
  validate_date <- function(date_str, arg_name = "Date") {
    if (!(nchar(date_str) == 10 && is.character(date_str))) {
      stop(sprintf("%s must be in YYYY-MM-DD format", arg_name))
    }
    # Try to parse the date
    parsed_date <- tryCatch(
      {
        as.Date(date_str, date_format)
      },
      error = function(e) {
        stop(sprintf(
          "%s '%s' is not a valid date in YYYY-MM-DD format",
          arg_name,
          date_str
        ))
      }
    )
    # Check if parsed successfully
    if (is.na(parsed_date)) {
      stop(sprintf(
        "%s '%s' is not a valid date in YYYY-MM-DD format",
        arg_name,
        date_str
      ))
    }
    return(parsed_date)
  }

  # One-way trip (3 arguments)
  if (n_args == 3) {
    if (!(nchar(args[[1]]) == 3 && is.character(args[[1]]))) {
      stop("Origin must be 3-character string")
    }
    if (!(nchar(args[[2]]) == 3 && is.character(args[[2]]))) {
      stop("Destination must be 3-character string")
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
      stop("Origin must be 3-character string")
    }
    if (!(nchar(args[[2]]) == 3 && is.character(args[[2]]))) {
      stop("Destination must be 3-character string")
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
        stop(sprintf("Argument %d must be 3-character string", i))
      }
      if (!(nchar(args[[i + 1]]) == 3 && is.character(args[[i + 1]]))) {
        stop(sprintf("Argument %d must be 3-character string", i + 1))
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
      stop("First argument must be 3-character string")
    }
    validate_date(args[[2]], "Second argument (date)")

    query$origin <- list(args[[1]])
    query$dest <- list()
    query$date <- list(args[[2]])

    for (i in seq(3, n_args - 1, by = 2)) {
      if (!(nchar(args[[i]]) == 3 && is.character(args[[i]]))) {
        stop(sprintf("Argument %d must be 3-character string", i))
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
      stop("Last argument must be 3-character string")
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
