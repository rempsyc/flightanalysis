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
#' @param flight_results A single query object, a flight_results object, or a named list of query objects
#'
#' @return A data frame with columns: Airport, Date, Price, City (if named list),
#'   and additional columns: departure_datetime, airlines, travel_time, num_stops,
#'   layover, co2_emission_kg (when available)
#'
#' @keywords internal
extract_data_from_scrapes <- function(flight_results) {
  # Handle flight_results objects - use the merged data directly
  if (inherits(flight_results, "flight_results")) {
    # Use the merged data directly from flight_results$data
    if (!is.null(flight_results$data) && nrow(flight_results$data) > 0) {
      data <- flight_results$data
      
      # Filter placeholder rows
      data <- filter_placeholder_rows(data)
      
      if (nrow(data) == 0) {
        return(data.frame(
          City = character(),
          Airport = character(),
          Date = character(),
          Price = numeric(),
          departure_datetime = as.POSIXct(character()),
          airlines = character(),
          travel_time = character(),
          num_stops = integer(),
          layover = character(),
          co2_emission_kg = numeric(),
          stringsAsFactors = FALSE
        ))
      }
      
      # Process the data - city_name will be derived from origin column
      return(process_query_data(data, city_name = NULL))
    } else {
      return(data.frame(
        City = character(),
        Airport = character(),
        Date = character(),
        Price = numeric(),
        departure_datetime = as.POSIXct(character()),
        airlines = character(),
        travel_time = character(),
        num_stops = integer(),
        layover = character(),
        co2_emission_kg = numeric(),
        stringsAsFactors = FALSE
      ))
    }
  }

  # Ensure we have a list
  if (inherits(flight_results, "flight_query")) {
    # For single query object, try to extract origin from the data
    # This ensures we have a named list for proper City assignment
    if (
      !is.null(flight_results$data) &&
        nrow(flight_results$data) > 0 &&
        "origin" %in% names(flight_results$data)
    ) {
      origin_code <- flight_results$data$origin[1]
      flight_results <- list(flight_results)
      names(flight_results) <- origin_code
    } else {
      flight_results <- list(flight_results)
    }
  }

  all_data <- list()

  for (i in seq_along(flight_results)) {
    query <- flight_results[[i]]

    # Extract data
    if (is.null(query$data) || nrow(query$data) == 0) {
      next
    }

    data <- query$data

    # Filter placeholder rows
    data <- filter_placeholder_rows(data)

    if (nrow(data) == 0) {
      next
    }

    # Get city name from list name if available
    city_name <- if (!is.null(names(flight_results)[i])) names(flight_results)[i] else NULL
    
    # Process the data
    all_data[[i]] <- process_query_data(data, city_name)
  }

  if (length(all_data) == 0) {
    return(data.frame(
      City = character(),
      Airport = character(),
      Date = character(),
      Price = numeric(),
      departure_datetime = as.POSIXct(character()),
      airlines = character(),
      travel_time = character(),
      num_stops = integer(),
      layover = character(),
      co2_emission_kg = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  # Combine all data
  combined <- do.call(rbind, all_data)
  rownames(combined) <- NULL

  return(combined)
}

#' Process Query Data
#'
#' @description
#' Internal helper that processes a single query's data frame, extracting and
#' standardizing columns for use with fa_summarize_prices and fa_find_best_dates.
#'
#' @param data A data frame from a flight query
#' @param city_name Optional city name to use
#'
#' @return A processed data frame with standardized columns
#'
#' @keywords internal
process_query_data <- function(data, city_name = NULL) {
  # Extract relevant columns
  # Use origin as the Airport (the airport we're searching FROM)
  if ("origin" %in% names(data)) {
    data$Airport <- data$origin
  } else if ("destination" %in% names(data)) {
    data$Airport <- data$destination
  } else {
    data$Airport <- NA_character_
  }

  if ("departure_date" %in% names(data)) {
    data$Date <- data$departure_date
  } else if ("departure_datetime" %in% names(data)) {
    # Backward compatibility for old format
    data$Date <- as.character(as.Date(data$departure_datetime))
  } else {
    data$Date <- NA_character_
  }

  if ("price" %in% names(data)) {
    data$Price <- data$price
  } else {
    data$Price <- NA_real_
  }

  # Add City from provided name or look up from airport code
  if (!is.null(city_name) && !is.na(city_name)) {
    data$City <- city_name
  } else {
    data$City <- data$Airport
  }

  # Try to convert airport codes to city names using airportr if available
  data$City <- airport_to_city(data$Airport, data$City)
  data$City <- ifelse(data$City == "Patina", "Patna", data$City)

  # Preserve additional columns if they exist
  additional_cols <- c()

  if (
    "departure_date" %in% names(data) && "departure_time" %in% names(data)
  ) {
    additional_cols <- c(additional_cols, "departure_date", "departure_time")
  } else if ("departure_datetime" %in% names(data)) {
    # Backward compatibility for old format
    additional_cols <- c(additional_cols, "departure_datetime")
  }

  if ("arrival_date" %in% names(data) && "arrival_time" %in% names(data)) {
    additional_cols <- c(additional_cols, "arrival_date", "arrival_time")
  } else if ("arrival_datetime" %in% names(data)) {
    # Backward compatibility for old format
    additional_cols <- c(additional_cols, "arrival_datetime")
  }

  if ("airlines" %in% names(data)) {
    additional_cols <- c(additional_cols, "airlines")
  }

  if ("travel_time" %in% names(data)) {
    additional_cols <- c(additional_cols, "travel_time")
  }

  if ("num_stops" %in% names(data)) {
    additional_cols <- c(additional_cols, "num_stops")
  }

  if ("layover" %in% names(data)) {
    additional_cols <- c(additional_cols, "layover")
  }

  if ("co2_emission_kg" %in% names(data)) {
    additional_cols <- c(additional_cols, "co2_emission_kg")
  }

  # Select needed columns (always include base columns, plus any additional ones available)
  base_cols <- c("City", "Airport", "Date", "Price")
  data <- data[, c(base_cols, additional_cols), drop = FALSE]

  return(data)
}

#' Parse Time Duration to Minutes
#'
#' @description
#' Internal helper function to parse time duration strings or numeric values to minutes.
#' Handles both numeric (hours) and character ("XX hr XX min") formats.
#'
#' @param time_value Numeric or character. If numeric, interpreted as hours.
#'   If character, parsed as "XX hr XX min" format.
#'
#' @return Numeric value in minutes
#'
#' @keywords internal
parse_time_to_minutes <- function(time_value) {
  # Handle NA and "NA" string values
  if (is.na(time_value) || (is.character(time_value) && time_value == "NA")) {
    return(NA_real_)
  }

  if (is.numeric(time_value)) {
    # If numeric, interpret as hours and convert to minutes
    return(time_value * 60)
  } else if (is.character(time_value)) {
    # Handle empty strings
    if (time_value == "" || nchar(trimws(time_value)) == 0) {
      return(NA_real_)
    }

    # If character, parse the format "XX hr XX min", "XX hr", or "XX min"
    parts <- strsplit(time_value, " ")[[1]]
    hours <- 0
    minutes <- 0

    if (length(parts) >= 2 && parts[2] == "hr") {
      hours_val <- suppressWarnings(as.numeric(parts[1]))
      if (is.na(hours_val)) {
        stop(
          "Invalid time format: unable to parse hours from '",
          time_value,
          "'"
        )
      }
      hours <- hours_val
    }

    if (length(parts) >= 4 && parts[4] == "min") {
      minutes_val <- suppressWarnings(as.numeric(parts[3]))
      if (is.na(minutes_val)) {
        stop(
          "Invalid time format: unable to parse minutes from '",
          time_value,
          "'"
        )
      }
      minutes <- minutes_val
    } else if (length(parts) >= 2 && parts[2] == "min") {
      minutes_val <- suppressWarnings(as.numeric(parts[1]))
      if (is.na(minutes_val)) {
        stop(
          "Invalid time format: unable to parse minutes from '",
          time_value,
          "'"
        )
      }
      minutes <- minutes_val
    }

    return(hours * 60 + minutes)
  } else {
    stop(
      "time_value must be numeric (hours) or character (format: 'XX hr XX min')"
    )
  }
}
