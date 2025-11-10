#' Create Flexible Date Summary Table
#'
#' @description
#' Creates a wide summary table showing prices by city/airport and date,
#' with an average price column. This is useful for visualizing price
#' patterns across multiple dates and comparing different origin airports.
#'
#' @param results Either:
#'   - A data frame with columns: City, Airport, Date, Price, and optionally Comment
#'   - A list of Scrape objects (from fa_create_date_range_scrape with multiple origins)
#'   - A single Scrape object (from fa_create_date_range_scrape with single origin)
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
#' # Option 1: Pass list of Scrape objects directly
#' scrapes <- fa_create_date_range_scrape(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
#' for (code in names(scrapes)) {
#'   scrapes[[code]] <- ScrapeObjects(scrapes[[code]])
#' }
#' summary_table <- fa_flex_table(scrapes)
#' 
#' # Option 2: Pass processed data frame
#' summary_table <- fa_flex_table(my_data_frame)
#' }
fa_flex_table <- function(
  results,
  include_comment = TRUE,
  currency_symbol = "$",
  round_prices = TRUE
) {
  # Handle different input types
  if (is.list(results) && !is.data.frame(results)) {
    # Check if it's a list of Scrape objects
    if (all(sapply(results, function(x) inherits(x, "Scrape")))) {
      # Extract and combine data from list of Scrape objects
      results <- extract_data_from_scrapes(results)
    } else {
      stop("results must be a data frame, a Scrape object, or a list of Scrape objects")
    }
  } else if (inherits(results, "Scrape")) {
    # Single Scrape object
    results <- extract_data_from_scrapes(list(results))
  } else if (!is.data.frame(results)) {
    stop("results must be a data frame, a Scrape object, or a list of Scrape objects")
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
