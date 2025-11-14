#' Clean Flight Data by Removing Invalid Entries
#'
#' @description
#' Removes invalid and placeholder rows from flight data, such as "Price graph",
#' "Price unavailable", empty entries, and rows with missing prices.
#' This is a data cleaning function used internally.
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

#' Extract and Process Data from Query Objects
#'
#' @description
#' Internal helper that extracts data from query objects (single or list),
#' filters placeholder rows, and formats for use with fa_summarize_prices and fa_find_best_dates.
#'
#' @param scrapes A single query object or a named list of query objects
#'
#' @return A data frame with columns: Airport, Date, Price, and City (if named list)
#'
#' @keywords internal
extract_data_from_scrapes <- function(scrapes) {
  # Ensure we have a list
  if (inherits(scrapes, "flight_query")) {
    # For single query object, try to extract origin from the data
    # This ensures we have a named list for proper City assignment
    if (
      !is.null(scrapes$data) &&
        nrow(scrapes$data) > 0 &&
        "origin" %in% names(scrapes$data)
    ) {
      origin_code <- scrapes$data$origin[1]
      scrapes <- list(scrapes)
      names(scrapes) <- origin_code
    } else {
      scrapes <- list(scrapes)
    }
  }

  all_data <- list()

  for (i in seq_along(scrapes)) {
    scrape <- scrapes[[i]]

    # Extract data
    if (is.null(scrape$data) || nrow(scrape$data) == 0) {
      next
    }

    data <- scrape$data

    # Filter placeholder rows
    data <- filter_placeholder_rows(data)

    if (nrow(data) == 0) {
      next
    }

    # Extract relevant columns
    # Use origin as the Airport (the airport we're searching FROM)
    if ("origin" %in% names(data)) {
      data$Airport <- data$origin
    } else if ("destination" %in% names(data)) {
      data$Airport <- data$destination
    } else {
      data$Airport <- NA_character_
    }

    if ("departure_datetime" %in% names(data)) {
      data$Date <- as.character(as.Date(data$departure_datetime))
    } else {
      data$Date <- NA_character_
    }

    if ("price" %in% names(data)) {
      data$Price <- data$price
    } else {
      data$Price <- NA_real_
    }

    # Add City from list name if available, or try to look up from airport code
    if (!is.null(names(scrapes)[i])) {
      data$City <- names(scrapes)[i]
    } else {
      data$City <- data$Airport
    }

    # Try to convert airport codes to city names using airportr if available
    data$City <- airport_to_city(data$Airport, data$City)

    # Select only needed columns
    data <- data[, c("City", "Airport", "Date", "Price"), drop = FALSE]

    all_data[[i]] <- data
  }

  if (length(all_data) == 0) {
    return(data.frame(
      City = character(),
      Airport = character(),
      Date = character(),
      Price = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  # Combine all data
  combined <- do.call(rbind, all_data)
  rownames(combined) <- NULL

  return(combined)
}

#' Convert Airport Codes to City Names
#'
#' @description
#' Attempts to convert IATA airport codes to city names using the airportr package.
#' Falls back to the provided fallback value if conversion fails or package is not available.
#'
#' @param airport_codes Character vector of IATA airport codes
#' @param fallback Character vector of fallback values (same length as airport_codes)
#'
#' @return Character vector of city names
#'
#' @keywords internal
airport_to_city <- function(airport_codes, fallback = airport_codes) {
  result <- tryCatch({
    ap <- airportr::airports
    key <- ap$IATA
    val <- ap$City
    out <- val[match(airport_codes, key)]
    ifelse(is.na(out) | out == "", fallback, out)
  }, error = function(e) {
    fallback
  })
  return(result)
}
