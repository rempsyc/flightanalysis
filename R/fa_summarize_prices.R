#' Create Price Summary Table
#'
#' @description
#' Creates a wide summary table showing prices by city/airport and date,
#' with an average price column. When multiple flights exist for the same
#' date, uses the minimum (cheapest) price. This is useful for visualizing
#' price patterns across multiple dates and comparing different origin airports.
#'
#' @param results Either:
#'   - A data frame with columns: City, Airport, Date, Price, and optionally Comment
#'   - A list of flight querys (from fa_create_date_range with multiple origins)
#'   - A single flight query (from fa_create_date_range with single origin)
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
#' # Option 1: Pass list of flight querys directly
#' queries <- fa_create_date_range(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
#' for (code in names(queries)) {
#'   queries[[code]] <- fa_fetch_flights(queries[[code]])
#' }
#' summary_table <- fa_summarize_prices(queries)
#' 
#' # Option 2: Pass processed data frame
#' summary_table <- fa_summarize_prices(my_data_frame)
#' }
fa_summarize_prices <- function(
  results,
  include_comment = TRUE,
  currency_symbol = "$",
  round_prices = TRUE
) {
  # Handle different input types
  # Check for flight query FIRST (before is.list, since flight queries are lists)
  if (inherits(results, "flight_query")) {
    # Validate flight query has data
    if (is.null(results$data) || nrow(results$data) == 0) {
      stop("flight query contains no data. Please run fa_fetch_flights() first to fetch flight data.")
    }
    # Single flight query - pass directly to extract_data_from_scrapes
    results <- extract_data_from_scrapes(results)
  } else if (is.list(results) && !is.data.frame(results)) {
    # Check if it's a list of flight queries
    if (all(sapply(results, function(x) inherits(x, "flight_query")))) {
      # Extract and combine data from list of flight queries
      results <- extract_data_from_scrapes(results)
    } else {
      stop("results must be a data frame, a flight query, or a list of flight queries")
    }
  } else if (!is.data.frame(results)) {
    stop("results must be a data frame, a flight query, or a list of flight queries")
  }

  required_cols <- c("City", "Airport", "Date", "Price")
  if (!all(required_cols %in% names(results))) {
    stop(sprintf(
      "results must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }
  
  # Check if we have any data after filtering
  if (nrow(results) == 0) {
    stop("No data available after filtering. The flight query may contain only placeholder rows or no valid flight data.")
  }

  # Convert Date to character if it's not already
  if (!is.character(results$Date)) {
    results$Date <- as.character(results$Date)
  }

  # Round prices if requested
  if (round_prices) {
    results$Price <- round(results$Price)
  }

  # Aggregate to get the minimum (cheapest) price for each City-Airport-Date combination
  # This handles cases where multiple flights exist for the same date
  results_agg <- stats::aggregate(
    Price ~ City + Airport + Date,
    data = results,
    FUN = min,
    na.rm = TRUE
  )

  # Create a unique identifier for each City-Airport combination
  results_agg$ID <- paste(results_agg$City, results_agg$Airport, sep = "_")

  # Reshape
  wide_data <- stats::reshape(
    results_agg,
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
  if (length(price_cols) == 1) {
    # Single column - just use that column directly
    wide_data$Average_Price <- wide_data[[price_cols]]
  } else {
    # Multiple columns - calculate mean
    wide_data$Average_Price <- rowMeans(wide_data[, price_cols, drop = FALSE], na.rm = TRUE)
  }

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
