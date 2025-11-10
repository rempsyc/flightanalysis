#' Create Flexible Date Range Scrape Object
#'
#' @description
#' Creates a chain-trip Scrape object for multiple origin airports and date range.
#' This is a helper function that generates all permutations of origins and dates
#' without actually scraping. The resulting Scrape object can be passed to
#' ScrapeObjects() to perform the actual scraping in a single batch request.
#'
#' @param origin Character vector of 3-letter airport codes to search from.
#' @param dest Character. 3-letter destination airport code.
#' @param date_min Character or Date. Start date in "YYYY-MM-DD" format.
#' @param date_max Character or Date. End date in "YYYY-MM-DD" format.
#'
#' @return A Scrape object of type "chain-trip" containing all route-date combinations.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create Scrape object for multiple origin airports over date range
#' scrape <- fa_create_date_range_scrape(
#'   origin = c("BOM", "DEL", "VNS"),
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2026-01-05"
#' )
#'
#' # Then scrape using existing ScrapeObjects function
#' scrape <- ScrapeObjects(scrape, verbose = TRUE)
#' print(scrape$data)
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

  # Generate all combinations (origin × dates)
  combinations <- expand.grid(
    origin = origin,
    date = dates_char,
    stringsAsFactors = FALSE
  )

  # Sort by origin first, then date to ensure dates are increasing within each origin
  combinations <- combinations[order(combinations$origin, combinations$date), ]

  # Build chain-trip arguments: origin1, dest1, date1, origin2, dest2, date2, ...
  args <- list()
  for (i in seq_len(nrow(combinations))) {
    args <- c(args, list(
      as.character(combinations$origin[i]),
      dest,
      combinations$date[i]
    ))
  }

  # Create Scrape object using do.call
  scrape <- do.call(Scrape, args)

  return(scrape)
}

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

#' Create Flexible Date Summary Table
#'
#' @description
#' Creates a wide summary table showing prices by city/airport and date,
#' with an average price column. This is useful for visualizing price
#' patterns across multiple dates and comparing different origin airports.
#'
#' @param results A data frame with columns: City, Airport, Date, Price, and
#'   optionally Comment. Typically created after scraping with fa_create_date_range_scrape()
#'   and ScrapeObjects(), then processing the results.
#' @param include_comment Logical. If TRUE and Comment column exists, includes
#'   it in the output. Default is TRUE.
#' @param currency_symbol Character. Currency symbol to use for formatting.
#'   Default is "$".
#' @param round_prices Logical. If TRUE, rounds prices to nearest integer.
#'   Default is TRUE.
#'
#' @return A wide data frame with columns: City, Airport, Comment (optional),
#'   one column per date with prices, and an Average_Price column.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create and scrape
#' scrape <- fa_create_date_range_scrape(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
#' scrape <- ScrapeObjects(scrape)
#' 
#' # Process and create summary table
#' # (Add City and Date columns to scrape$data as needed)
#' summary_table <- fa_flex_table(results)
#' print(summary_table)
#' }
fa_flex_table <- function(
  results,
  include_comment = TRUE,
  currency_symbol = "$",
  round_prices = TRUE
) {
  if (!is.data.frame(results)) {
    stop("results must be a data frame")
  }

  required_cols <- c("City", "Airport", "Date", "Price")
  if (!all(required_cols %in% names(results))) {
    stop(sprintf(
      "results must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }

  # Convert Date to character if it's not already
  if (!is.character(results$Date)) {
    results$Date <- as.character(results$Date)
  }

  # Round prices if requested
  if (round_prices) {
    results$Price <- round(results$Price)
  }

  # Reshape to wide format
  # Use stats::reshape to avoid dependency on tidyr
  results_unique <- unique(results[, c("City", "Airport", "Date", "Price")])

  # Create a unique identifier for each City-Airport combination
  results_unique$ID <- paste(results_unique$City, results_unique$Airport, sep = "_")

  # Reshape
  wide_data <- stats::reshape(
    results_unique,
    idvar = "ID",
    timevar = "Date",
    v.names = "Price",
    direction = "wide",
    sep = "_"
  )

  # Extract City and Airport from ID
  id_parts <- strsplit(wide_data$ID, "_")
  wide_data$City <- sapply(id_parts, function(x) x[1])
  wide_data$Airport <- sapply(id_parts, function(x) x[2])

  # Remove ID column
  wide_data$ID <- NULL

  # Calculate average price
  price_cols <- grep("^Price_", names(wide_data))
  wide_data$Average_Price <- rowMeans(wide_data[, price_cols], na.rm = TRUE)

  if (round_prices) {
    wide_data$Average_Price <- round(wide_data$Average_Price)
  }

  # Reorder columns: City, Airport, Comment (if applicable), dates, Average_Price
  base_cols <- c("City", "Airport")

  # Add Comment column if it exists and is requested
  if (include_comment && "Comment" %in% names(results)) {
    # Get unique comments for each City-Airport pair
    comment_map <- unique(results[, c("City", "Airport", "Comment")])
    wide_data <- merge(
      wide_data,
      comment_map,
      by = c("City", "Airport"),
      all.x = TRUE
    )
    base_cols <- c(base_cols, "Comment")
  }

  # Format date column names (remove "Price_" prefix)
  date_cols <- grep("^Price_", names(wide_data))
  date_col_names <- names(wide_data)[date_cols]
  names(wide_data)[date_cols] <- gsub("^Price_", "", date_col_names)

  # Get updated date column positions
  date_cols <- grep("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", names(wide_data))

  # Sort date columns chronologically
  date_names_sorted <- sort(names(wide_data)[date_cols])

  # Reorder all columns
  final_cols <- c(base_cols, date_names_sorted, "Average_Price")
  wide_data <- wide_data[, final_cols]

  # Format prices with currency symbol if scales is available
  if (requireNamespace("scales", quietly = TRUE)) {
    price_format_cols <- c(date_names_sorted, "Average_Price")
    for (col in price_format_cols) {
      if (col %in% names(wide_data)) {
        # Format only non-NA values
        formatted_vals <- ifelse(
          is.na(wide_data[[col]]),
          NA_character_,
          paste0(currency_symbol, format(wide_data[[col]], big.mark = ",", scientific = FALSE))
        )
        wide_data[[col]] <- formatted_vals
      }
    }
  }

  return(wide_data)
}

#' Extract Best Dates from Flight Search Results
#'
#' @description
#' Identifies and returns the top N dates with the cheapest average prices
#' across all routes. This helps quickly identify the best travel dates
#' when planning a flexible trip.
#'
#' @param results A data frame with columns: Date and Price. Typically created
#'   after scraping with fa_create_date_range_scrape() and ScrapeObjects().
#' @param n Integer. Number of best dates to return. Default is 10.
#' @param by Character. How to calculate best dates: "mean" (average price
#'   across routes), "median", or "min" (lowest price on that date).
#'   Default is "mean".
#'
#' @return A data frame with columns: Date, Price (average/median/min),
#'   and N_Routes (number of routes with data for that date).
#'   Sorted by price (cheapest first).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create and scrape
#' scrape <- fa_create_date_range_scrape(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
#' scrape <- ScrapeObjects(scrape)
#' 
#' # Extract best dates from results
#' best_dates <- fa_best_dates(results, n = 5, by = "mean")
#' print(best_dates)
#' }
fa_best_dates <- function(results, n = 10, by = "mean") {
  if (!is.data.frame(results)) {
    stop("results must be a data frame")
  }

  required_cols <- c("Date", "Price")
  if (!all(required_cols %in% names(results))) {
    stop(sprintf(
      "results must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }

  if (!by %in% c("mean", "median", "min")) {
    stop("by must be one of: 'mean', 'median', 'min'")
  }

  # Aggregate by date
  date_summary <- stats::aggregate(
    Price ~ Date,
    data = results,
    FUN = function(x) {
      switch(by,
        mean = mean(x, na.rm = TRUE),
        median = stats::median(x, na.rm = TRUE),
        min = min(x, na.rm = TRUE)
      )
    }
  )

  # Count number of routes per date
  route_counts <- stats::aggregate(
    Price ~ Date,
    data = results,
    FUN = function(x) sum(!is.na(x))
  )
  names(route_counts)[2] <- "N_Routes"

  # Combine
  date_summary <- merge(date_summary, route_counts, by = "Date")

  # Sort by price
  date_summary <- date_summary[order(date_summary$Price), ]

  # Return top n
  if (n < nrow(date_summary)) {
    date_summary <- date_summary[1:n, ]
  }

  rownames(date_summary) <- NULL

  return(date_summary)
}
