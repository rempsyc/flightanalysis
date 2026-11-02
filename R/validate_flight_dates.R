# Parse dates strictly: as.Date() alone can accept trailing text or short fields.
parse_flight_dates <- function(x, label = "Departure dates") {
  if (inherits(x, "Date")) {
    dates <- x
  } else if (is.character(x)) {
    dates <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
    valid <- !is.na(x) & grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x)
    valid <- valid & !is.na(dates) & format(dates, "%Y-%m-%d") == x
    if (!all(valid)) {
      stop(sprintf("%s must be valid dates in YYYY-MM-DD format (for example, 2026-12-20).", label),
           call. = FALSE)
    }
  } else {
    stop(sprintf("%s must be Date objects or character strings in YYYY-MM-DD format.", label),
         call. = FALSE)
  }
  if (!length(dates) || anyNA(dates) || any(!is.finite(as.numeric(dates)))) {
    stop(sprintf("%s must contain non-missing, valid dates in YYYY-MM-DD format.", label),
         call. = FALSE)
  }
  dates
}

# Google Flights accepted +330 days and rejected +331 in live probes on
# 2026-11-02. This is a search limit, not a guarantee of airline availability.
validate_flight_date_window <- function(dates, today = Sys.Date()) {
  dates <- parse_flight_dates(dates)
  last_date <- today + 330L
  invalid <- dates < today | dates > last_date
  if (any(invalid)) {
    stop(sprintf(
      paste0("Departure date %s is outside the Google Flights search window: %s through %s ",
             "(today through 330 days ahead, inclusive). Searches for past departure dates are unavailable; ",
             "later dates are too far in the future. Availability within this window varies by airline."),
      format(dates[which(invalid)[1]]), format(today), format(last_date)
    ), call. = FALSE)
  }
  invisible(dates)
}
