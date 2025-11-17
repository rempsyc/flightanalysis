#' Find Best Travel Dates
#'
#' @description
#' Identifies and returns the top N dates with the cheapest average prices
#' across all routes. This helps quickly identify the best travel dates
#' when planning a flexible trip. Supports filtering by various criteria
#' such as departure time, airlines, travel time, stops, and emissions.
#'
#' @param flight_results A flight_results object from fa_fetch_flights().
#'   This function no longer accepts data frames or query objects directly.
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
#'   origin, price (average/median/min), n_routes, num_stops, layover, 
#'   travel_time, co2_emission_kg, airlines, arrival_date, arrival_time. All column names are lowercase.
#'   Returns the top N dates with best (lowest) prices, sorted by departure time for display.
#'   Additional columns are aggregated using mean/median for numeric values and most common value for categorical.
#'   Note: arrival_date and arrival_time represent the most common values when multiple flights are aggregated
#'   and may not correspond exactly to the specific departure times shown.
#'
#' @export
#'
#' @examples
#' # Find best dates
#' fa_find_best_dates(sample_flight_results, n = 3, by = "min")
#'
#' # With filters
#' fa_find_best_dates(
#'   sample_flight_results,
#'   n = 2,
#'   max_stops = 0
#' )
fa_find_best_dates <- function(
  flight_results,
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

  # Normalize column names for direct data frame input
  if (
    "price" %in% names(flight_results) && !"Price" %in% names(flight_results)
  ) {
    flight_results$Price <- flight_results$price
  }

  if (
    "departure_date" %in% names(flight_results) &&
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
      !any(c("Origin", "Airport") %in% names(flight_results))
  ) {
    flight_results$Origin <- flight_results$origin
  }

  required_cols <- c("Date", "Price")
  if (!all(required_cols %in% names(flight_results))) {
    stop(sprintf(
      "flight_results must contain columns: %s (or lowercase equivalents: departure_date/departure_datetime, price)",
      paste(required_cols, collapse = ", ")
    ))
  }

  # Rename Airport to Origin for consistency
  if ("Airport" %in% names(flight_results)) {
    names(flight_results)[names(flight_results) == "Airport"] <- "Origin"
  }

  # Apply filters
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
    # Check if any of the specified airlines appear in the airlines column
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

  # Check if we have any data after filtering
  if (nrow(flight_results) == 0) {
    stop(
      "No data available after filtering. The flight query may contain only placeholder rows or no valid flight data."
    )
  }

  if (!by %in% c("mean", "median", "min")) {
    stop("by must be one of: 'mean', 'median', 'min'")
  }

  # Create a combined datetime column for grouping if we have split columns
  if ("departure_date" %in% names(flight_results) &&
      "departure_time" %in% names(flight_results)) {
    flight_results$departure_datetime <- as.POSIXct(
      paste(flight_results$departure_date, flight_results$departure_time),
      format = "%Y-%m-%d %H:%M"
    )
  }
  
  # Use departure_datetime if available, otherwise fall back to Date
  grouping_col <- if ("departure_datetime" %in% names(flight_results)) {
    "departure_datetime"
  } else {
    "Date"
  }

  # Aggregate by datetime/date and origin (if Origin column exists)
  if ("Origin" %in% names(flight_results)) {
    # Build aggregation formula dynamically
    agg_formula <- stats::as.formula(paste("Price ~", grouping_col, "+ Origin"))

    # Aggregate price
    date_summary <- stats::aggregate(
      agg_formula,
      data = flight_results,
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
    if ("num_stops" %in% names(flight_results)) {
      stops_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("num_stops ~", grouping_col, "+ Origin")),
            data = flight_results,
            FUN = function(x) round(mean(x, na.rm = TRUE), 1)
          )
        },
        error = function(e) NULL
      )
      if (!is.null(stops_agg)) {
        date_summary <- merge(
          date_summary,
          stops_agg,
          by = c(grouping_col, "Origin"),
          all.x = TRUE
        )
      }
    }

    if ("layover" %in% names(flight_results)) {
      # For layover, take the most common value
      layover_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("layover ~", grouping_col, "+ Origin")),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x) & x != "NA"]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(layover_agg)) {
        date_summary <- merge(
          date_summary,
          layover_agg,
          by = c(grouping_col, "Origin"),
          all.x = TRUE
        )
      }
    }

    if ("travel_time" %in% names(flight_results)) {
      # For travel_time, take the most common value
      travel_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("travel_time ~", grouping_col, "+ Origin")),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x)]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(travel_agg)) {
        date_summary <- merge(
          date_summary,
          travel_agg,
          by = c(grouping_col, "Origin"),
          all.x = TRUE
        )
      }
    }

    if ("co2_emission_kg" %in% names(flight_results)) {
      emissions_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste(
              "co2_emission_kg ~",
              grouping_col,
              "+ Origin"
            )),
            data = flight_results,
            FUN = function(x) round(mean(x, na.rm = TRUE), 0)
          )
        },
        error = function(e) NULL
      )
      if (!is.null(emissions_agg)) {
        date_summary <- merge(
          date_summary,
          emissions_agg,
          by = c(grouping_col, "Origin"),
          all.x = TRUE
        )
      }
    }

    if ("airlines" %in% names(flight_results)) {
      # For airlines, take the most common value
      airlines_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("airlines ~", grouping_col, "+ Origin")),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x)]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(airlines_agg)) {
        date_summary <- merge(
          date_summary,
          airlines_agg,
          by = c(grouping_col, "Origin"),
          all.x = TRUE
        )
      }
    }

    if ("arrival_date" %in% names(flight_results)) {
      # For arrival_date, take the most common value
      arrival_date_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("arrival_date ~", grouping_col, "+ Origin")),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x)]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(arrival_date_agg)) {
        date_summary <- merge(
          date_summary,
          arrival_date_agg,
          by = c(grouping_col, "Origin"),
          all.x = TRUE
        )
      }
    }

    if ("arrival_time" %in% names(flight_results)) {
      # For arrival_time, take the most common value
      arrival_time_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("arrival_time ~", grouping_col, "+ Origin")),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x)]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(arrival_time_agg)) {
        date_summary <- merge(
          date_summary,
          arrival_time_agg,
          by = c(grouping_col, "Origin"),
          all.x = TRUE
        )
      }
    }

    # Count number of routes per datetime/date (total across all origins)
    route_counts <- stats::aggregate(
      stats::as.formula(paste("Price ~", grouping_col)),
      data = flight_results,
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
      data = flight_results,
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
    if ("num_stops" %in% names(flight_results)) {
      stops_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("num_stops ~", grouping_col)),
            data = flight_results,
            FUN = function(x) round(mean(x, na.rm = TRUE), 1)
          )
        },
        error = function(e) NULL
      )
      if (!is.null(stops_agg)) {
        date_summary <- merge(
          date_summary,
          stops_agg,
          by = grouping_col,
          all.x = TRUE
        )
      }
    }

    if ("layover" %in% names(flight_results)) {
      layover_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("layover ~", grouping_col)),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x) & x != "NA"]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(layover_agg)) {
        date_summary <- merge(
          date_summary,
          layover_agg,
          by = grouping_col,
          all.x = TRUE
        )
      }
    }

    if ("travel_time" %in% names(flight_results)) {
      travel_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("travel_time ~", grouping_col)),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x)]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(travel_agg)) {
        date_summary <- merge(
          date_summary,
          travel_agg,
          by = grouping_col,
          all.x = TRUE
        )
      }
    }

    if ("co2_emission_kg" %in% names(flight_results)) {
      emissions_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("co2_emission_kg ~", grouping_col)),
            data = flight_results,
            FUN = function(x) round(mean(x, na.rm = TRUE), 0)
          )
        },
        error = function(e) NULL
      )
      if (!is.null(emissions_agg)) {
        date_summary <- merge(
          date_summary,
          emissions_agg,
          by = grouping_col,
          all.x = TRUE
        )
      }
    }

    if ("airlines" %in% names(flight_results)) {
      airlines_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("airlines ~", grouping_col)),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x)]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(airlines_agg)) {
        date_summary <- merge(
          date_summary,
          airlines_agg,
          by = grouping_col,
          all.x = TRUE
        )
      }
    }

    if ("arrival_date" %in% names(flight_results)) {
      # For arrival_date, take the most common value
      arrival_date_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("arrival_date ~", grouping_col)),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x)]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(arrival_date_agg)) {
        date_summary <- merge(
          date_summary,
          arrival_date_agg,
          by = grouping_col,
          all.x = TRUE
        )
      }
    }

    if ("arrival_time" %in% names(flight_results)) {
      # For arrival_time, take the most common value
      arrival_time_agg <- tryCatch(
        {
          stats::aggregate(
            stats::as.formula(paste("arrival_time ~", grouping_col)),
            data = flight_results,
            FUN = function(x) {
              x <- x[!is.na(x)]
              if (length(x) == 0) {
                return(NA_character_)
              }
              names(sort(table(x), decreasing = TRUE))[1]
            }
          )
        },
        error = function(e) NULL
      )
      if (!is.null(arrival_time_agg)) {
        date_summary <- merge(
          date_summary,
          arrival_time_agg,
          by = grouping_col,
          all.x = TRUE
        )
      }
    }

    # Count number of routes per datetime/date
    route_counts <- stats::aggregate(
      agg_formula,
      data = flight_results,
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
      "%H:%M"
    )
    # Remove the original departure_datetime column
    date_summary$departure_datetime <- NULL
  }

  # Standardize column names to lowercase
  names(date_summary) <- tolower(names(date_summary))

  # Sort by price first to identify the best n dates
  if ("price" %in% names(date_summary)) {
    date_summary <- date_summary[order(date_summary$price), ]
  }

  # Return top n
  if (n < nrow(date_summary)) {
    date_summary <- date_summary[1:n, ]
  }

  # Now sort the selected n by departure time/date for display
  if ("departure_time" %in% names(date_summary)) {
    date_summary <- date_summary[
      order(date_summary$departure_date, date_summary$departure_time),
    ]
  } else if ("date" %in% names(date_summary)) {
    date_summary <- date_summary[order(date_summary$date), ]
  }

  # Reorder columns to put departure and arrival date/time first as documented
  if (
    "departure_date" %in%
      names(date_summary) &&
      "departure_time" %in% names(date_summary)
  ) {
    # Define preferred column order
    priority_cols <- c("departure_date", "departure_time", "arrival_date", "arrival_time")
    existing_priority <- intersect(priority_cols, names(date_summary))
    other_cols <- setdiff(names(date_summary), priority_cols)
    date_summary <- date_summary[, c(existing_priority, other_cols)]
  }

  rownames(date_summary) <- NULL

  return(date_summary)
}
