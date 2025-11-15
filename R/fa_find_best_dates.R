#' Find Best Travel Dates
#'
#' @description
#' Identifies and returns the top N dates with the cheapest average prices
#' across all routes. This helps quickly identify the best travel dates
#' when planning a flexible trip. Supports filtering by various criteria
#' such as departure time, airlines, travel time, stops, and emissions.
#'
#' @param results Either:
#'   - A data frame with columns: Date and Price (and optionally other filter columns)
#'   - A list of flight queries (from fa_create_date_range with multiple origins)
#'   - A single flight query (from fa_create_date_range with single origin)
#' @param n Integer. Number of best dates to return. Default is 10.
#' @param by Character. How to calculate best dates: "mean" (average price
#'   across routes), "median", or "min" (lowest price on that date).
#'   Default is "min".
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
#' @return A data frame with columns: departure_date, departure_time (or date if datetime not available),
#'   origin, price (average/median/min), n_routes, num_stops, layover, travel_time,
#'   co2_emission_kg, and airlines. All column names are lowercase.
#'   Sorted by price (cheapest first). Additional columns are aggregated using
#'   mean/median for numeric values and most common value for categorical.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' queries <- fa_create_date_range(c("BOM", "DEL"), "JFK", "2025-12-28", "2026-01-02")
#' flights <- fa_fetch_flights(queries)
#' fa_find_best_dates(flights, n = 5, by = "min")
#'
#' # With filters
#' fa_find_best_dates(
#'   flights,
#'   n = 5,
#'   time_min = "08:00",
#'   time_max = "20:00",
#'   max_stops = 1,
#'   max_emissions = 500
#' )
#' }
fa_find_best_dates <- function(
  results,
  n = 10,
  by = "min",
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

  required_cols <- c("Date", "Price")
  if (!all(required_cols %in% names(results))) {
    stop(sprintf(
      "results must contain columns: %s",
      paste(required_cols, collapse = ", ")
    ))
  }

  # Rename Airport to Origin for consistency
  if ("Airport" %in% names(results)) {
    names(results)[names(results) == "Airport"] <- "Origin"
  }

  # Apply filters
  if (!is.null(time_min) && "departure_datetime" %in% names(results)) {
    time_min_parsed <- as.POSIXct(
      paste("1970-01-01", time_min),
      format = "%Y-%m-%d %H:%M"
    )
    results <- results[
      format(results$departure_datetime, "%H:%M") >=
        format(time_min_parsed, "%H:%M"),
    ]
  }

  if (!is.null(time_max) && "departure_datetime" %in% names(results)) {
    time_max_parsed <- as.POSIXct(
      paste("1970-01-01", time_max),
      format = "%Y-%m-%d %H:%M"
    )
    results <- results[
      format(results$departure_datetime, "%H:%M") <=
        format(time_max_parsed, "%H:%M"),
    ]
  }

  if (!is.null(airlines) && "airlines" %in% names(results)) {
    # Check if any of the specified airlines appear in the airlines column
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
    results$travel_time_minutes <- sapply(
      results$travel_time,
      parse_time_to_minutes
    )

    # Convert travel_time_max to minutes using helper function
    max_minutes <- parse_time_to_minutes(travel_time_max)

    results <- results[
      !is.na(results$travel_time_minutes) &
        results$travel_time_minutes <= max_minutes,
    ]
    results$travel_time_minutes <- NULL
  }

  if (!is.null(max_stops) && "num_stops" %in% names(results)) {
    results <- results[results$num_stops <= max_stops, ]
  }

  if (!is.null(max_layover) && "layover" %in% names(results)) {
    # Parse layover time using helper function (treat NA/empty as 0)
    results$layover_minutes <- sapply(results$layover, function(x) {
      if (is.na(x) || x == "NA") {
        return(0)
      }
      parse_time_to_minutes(x)
    })

    # Parse max_layover as a single string
    max_layover_minutes <- parse_time_to_minutes(max_layover)

    results <- results[results$layover_minutes <= max_layover_minutes, ]
    results$layover_minutes <- NULL
  }

  if (!is.null(max_emissions) && "co2_emission_kg" %in% names(results)) {
    results <- results[
      !is.na(results$co2_emission_kg) &
        results$co2_emission_kg <= max_emissions,
    ]
  }

  # Check if we have any data after filtering
  if (nrow(results) == 0) {
    stop(
      "No data available after filtering. The flight query may contain only placeholder rows or no valid flight data."
    )
  }

  if (!by %in% c("mean", "median", "min")) {
    stop("by must be one of: 'mean', 'median', 'min'")
  }

  # Use departure_datetime if available, otherwise fall back to Date
  grouping_col <- if ("departure_datetime" %in% names(results)) {
    "departure_datetime"
  } else {
    "Date"
  }

  # Aggregate by datetime/date and origin (if Origin column exists)
  if ("Origin" %in% names(results)) {
    # Build aggregation formula dynamically
    agg_formula <- stats::as.formula(paste("Price ~", grouping_col, "+ Origin"))

    # Aggregate price
    date_summary <- stats::aggregate(
      agg_formula,
      data = results,
      FUN = function(x) {
        switch(
          by,
          mean = mean(x, na.rm = TRUE),
          median = stats::median(x, na.rm = TRUE),
          min = min(x, na.rm = TRUE)
        )
      }
    )

    # Find the best origin (cheapest) for each datetime/date
    date_summary <- do.call(
      rbind,
      lapply(split(date_summary, date_summary[[grouping_col]]), function(df) {
        df[which.min(df$Price), ]
      })
    )

    # Add additional information columns if available
    if ("num_stops" %in% names(results)) {
      stops_agg <- stats::aggregate(
        stats::as.formula(paste("num_stops ~", grouping_col, "+ Origin")),
        data = results,
        FUN = function(x) round(mean(x, na.rm = TRUE), 1)
      )
      date_summary <- merge(
        date_summary,
        stops_agg,
        by = c(grouping_col, "Origin"),
        all.x = TRUE
      )
    }

    if ("layover" %in% names(results)) {
      # For layover, take the most common value
      layover_agg <- stats::aggregate(
        stats::as.formula(paste("layover ~", grouping_col, "+ Origin")),
        data = results,
        FUN = function(x) {
          x <- x[!is.na(x) & x != "NA"]
          if (length(x) == 0) {
            return(NA_character_)
          }
          names(sort(table(x), decreasing = TRUE))[1]
        }
      )
      date_summary <- merge(
        date_summary,
        layover_agg,
        by = c(grouping_col, "Origin"),
        all.x = TRUE
      )
    }

    if ("travel_time" %in% names(results)) {
      # For travel_time, take the most common value
      travel_agg <- stats::aggregate(
        stats::as.formula(paste("travel_time ~", grouping_col, "+ Origin")),
        data = results,
        FUN = function(x) {
          x <- x[!is.na(x)]
          if (length(x) == 0) {
            return(NA_character_)
          }
          names(sort(table(x), decreasing = TRUE))[1]
        }
      )
      date_summary <- merge(
        date_summary,
        travel_agg,
        by = c(grouping_col, "Origin"),
        all.x = TRUE
      )
    }

    if ("co2_emission_kg" %in% names(results)) {
      emissions_agg <- stats::aggregate(
        stats::as.formula(paste("co2_emission_kg ~", grouping_col, "+ Origin")),
        data = results,
        FUN = function(x) round(mean(x, na.rm = TRUE), 0)
      )
      date_summary <- merge(
        date_summary,
        emissions_agg,
        by = c(grouping_col, "Origin"),
        all.x = TRUE
      )
    }

    if ("airlines" %in% names(results)) {
      # For airlines, take the most common value
      airlines_agg <- stats::aggregate(
        stats::as.formula(paste("airlines ~", grouping_col, "+ Origin")),
        data = results,
        FUN = function(x) {
          x <- x[!is.na(x)]
          if (length(x) == 0) {
            return(NA_character_)
          }
          names(sort(table(x), decreasing = TRUE))[1]
        }
      )
      date_summary <- merge(
        date_summary,
        airlines_agg,
        by = c(grouping_col, "Origin"),
        all.x = TRUE
      )
    }

    # Count number of routes per datetime/date (total across all origins)
    route_counts <- stats::aggregate(
      stats::as.formula(paste("Price ~", grouping_col)),
      data = results,
      FUN = function(x) sum(!is.na(x))
    )
    names(route_counts)[2] <- "N_Routes"

    # Combine
    date_summary <- merge(date_summary, route_counts, by = grouping_col)
  } else {
    # Aggregate by datetime/date only (no Origin column)
    agg_formula <- stats::as.formula(paste("Price ~", grouping_col))

    date_summary <- stats::aggregate(
      agg_formula,
      data = results,
      FUN = function(x) {
        switch(
          by,
          mean = mean(x, na.rm = TRUE),
          median = stats::median(x, na.rm = TRUE),
          min = min(x, na.rm = TRUE)
        )
      }
    )

    # Add additional information columns if available
    if ("num_stops" %in% names(results)) {
      stops_agg <- stats::aggregate(
        stats::as.formula(paste("num_stops ~", grouping_col)),
        data = results,
        FUN = function(x) round(mean(x, na.rm = TRUE), 1)
      )
      date_summary <- merge(
        date_summary,
        stops_agg,
        by = grouping_col,
        all.x = TRUE
      )
    }

    if ("layover" %in% names(results)) {
      layover_agg <- stats::aggregate(
        stats::as.formula(paste("layover ~", grouping_col)),
        data = results,
        FUN = function(x) {
          x <- x[!is.na(x) & x != "NA"]
          if (length(x) == 0) {
            return(NA_character_)
          }
          names(sort(table(x), decreasing = TRUE))[1]
        }
      )
      date_summary <- merge(
        date_summary,
        layover_agg,
        by = grouping_col,
        all.x = TRUE
      )
    }

    if ("travel_time" %in% names(results)) {
      travel_agg <- stats::aggregate(
        stats::as.formula(paste("travel_time ~", grouping_col)),
        data = results,
        FUN = function(x) {
          x <- x[!is.na(x)]
          if (length(x) == 0) {
            return(NA_character_)
          }
          names(sort(table(x), decreasing = TRUE))[1]
        }
      )
      date_summary <- merge(
        date_summary,
        travel_agg,
        by = grouping_col,
        all.x = TRUE
      )
    }

    if ("co2_emission_kg" %in% names(results)) {
      emissions_agg <- stats::aggregate(
        stats::as.formula(paste("co2_emission_kg ~", grouping_col)),
        data = results,
        FUN = function(x) round(mean(x, na.rm = TRUE), 0)
      )
      date_summary <- merge(
        date_summary,
        emissions_agg,
        by = grouping_col,
        all.x = TRUE
      )
    }

    if ("airlines" %in% names(results)) {
      airlines_agg <- stats::aggregate(
        stats::as.formula(paste("airlines ~", grouping_col)),
        data = results,
        FUN = function(x) {
          x <- x[!is.na(x)]
          if (length(x) == 0) {
            return(NA_character_)
          }
          names(sort(table(x), decreasing = TRUE))[1]
        }
      )
      date_summary <- merge(
        date_summary,
        airlines_agg,
        by = grouping_col,
        all.x = TRUE
      )
    }

    # Count number of routes per datetime/date
    route_counts <- stats::aggregate(
      agg_formula,
      data = results,
      FUN = function(x) sum(!is.na(x))
    )
    names(route_counts)[2] <- "N_Routes"

    # Combine
    date_summary <- merge(date_summary, route_counts, by = grouping_col)
  }

  # Split departure_datetime into departure_date and departure_time if it exists
  if ("departure_datetime" %in% names(date_summary)) {
    # Ensure it's a POSIXct object before formatting
    if (!inherits(date_summary$departure_datetime, "POSIXct")) {
      date_summary$departure_datetime <- as.POSIXct(
        date_summary$departure_datetime
      )
    }
    date_summary$departure_date <- as.Date(date_summary$departure_datetime)
    date_summary$departure_time <- format(
      date_summary$departure_datetime,
      "%H:%M:%S"
    )
    # Remove the original departure_datetime column
    date_summary$departure_datetime <- NULL
  }

  # Standardize column names to lowercase
  names(date_summary) <- tolower(names(date_summary))

  # Sort by price
  date_summary <- date_summary[order(date_summary$price), ]

  # Return top n
  if (n < nrow(date_summary)) {
    date_summary <- date_summary[1:n, ]
  }

  rownames(date_summary) <- NULL

  return(date_summary)
}
