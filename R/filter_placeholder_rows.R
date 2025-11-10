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

#' Extract and Process Data from Scrape Objects
#'
#' @description
#' Internal helper that extracts data from Scrape objects (single or list),
#' filters placeholder rows, and formats for use with fa_flex_table and fa_best_dates.
#'
#' @param scrapes A single Scrape object or a named list of Scrape objects
#'
#' @return A data frame with columns: Airport, Date, Price, and City (if named list)
#'
#' @keywords internal
extract_data_from_scrapes <- function(scrapes) {
  # Ensure we have a list
  if (inherits(scrapes, "Scrape")) {
    scrapes <- list(scrapes)
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
    # The 'destination' field contains the origin airport (swapped in scraping)
    data$Airport <- data$destination
    data$Date <- as.character(as.Date(data$departure_datetime))
    data$Price <- data$price
    
    # Add City from list name if available
    if (!is.null(names(scrapes)[i])) {
      data$City <- names(scrapes)[i]
    } else {
      data$City <- data$Airport
    }
    
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
