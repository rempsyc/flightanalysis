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
#' @param flight_results A flight_results object from fa_fetch_flights().
#'   This function no longer accepts data frames or query objects directly.
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
#' @param excluded_airports Character vector. Airport codes to exclude from results.
#'   Default is NULL (no additional filtering beyond global excluded_airports list).
#'
#' @return A wide data frame with columns: City, Origin, Comment (optional),
#'   one column per date with prices, and an Average_Price column.
#'
#' @export
#'
#' @examples
#' # Create summary table
#' fa_summarize_prices(sample_flight_results)
#'
#' # With filters
#' fa_summarize_prices(
#'   sample_flight_results,
#'   max_stops = 0
#' )
fa_summarize_prices <- function(
  flight_results,
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
  max_emissions = NULL,
  excluded_airports = NULL
) {
  # Validate input type - only accept flight_results objects
  if (!inherits(flight_results, "flight_results")) {
    stop(
      "flight_results must be a flight_results object from fa_fetch_flights().\n",
      "This function no longer accepts data frames or query objects directly.\n",
      "Please use fa_fetch_flights() to create a flight_results object first."
    )
  }
  
  # Extract the merged data from flight_results object
  if (is.null(flight_results$data) || nrow(flight_results$data) == 0) {
    stop(
      "flight_results object contains no data. Please run fa_fetch_flights() first to fetch flight data."
    )
  }
  
  flight_results <- extract_data_from_scrapes(flight_results)

  # Normalize column names from flight_results data to legacy format
  if (
    "price" %in% names(flight_results) && !"Price" %in% names(flight_results)
  ) {
    flight_results$Price <- flight_results$price
  }

  if (
    "departure_date" %in%
      names(flight_results) &&
      !"Date" %in% names(flight_results)
  ) {
    flight_results$Date <- flight_results$departure_date
  } else if (
    "departure_datetime" %in%
      names(flight_results) &&
      !"Date" %in% names(flight_results)
  ) {
    # Backward compatibility for old format
    flight_results$Date <- as.character(as.Date(
      flight_results$departure_datetime
    ))
  }

  if (
    "origin" %in%
      names(flight_results) &&
      !any(c("Airport") %in% names(flight_results))
  ) {
    flight_results$Airport <- flight_results$origin
  }

  # Add City column if not present (use origin as fallback)
  if (
    !"City" %in% names(flight_results) &&
      "origin" %in% names(flight_results)
  ) {
    flight_results$City <- flight_results$origin
  }

  required_cols <- c("Date", "Price")
  if (!all(required_cols %in% names(flight_results))) {
    stop(sprintf(
      "flight_results must contain columns: %s (or lowercase equivalents: departure_date/departure_datetime, price)",
      paste(required_cols, collapse = ", ")
    ))
  }

  # Rename Airport to Origin for consistency
  names(flight_results)[names(flight_results) == "Airport"] <- "Origin"

  # Apply filters (same as fa_find_best_dates)
  if (!is.null(time_min)) {
    if ("departure_time" %in% names(flight_results)) {
      flight_results <- flight_results[
        flight_results$departure_time >= time_min,
      ]
    } else if ("departure_datetime" %in% names(flight_results)) {
      # Backward compatibility for old format
      time_min_parsed <- as.POSIXct(
        paste("1970-01-01", time_min),
        format = "%Y-%m-%d %H:%M"
      )
      flight_results <- flight_results[
        format(flight_results$departure_datetime, "%H:%M") >=
          format(time_min_parsed, "%H:%M"),
      ]
    }
  }

  if (!is.null(time_max)) {
    if ("departure_time" %in% names(flight_results)) {
      flight_results <- flight_results[
        flight_results$departure_time <= time_max,
      ]
    } else if ("departure_datetime" %in% names(flight_results)) {
      # Backward compatibility for old format
      time_max_parsed <- as.POSIXct(
        paste("1970-01-01", time_max),
        format = "%Y-%m-%d %H:%M"
      )
      flight_results <- flight_results[
        format(flight_results$departure_datetime, "%H:%M") <=
          format(time_max_parsed, "%H:%M"),
      ]
    }
  }

  if (!is.null(airlines) && "airlines" %in% names(flight_results)) {
    airline_filter <- sapply(flight_results$airlines, function(x) {
      any(sapply(airlines, function(a) grepl(a, x, ignore.case = TRUE)))
    })
    flight_results <- flight_results[airline_filter, ]
  }

  if (!is.null(price_min)) {
    flight_results <- flight_results[flight_results$Price >= price_min, ]
  }

  if (!is.null(price_max)) {
    flight_results <- flight_results[flight_results$Price <= price_max, ]
  }

  if (!is.null(travel_time_max) && "travel_time" %in% names(flight_results)) {
    # Parse travel time using helper function
    flight_results$travel_time_minutes <- sapply(
      flight_results$travel_time,
      parse_time_to_minutes
    )

    # Convert travel_time_max to minutes using helper function
    max_minutes <- parse_time_to_minutes(travel_time_max)

    flight_results <- flight_results[
      !is.na(flight_results$travel_time_minutes) &
        flight_results$travel_time_minutes <= max_minutes,
    ]
    flight_results$travel_time_minutes <- NULL
  }

  if (!is.null(max_stops) && "num_stops" %in% names(flight_results)) {
    flight_results <- flight_results[flight_results$num_stops <= max_stops, ]
  }

  if (!is.null(max_layover) && "layover" %in% names(flight_results)) {
    # Parse layover time using helper function (treat NA/empty as 0)
    flight_results$layover_minutes <- sapply(
      flight_results$layover,
      function(x) {
        if (is.na(x) || x == "NA") {
          return(0)
        }
        parse_time_to_minutes(x)
      }
    )

    # Parse max_layover as a single string
    max_layover_minutes <- parse_time_to_minutes(max_layover)

    flight_results <- flight_results[
      flight_results$layover_minutes <= max_layover_minutes,
    ]
    flight_results$layover_minutes <- NULL
  }

  if (!is.null(max_emissions) && "co2_emission_kg" %in% names(flight_results)) {
    flight_results <- flight_results[
      !is.na(flight_results$co2_emission_kg) &
        flight_results$co2_emission_kg <= max_emissions,
    ]
  }

  # Filter out excluded airports if specified
  if (!is.null(excluded_airports) && "Origin" %in% names(flight_results)) {
    flight_results <- flight_results[
      !flight_results$Origin %in% excluded_airports,
    ]
  }

  # Check if we have any data after filtering
  if (nrow(flight_results) == 0) {
    stop(
      "No data available after filtering. The flight query may contain only placeholder rows or no valid flight data."
    )
  }

  # Convert Date to character if it's not already
  if (!is.character(flight_results$Date)) {
    flight_results$Date <- as.character(flight_results$Date)
  }

  # Round prices if requested
  if (round_prices) {
    flight_results$Price <- round(flight_results$Price)
  }

  # Aggregate to get the minimum (cheapest) price for each City-Origin-Date combination
  # This handles cases where multiple flights exist for the same date
  results_agg <- stats::aggregate(
    Price ~ City + Origin + Date,
    data = flight_results,
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
  if (include_comment && "Comment" %in% names(flight_results)) {
    # Get unique comments for each City-Origin pair
    comment_map <- unique(flight_results[, c("City", "Origin", "Comment")])
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
  # Create an empty template row for "Best" matching the structure of wide_data
  best_row <- wide_data[1, , drop = FALSE]
  best_row[1, ] <- NA
  best_row$City <- "Best"
  best_row$Origin <- "Day"

  if ("Comment" %in% names(best_row)) {
    best_row$Comment <- ""
  }

  # Find the absolute minimum price across ALL date columns
  all_prices <- c()
  for (col in date_names_sorted) {
    if (col %in% names(wide_data)) {
      col_vals <- wide_data[[col]]
      # Convert to numeric
      if (is.character(col_vals)) {
        col_vals <- as.numeric(gsub("[^0-9.]", "", col_vals))
      }
      all_prices <- c(all_prices, col_vals[!is.na(col_vals)])
    }
  }

  # Get the global minimum price
  global_min <- min(all_prices, na.rm = TRUE)

  # Mark only the ONE column that contains this minimum price
  found_min <- FALSE
  for (col in date_names_sorted) {
    if (col %in% names(wide_data) && !found_min) {
      col_vals <- wide_data[[col]]
      # Convert to numeric
      if (is.character(col_vals)) {
        col_vals <- as.numeric(gsub("[^0-9.]", "", col_vals))
      }
      # Check if this column contains the global minimum
      if (any(!is.na(col_vals) & col_vals == global_min)) {
        best_row[[col]] <- "X"
        found_min <- TRUE
      } else {
        best_row[[col]] <- ""
      }
    } else if (col %in% names(wide_data)) {
      best_row[[col]] <- ""
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
