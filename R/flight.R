#' Flight Class
#'
#' @description
#' Creates a Flight object that represents a single flight with all its details.
#'
#' @param date Character string representing the flight date in format "YYYY-MM-DD"
#' @param ... Additional arguments containing flight details
#'
#' @return A Flight object (S3 class)
#' @export
#'
#' @examples
#' \dontrun{
#' flight <- Flight("2025-12-25", "JFKIST", "9:00AM", "5:00PM+1",
#'                  "8 hr 0 min", "Nonstop", "150 kg CO2", "10% emissions", "$450")
#' }
Flight <- function(date, ...) {
  args <- list(...)

  # Initialize Flight object
  flight <- list(
    id = 1,
    origin = NULL,
    dest = NULL,
    date = date,
    dow = as.integer(format(as.Date(date, "%Y-%m-%d"), "%u")), # day of week
    airline = NULL,
    flight_time = NULL,
    num_stops = NULL,
    stops = NULL,
    co2 = NULL,
    emissions = NULL,
    price = NULL,
    times = list(),
    time_leave = NULL,
    time_arrive = NULL,
    trash = list()
  )

  # Parse arguments
  flight <- parse_args(flight, args)

  class(flight) <- "Flight"
  return(flight)
}

#' Parse Flight Arguments
#'
#' @param flight Flight object being constructed
#' @param args List of arguments to parse
#' @keywords internal
parse_args <- function(flight, args) {
  for (arg in args) {
    flight <- classify_arg(flight, arg)
  }
  return(flight)
}

#' Classify Flight Argument
#'
#' @param flight Flight object being constructed
#' @param arg Argument to classify
#' @keywords internal
classify_arg <- function(flight, arg) {
  # Check for arrival or departure time
  # Support both uppercase (AM/PM) and lowercase (am/pm) formats
  if (
    (grepl("AM", arg, ignore.case = TRUE) || grepl("PM", arg, ignore.case = TRUE)) &&
      length(flight$times) < 2 &&
      grepl(":", arg)
  ) {
    delta_days <- 0
    if (substr(arg, nchar(arg) - 1, nchar(arg) - 1) == "+") {
      delta_days <- as.integer(substr(arg, nchar(arg), nchar(arg)))
      arg <- substr(arg, 1, nchar(arg) - 2)
    }

    datetime_str <- paste(flight$date, arg)
    # Try multiple time format patterns
    parsed_time <- tryCatch(
      {
        # Try uppercase AM/PM first
        strptime(datetime_str, "%Y-%m-%d %I:%M%p")
      },
      error = function(e) NULL
    )
    
    # If that fails, try lowercase am/pm
    if (is.null(parsed_time) || is.na(parsed_time)) {
      parsed_time <- tryCatch(
        {
          # Convert to uppercase for parsing
          datetime_str_upper <- gsub("am", "AM", gsub("pm", "PM", datetime_str, ignore.case = TRUE), ignore.case = TRUE)
          strptime(datetime_str_upper, "%Y-%m-%d %I:%M%p")
        },
        error = function(e) NULL
      )
    }
    
    # If we successfully parsed a time, add it
    if (!is.null(parsed_time) && !is.na(parsed_time)) {
      parsed_time <- as.POSIXct(parsed_time) + (delta_days * 24 * 3600)
      flight$times <- c(flight$times, list(parsed_time))
    }
  } else if (
    (grepl("hr", arg) || grepl("min", arg)) && is.null(flight$flight_time)
  ) {
    # Check for flight time
    flight$flight_time <- arg
  } else if (grepl("stop", arg) && is.null(flight$num_stops)) {
    # Check for number of stops
    flight$num_stops <- if (arg == "Nonstop") {
      0
    } else {
      as.integer(strsplit(arg, " ")[[1]][1])
    }
  } else if (grepl("kg CO2e?$", arg) && is.null(flight$co2)) {
    # Check for CO2 (matches both "kg CO2" and "kg CO2e")
    flight$co2 <- as.integer(strsplit(arg, " ")[[1]][1])
  } else if (grepl("emissions$", arg) && is.null(flight$emissions)) {
    # Check for emissions
    emission_val <- strsplit(arg, " ")[[1]][1]
    flight$emissions <- if (emission_val == "Avg") {
      0
    } else {
      as.integer(gsub("%", "", emission_val))
    }
  } else if (grepl("\\$", arg) && is.null(flight$price)) {
    # Check for price with dollar sign
    flight$price <- as.integer(gsub("[\\$,]", "", arg))
  } else if (
    grepl("^[0-9,]+$", arg) &&
      is.null(flight$price) &&
      !is.null(flight$flight_time)
  ) {
    # Check for price without dollar sign (but only if flight time already parsed)
    # This helps ensure we're getting the price field, not some other number
    flight$price <- as.integer(gsub(",", "", arg))
  } else if (
    nchar(arg) == 6 &&
      arg == toupper(arg) &&
      is.null(flight$origin) &&
      is.null(flight$dest)
  ) {
    # Check for origin/destination
    flight$origin <- substr(arg, 1, 3)
    flight$dest <- substr(arg, 4, 6)
  } else if (
    (grepl("hr", arg) && grepl("[A-Z]{3}$", arg)) ||
      (length(strsplit(arg, ", ")[[1]]) > 1 && arg == toupper(arg))
  ) {
    # Check for stops with time
    flight$stops <- arg
  } else if (
    nchar(arg) > 0 &&
      arg != "Separate tickets booked together" &&
      arg != "Change of airport" &&
      !grepl("CO2e?", arg) &&
      !grepl("trees? absorb", arg) &&
      !grepl("Other flights?", arg) &&
      !grepl("Avoids", arg)
  ) {
    # Check for airline (but filter out CO2-related text and "Other flights")
    val <- strsplit(arg, ",")[[1]]
    val <- sapply(val, function(elem) strsplit(elem, "Operated")[[1]][1])
    flight$airline <- paste(val, collapse = ",")
  } else {
    flight$trash <- c(flight$trash, list(arg))
  }

  # Set time_leave and time_arrive if we have both times
  if (length(flight$times) == 2) {
    flight$time_leave <- flight$times[[1]]
    flight$time_arrive <- flight$times[[2]]
  }

  return(flight)
}

#' Print method for Flight objects
#' @param x A Flight object
#' @param ... Additional arguments (ignored)
#' @export
print.Flight <- function(x, ...) {
  cat(sprintf("Flight(id:%d, %s-->%s on %s)\n", x$id, x$origin, x$dest, x$date))
  invisible(x)
}

#' Convert Flight objects to data frame
#'
#' @description
#' Converts a list of Flight objects into a data frame.
#'
#' @param flights List of Flight objects
#'
#' @return A data frame with flight information
#' @export
#'
#' @examples
#' \dontrun{
#' flight1 <- Flight("2025-12-25", "JFKIST", "$450", "Nonstop")
#' flight2 <- Flight("2025-12-26", "ISTCDG", "$300", "1 stop")
#' flight3 <- Flight("2025-12-27", "CDGJFK", "$500", "Nonstop")
#' flights <- list(flight1, flight2, flight3)
#' df <- flights_to_dataframe(flights)
#' }
flights_to_dataframe <- function(flights) {
  data <- data.frame(
    departure_datetime = character(),
    arrival_datetime = character(),
    origin = character(),
    destination = character(),
    airlines = character(),
    travel_time = character(),
    price = integer(),
    num_stops = integer(),
    layover = character(),
    access_date = character(),
    co2_emission_kg = integer(),
    emission_diff_pct = integer(),
    stringsAsFactors = FALSE
  )

  for (flight in flights) {
    row <- data.frame(
      departure_datetime = if (!is.null(flight$time_leave)) {
        format(flight$time_leave, "%Y-%m-%d %H:%M:%S")
      } else {
        NA
      },
      arrival_datetime = if (!is.null(flight$time_arrive)) {
        format(flight$time_arrive, "%Y-%m-%d %H:%M:%S")
      } else {
        NA
      },
      origin = ifelse(is.null(flight$origin), NA, flight$origin),
      destination = ifelse(is.null(flight$dest), NA, flight$dest),
      airlines = ifelse(is.null(flight$airline), NA, flight$airline),
      travel_time = ifelse(is.null(flight$flight_time), NA, flight$flight_time),
      price = ifelse(is.null(flight$price), NA, flight$price),
      num_stops = ifelse(is.null(flight$num_stops), NA, flight$num_stops),
      layover = ifelse(is.null(flight$stops), NA, flight$stops),
      access_date = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      co2_emission_kg = ifelse(is.null(flight$co2), NA, flight$co2),
      emission_diff_pct = ifelse(
        is.null(flight$emissions),
        NA,
        flight$emissions
      ),
      stringsAsFactors = FALSE
    )
    data <- rbind(data, row)
  }

  return(data)
}
