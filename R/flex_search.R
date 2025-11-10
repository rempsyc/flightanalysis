#' Create Flexible Date Range Scrape Object
#'
#' @description
#' Creates a chain-trip Scrape object for multiple airports and date range.
#' This is a helper function that generates all permutations of airports and dates
#' without actually scraping. The resulting Scrape object can be passed to
#' ScrapeObjects() to perform the actual scraping in a single batch request.
#'
#' @param airports Character vector of 3-letter airport codes to search from.
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
#' # Create Scrape object for multiple airports over date range
#' scrape <- fa_create_date_range_scrape(
#'   airports = c("BOM", "DEL", "VNS"),
#'   dest = "JFK",
#'   date_min = "2025-12-18",
#'   date_max = "2026-01-05"
#' )
#'
#' # Then scrape using existing ScrapeObjects function
#' scrape <- ScrapeObjects(scrape, verbose = TRUE)
#' print(scrape$data)
#' }
fa_create_date_range_scrape <- function(airports, dest, date_min, date_max) {
  # Validate inputs
  if (!is.character(airports) || length(airports) == 0) {
    stop("airports must be a non-empty character vector")
  }

  if (any(nchar(airports) != 3)) {
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

  # Generate all combinations (airports × dates)
  combinations <- expand.grid(
    airport = airports,
    date = dates_char,
    stringsAsFactors = FALSE
  )

  # Sort by date first, then airport for logical ordering
  combinations <- combinations[order(combinations$date, combinations$airport), ]

  # Build chain-trip arguments: origin1, dest1, date1, origin2, dest2, date2, ...
  args <- list()
  for (i in seq_len(nrow(combinations))) {
    args <- c(args, list(
      as.character(combinations$airport[i]),
      dest,
      combinations$date[i]
    ))
  }

  # Create Scrape object using do.call
  scrape <- do.call(Scrape, args)

  return(scrape)
}

#' Scrape Best One-Way Flights Across Multiple Dates and Routes
#'
#' @description
#' Scrapes Google Flights for flights across multiple origin-destination pairs
#' and a range of dates. This function creates a chain-trip Scrape object with
#' all permutations and then uses ScrapeObjects() to scrape them in a single
#' batch request, reducing browser initialization overhead.
#'
#' After scraping, you can filter the results using keep_offers parameter.
#'
#' @param routes A data frame with columns: City, Airport, Dest, and optionally Comment.
#'   Each row represents an origin airport to search from.
#' @param dates A vector of dates (Date objects or character strings in "YYYY-MM-DD" format)
#'   to search across.
#' @param keep_offers Logical. If TRUE, stores all flight offers in a list-column.
#'   If FALSE (default), only keeps the cheapest offer per day. Default is FALSE.
#' @param headless Logical. If TRUE, runs browser in headless mode (no GUI, default).
#' @param verbose Logical. If TRUE, shows detailed progress information (default).
#'
#' @return A data frame with columns: City, Airport, Dest, Date, Price, and
#'   optionally Comment and Offers (if keep_offers=TRUE). Each row represents
#'   the cheapest flight (or all offers) for a given route and date combination.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(tibble)
#' routes <- tribble(
#'   ~City,      ~Airport, ~Dest, ~Comment,
#'   "Mumbai",   "BOM",    "JFK", "Original flight",
#'   "Delhi",    "DEL",    "JFK", "",
#'   "Varanasi", "VNS",    "JFK", ""
#' )
#' dates <- seq(as.Date("2025-12-18"), as.Date("2026-01-05"), by = "day")
#'
#' # Scrape all routes and dates
#' results <- fa_scrape_best_oneway(routes, dates, verbose = TRUE)
#'
#' # Or keep all offers for detailed analysis
#' results_full <- fa_scrape_best_oneway(routes, dates, keep_offers = TRUE)
#' }
fa_scrape_best_oneway <- function(
  routes,
  dates,
  keep_offers = FALSE,
  headless = TRUE,
  verbose = TRUE
) {
  # Validate inputs
  if (!is.data.frame(routes)) {
    stop("routes must be a data frame")
  }

  required_cols <- c("City", "Airport", "Dest")
  if (!all(required_cols %in% names(routes))) {
    stop(sprintf(
      "routes must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }

  # Check that all routes have the same destination
  if (length(unique(routes$Dest)) > 1) {
    stop("All routes must have the same destination. Use fa_create_date_range_scrape() for custom combinations.")
  }

  dest <- routes$Dest[1]

  # Convert dates to Date objects if they're character strings
  if (is.character(dates)) {
    dates <- as.Date(dates)
  }

  if (verbose) {
    cat(sprintf(
      "Creating Scrape object for %d routes across %d dates (%d total queries)...\n",
      nrow(routes),
      length(dates),
      nrow(routes) * length(dates)
    ))
  }

  # Create Scrape object using the helper function
  scrape <- fa_create_date_range_scrape(
    airports = routes$Airport,
    dest = dest,
    date_min = min(dates),
    date_max = max(dates)
  )

  if (verbose) {
    cat("Scraping flights using ScrapeObjects()...\n")
  }

  # Use existing ScrapeObjects function to scrape
  scrape <- ScrapeObjects(scrape, headless = headless, verbose = verbose)

  # Filter out placeholder rows
  if (nrow(scrape$data) > 0) {
    scrape$data <- filter_placeholder_rows(scrape$data)
  }

  if (nrow(scrape$data) == 0) {
    warning("No valid flight data retrieved")
    return(data.frame(
      City = character(),
      Airport = character(),
      Dest = character(),
      Date = character(),
      Price = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  # Process results to match expected format
  results <- process_scrape_results(
    scrape_data = scrape$data,
    routes = routes,
    keep_offers = keep_offers,
    verbose = verbose
  )

  return(results)
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

#' Process Scrape Results into Summary Format
#'
#' @description
#' Processes the raw scraped data into the desired summary format,
#' optionally keeping all offers or just the cheapest per route-date.
#'
#' @param scrape_data Data frame from scrape$data
#' @param routes Original routes data frame
#' @param keep_offers Logical, whether to keep all offers
#' @param verbose Logical, show progress
#'
#' @return Processed data frame
#'
#' @keywords internal
process_scrape_results <- function(scrape_data, routes, keep_offers, verbose) {
  # Extract date from departure_datetime
  scrape_data$Date <- as.character(as.Date(scrape_data$departure_datetime))

  # The origin and destination columns in scrape_data are swapped
  # (Google Flights returns destination as origin for our queries)
  # So we need to map based on destination field
  scrape_data$Airport <- scrape_data$destination
  scrape_data$Dest <- scrape_data$origin

  # Create results list
  results_list <- list()

  # Group by Airport and Date
  unique_combinations <- unique(scrape_data[, c("Airport", "Date")])

  for (i in seq_len(nrow(unique_combinations))) {
    airport <- unique_combinations$Airport[i]
    date <- unique_combinations$Date[i]

    # Get all flights for this combination
    flights <- scrape_data[
      scrape_data$Airport == airport & scrape_data$Date == date,
    ]

    if (nrow(flights) == 0) next

    # Get city and dest from routes
    route_info <- routes[routes$Airport == airport, ]
    if (nrow(route_info) == 0) {
      city <- airport
      dest <- flights$Dest[1]
    } else {
      city <- route_info$City[1]
      dest <- route_info$Dest[1]
    }

    if (keep_offers) {
      # Store all offers
      results_list[[length(results_list) + 1]] <- data.frame(
        City = city,
        Airport = airport,
        Dest = dest,
        Date = date,
        Price = min(flights$price, na.rm = TRUE),
        Offers = I(list(flights)),
        stringsAsFactors = FALSE
      )
    } else {
      # Only keep cheapest
      min_price_idx <- which.min(flights$price)
      results_list[[length(results_list) + 1]] <- data.frame(
        City = city,
        Airport = airport,
        Dest = dest,
        Date = date,
        Price = flights$price[min_price_idx],
        stringsAsFactors = FALSE
      )
    }
  }

  # Combine results
  if (length(results_list) == 0) {
    return(data.frame(
      City = character(),
      Airport = character(),
      Dest = character(),
      Date = character(),
      Price = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  results <- do.call(rbind, results_list)

  # Add Comment column if it exists in routes
  if ("Comment" %in% names(routes)) {
    results$Comment <- routes$Comment[match(
      results$Airport,
      routes$Airport
    )]
  }

  if (verbose) {
    cat(sprintf("[OK] Processed %d route-date combinations\n", nrow(results)))
  }

  return(results)
}

#' Create Flexible Date Summary Table
#'
#' @description
#' Creates a wide summary table showing prices by city/airport and date,
#' with an average price column. This is useful for visualizing price
#' patterns across multiple dates and comparing different origin airports.
#'
#' @param results A data frame returned by fa_scrape_best_oneway()
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
#' # After running fa_scrape_best_oneway()
#' results <- fa_scrape_best_oneway(routes, dates)
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
#' @param results A data frame returned by fa_scrape_best_oneway()
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
#' # After running fa_scrape_best_oneway()
#' results <- fa_scrape_best_oneway(routes, dates)
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
