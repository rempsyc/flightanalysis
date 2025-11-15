#' Create Price Summary Table
#'
#' @description
#' Creates a wide summary table showing prices by city/airport and date,
#' with an average price column. When multiple flights exist for the same
#' date, uses the minimum (cheapest) price. This is useful for visualizing
#' price patterns across multiple dates and comparing different origin airports.
#' Supports filtering by various criteria such as departure time, airlines,
#' travel time, stops, and emissions.
#'
#' @param results Either:
#'   - A data frame with columns: City, Airport, Date, Price, and optionally Comment (Airport will be renamed to Origin)
#'   - A list of flight queries (from fa_create_date_range with multiple origins)
#'   - A single flight query (from fa_create_date_range with single origin)
#' @param include_comment Logical. If TRUE and Comment column exists, includes
#'   it in the output. Default is TRUE.
#' @param currency_symbol Character. Currency symbol to use for formatting.
#'   Default is "$".
#' @param round_prices Logical. If TRUE, rounds prices to nearest integer.
#'   Default is TRUE.
#' @param time_min Character. Minimum departure time in "HH:MM" format (24-hour).
#'   Filters flights departing at or after this time. Default is NULL (no filter).
#' @param time_max Character. Maximum departure time in "HH:MM" format (24-hour).
#'   Filters flights departing at or before this time. Default is NULL (no filter).
#' @param airlines Character vector. Filter by specific airlines. Default is NULL (no filter).
#' @param price_min Numeric. Minimum price. Default is NULL (no filter).
#' @param price_max Numeric. Maximum price. Default is NULL (no filter).
#' @param travel_time_max Numeric or character. Maximum travel time. 
#'   If numeric, interpreted as hours. If character, use format "XX hr XX min".
#'   Default is NULL (no filter).
#' @param max_stops Integer. Maximum number of stops. Default is NULL (no filter).
#' @param max_layover Character. Maximum layover time in format "XX hr XX min".
#'   Default is NULL (no filter).
#' @param max_emissions Numeric. Maximum CO2 emissions in kg. Default is NULL (no filter).
#'
#' @return A wide data frame with columns: City, Origin, Comment (optional),
#'   one column per date with prices, and an Average_Price column.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' queries <- fa_create_date_range(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
#' for (code in names(queries)) {
#'   queries[[code]] <- fa_fetch_flights(queries[[code]])
#' }
#' summary_table <- fa_summarize_prices(queries)
#'
#' # With filters
#' summary_table <- fa_summarize_prices(
#'   queries,
#'   time_min = "08:00",
#'   time_max = "20:00",
#'   max_stops = 1
#' )
#' }
fa_summarize_prices <- function(
  results,
  include_comment = TRUE,
  currency_symbol = "$",
  round_prices = TRUE,
  time_min = NULL,
  time_max = NULL,
  airlines = NULL,
  price_min = NULL,
  price_max = NULL,
  travel_time_max = NULL,
  max_stops = NULL,
  max_layover = NULL,
  max_emissions = NULL
) {
  # Handle different input types
  # Check for flight query FIRST (before is.list, since flight queries are lists)
  if (inherits(results, "flight_query")) {
    # Validate flight query has data
    if (is.null(results$data) || nrow(results$data) == 0) {
      stop(
        "flight query contains no data. Please run fa_fetch_flights() first to fetch flight data."
      )
    }
    # Single flight query - pass directly to extract_data_from_scrapes
    results <- extract_data_from_scrapes(results)
  } else if (is.list(results) && !is.data.frame(results)) {
    # Check if it's a list of flight queries
    if (all(sapply(results, function(x) inherits(x, "flight_query")))) {
      # Extract and combine data from list of flight queries
      results <- extract_data_from_scrapes(results)
    } else {
      stop(
        "results must be a data frame, a flight query, or a list of flight queries"
      )
    }
  } else if (!is.data.frame(results)) {
    stop(
      "results must be a data frame, a flight query, or a list of flight queries"
    )
  }

  required_cols <- c("City", "Airport", "Date", "Price")
  if (!all(required_cols %in% names(results))) {
    stop(sprintf(
      "results must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }
  
  # Rename Airport to Origin for consistency
  names(results)[names(results) == "Airport"] <- "Origin"

  # Apply filters (same as fa_find_best_dates)
  if (!is.null(time_min) && "departure_datetime" %in% names(results)) {
    time_min_parsed <- as.POSIXct(paste("1970-01-01", time_min), format = "%Y-%m-%d %H:%M")
    results <- results[format(results$departure_datetime, "%H:%M") >= format(time_min_parsed, "%H:%M"), ]
  }
  
  if (!is.null(time_max) && "departure_datetime" %in% names(results)) {
    time_max_parsed <- as.POSIXct(paste("1970-01-01", time_max), format = "%Y-%m-%d %H:%M")
    results <- results[format(results$departure_datetime, "%H:%M") <= format(time_max_parsed, "%H:%M"), ]
  }
  
  if (!is.null(airlines) && "airlines" %in% names(results)) {
    airline_filter <- sapply(results$airlines, function(x) {
      any(sapply(airlines, function(a) grepl(a, x, ignore.case = TRUE)))
    })
    results <- results[airline_filter, ]
  }
  
  if (!is.null(price_min)) {
    results <- results[results$Price >= price_min, ]
  }
  
  if (!is.null(price_max)) {
    results <- results[results$Price <= price_max, ]
  }
  
  if (!is.null(travel_time_max) && "travel_time" %in% names(results)) {
    # Parse travel time using helper function
    results$travel_time_minutes <- sapply(results$travel_time, parse_time_to_minutes)
    
    # Convert travel_time_max to minutes using helper function
    max_minutes <- parse_time_to_minutes(travel_time_max)
    
    results <- results[!is.na(results$travel_time_minutes) & results$travel_time_minutes <= max_minutes, ]
    results$travel_time_minutes <- NULL
  }
  
  if (!is.null(max_stops) && "num_stops" %in% names(results)) {
    results <- results[results$num_stops <= max_stops, ]
  }
  
  if (!is.null(max_layover) && "layover" %in% names(results)) {
    # Parse layover time using helper function (treat NA/empty as 0)
    results$layover_minutes <- sapply(results$layover, function(x) {
      if (is.na(x) || x == "NA") return(0)
      parse_time_to_minutes(x)
    })
    
    # Parse max_layover as a single string
    max_layover_minutes <- parse_time_to_minutes(max_layover)
    
    results <- results[results$layover_minutes <= max_layover_minutes, ]
    results$layover_minutes <- NULL
  }
  
  if (!is.null(max_emissions) && "co2_emission_kg" %in% names(results)) {
    results <- results[!is.na(results$co2_emission_kg) & results$co2_emission_kg <= max_emissions, ]
  }

  # Check if we have any data after filtering
  if (nrow(results) == 0) {
    stop(
      "No data available after filtering. The flight query may contain only placeholder rows or no valid flight data."
    )
  }

  # Convert Date to character if it's not already
  if (!is.character(results$Date)) {
    results$Date <- as.character(results$Date)
  }

  # Round prices if requested
  if (round_prices) {
    results$Price <- round(results$Price)
  }

  # Aggregate to get the minimum (cheapest) price for each City-Origin-Date combination
  # This handles cases where multiple flights exist for the same date
  results_agg <- stats::aggregate(
    Price ~ City + Origin + Date,
    data = results,
    FUN = min,
    na.rm = TRUE
  )

  # Create a unique identifier for each City-Origin combination
  results_agg$ID <- paste(results_agg$City, results_agg$Origin, sep = "_")

  # Reshape
  wide_data <- stats::reshape(
    results_agg,
    idvar = "ID",
    timevar = "Date",
    v.names = "Price",
    direction = "wide",
    sep = "_"
  )

  # Extract City and Origin from ID
  id_parts <- strsplit(wide_data$ID, "_")
  wide_data$City <- sapply(id_parts, function(x) x[1])
  wide_data$Origin <- sapply(id_parts, function(x) x[2])

  # Remove ID column
  wide_data$ID <- NULL

  # Calculate average price
  price_cols <- grep("^Price_", names(wide_data))
  if (length(price_cols) == 1) {
    # Single column - just use that column directly
    wide_data$Average_Price <- wide_data[[price_cols]]
  } else {
    # Multiple columns - calculate mean
    wide_data$Average_Price <- rowMeans(
      wide_data[, price_cols, drop = FALSE],
      na.rm = TRUE
    )
  }

  if (round_prices) {
    wide_data$Average_Price <- round(wide_data$Average_Price)
  }

  # Reorder columns: City, Origin, Comment (if applicable), dates, Average_Price
  base_cols <- c("City", "Origin")

  # Add Comment column if it exists and is requested
  if (include_comment && "Comment" %in% names(results)) {
    # Get unique comments for each City-Origin pair
    comment_map <- unique(results[, c("City", "Origin", "Comment")])
    wide_data <- merge(
      wide_data,
      comment_map,
      by = c("City", "Origin"),
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

  # Add "Best" row showing which dates have minimum prices
  # Create an empty template row for "Best"
  best_row <- as.data.frame(lapply(wide_data, function(x) NA), stringsAsFactors = FALSE)
  best_row$City <- "Best"
  best_row$Origin <- "Best"
  
  if ("Comment" %in% names(best_row)) {
    best_row$Comment <- ""
  }
  
  # For each date column, check if it has the minimum price
  for (col in date_names_sorted) {
    if (col %in% names(wide_data)) {
      # Extract numeric values (remove currency symbol if already formatted)
      col_vals <- wide_data[[col]]
      # Convert to numeric
      if (is.character(col_vals)) {
        col_vals <- as.numeric(gsub("[^0-9.]", "", col_vals))
      }
      min_val <- min(col_vals, na.rm = TRUE)
      # Check if current column value equals minimum
      is_min <- !is.na(col_vals) & col_vals == min_val
      # Mark with "X" if minimum, otherwise empty string
      best_row[[col]] <- ifelse(any(is_min), "X", "")
    }
  }
  
  # Average_Price column should be empty for Best row
  best_row$Average_Price <- ""

  # Format prices with currency symbol
  price_format_cols <- c(date_names_sorted, "Average_Price")
  for (col in price_format_cols) {
    if (col %in% names(wide_data)) {
      # Format only non-NA values
      formatted_vals <- ifelse(
        is.na(wide_data[[col]]),
        NA_character_,
        paste0(
          currency_symbol,
          format(wide_data[[col]], big.mark = ",", scientific = FALSE)
        )
      )
      wide_data[[col]] <- formatted_vals
    }
  }
  
  # Append the "Best" row at the bottom
  wide_data <- rbind(wide_data, best_row)
  rownames(wide_data) <- NULL

  return(wide_data)
}
