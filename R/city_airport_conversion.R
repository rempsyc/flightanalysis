# List of excluded airport codes that are not used by Google Flights
# Maintainers can easily add codes here to filter them out from city lookups
# Example: "CXH" is Vancouver Harbour Flight Centre (seaplane terminal)
excluded_airports <- c("CXH")

#' Convert Airport Codes to City Names
#'
#' @description
#' Converts IATA airport codes to city names using the airportr package.
#' Falls back to the provided fallback value if conversion fails or package is not available.
#'
#' @param airport_codes Character vector of IATA airport codes
#' @param fallback Character vector of fallback values (same length as airport_codes).
#'   Default is the original airport_codes.
#'
#' @return Character vector of city names
#'
#' @export
#'
#' @examples
#' airport_to_city("JFK")
#' airport_to_city(c("JFK", "LGA", "EWR"))
airport_to_city <- function(airport_codes, fallback = airport_codes) {
  result <- tryCatch(
    {
      ap <- airportr::airports
      key <- ap$IATA
      val <- ap$City

      # Direct IATA code lookup
      out <- val[match(airport_codes, key)]

      ifelse(is.na(out) | out == "", fallback, out)
    },
    error = function(e) {
      fallback
    }
  )
  return(result)
}

#' Convert City Names to Airport Codes
#'
#' @description
#' Converts full city names to 3-letter IATA airport codes using the airportr package.
#' Returns all valid matching airport codes for cities with multiple airports.
#' Automatically filters out heliports and excluded airports (those not used by
#' Google Flights) to return only commercial airports.
#' Throws an error if a city name is not found in the database.
#'
#' @param city_names Character vector of city names
#'
#' @return Character vector of 3-letter IATA airport codes. For cities with multiple
#'   airports, all valid codes are returned (e.g., "New York" returns c("LGA", "JFK")).
#'   Heliports, excluded airports, and invalid codes are automatically filtered out.
#'
#' @export
#'
#' @examples
#' city_name_to_code("New York")
#' city_name_to_code(c("New York", "London"))
city_name_to_code <- function(city_names) {
  result <- tryCatch(
    {
      ap <- airportr::airports
      ap$City <- ifelse(ap$City == "Patina", "Patna", ap$City)
      ap$City <- ifelse(ap$IATA == "EWR", "New York", ap$City)

      all_codes <- list()
      for (i in seq_along(city_names)) {
        # Try exact match first (case-insensitive)
        city_matches <- which(tolower(ap$City) == tolower(city_names[i]))

        if (length(city_matches) > 0) {
          # Get matching rows
          matched_airports <- ap[city_matches, ]

          # Get IATA codes
          codes <- matched_airports$IATA
          names <- matched_airports$Name

          # Filter out invalid codes (like \\N, NA, empty strings)
          valid_idx <- !is.na(codes) &
            codes != "" &
            codes != "\\N" &
            nchar(codes) == 3
          codes <- codes[valid_idx]
          names <- names[valid_idx]

          # Filter out heliports (check if "Heliport" is in the name)
          not_heliport <- !grepl("heliport", tolower(names), fixed = TRUE)
          codes <- codes[not_heliport]

          # Filter out excluded airports (not used by Google Flights)
          codes <- codes[!codes %in% excluded_airports]

          if (length(codes) > 0) {
            all_codes[[i]] <- codes
          } else {
            # No valid codes found
            stop(sprintf(
              "City name '%s' found but has no valid airport codes in database. Please use a 3-letter airport or city code instead.",
              city_names[i]
            ))
          }
        } else {
          # No match found - throw error
          stop(sprintf(
            "City name '%s' not found in airport database. Please verify spelling or use a 3-letter airport or city code instead.",
            city_names[i]
          ))
        }
      }

      # Flatten the list to a vector
      unlist(all_codes)
    },
    error = function(e) {
      # Re-throw the error to propagate it
      stop(e$message, call. = FALSE)
    }
  )
  return(result)
}

#' Get Metropolitan Area Code for City Name
#'
#' @description
#' Internal function to check if a city name has a corresponding metropolitan area code
#' (e.g., "New York" -> "NYC", "London" -> "LON"). These codes are used by airlines
#' and Google Flights to represent all airports in a metropolitan area.
#'
#' @param city_name Character string of a city name
#'
#' @return Metropolitan area code if it exists, NULL otherwise
#'
#' @keywords internal
get_metropolitan_code <- function(city_name) {
  # Common metropolitan area codes used by airlines and Google Flights
  metro_codes <- list(
    # North America
    "new york" = "NYC",
    "washington" = "WAS",
    "chicago" = "CHI",
    "los angeles" = "LAX",
    "san francisco" = "SFO",
    "miami" = "MIA",
    "houston" = "HOU",
    "dallas" = "DFW",
    "atlanta" = "ATL",
    "boston" = "BOS",
    "seattle" = "SEA",
    "detroit" = "DTT",
    "philadelphia" = "PHL",
    "toronto" = "YTO",
    "montreal" = "YMQ",

    # Europe
    "london" = "LON",
    "paris" = "PAR",
    "berlin" = "BER",
    "rome" = "ROM",
    "milan" = "MIL",
    "madrid" = "MAD",
    "barcelona" = "BCN",
    "moscow" = "MOW",
    "stockholm" = "STO",
    "oslo" = "OSL",
    "amsterdam" = "AMS",
    "brussels" = "BRU",
    "dublin" = "DUB",
    "copenhagen" = "CPH",
    "vienna" = "VIE",
    "athens" = "ATH",
    "lisbon" = "LIS",
    "istanbul" = "IST",
    "budapest" = "BUD",
    "prague" = "PRG",
    "warsaw" = "WAW",

    # Asia
    "tokyo" = "TYO",
    "beijing" = "BJS",
    "shanghai" = "SHA",
    "hong kong" = "HKG",
    "singapore" = "SIN",
    "seoul" = "SEL",
    "bangkok" = "BKK",
    "jakarta" = "JKT",
    "manila" = "MNL",
    "taipei" = "TPE",
    "osaka" = "OSA",
    "delhi" = "DEL",
    "mumbai" = "BOM",
    "dubai" = "DXB",
    "tel aviv" = "TLV",
    "doha" = "DOH",
    "kuala lumpur" = "KUL",

    # South America
    "buenos aires" = "BUE",
    "rio de janeiro" = "RIO",
    "sao paulo" = "SAO",
    "santiago" = "SCL",
    "lima" = "LIM",
    "bogota" = "BOG",

    # Africa & Middle East
    "cairo" = "CAI",
    "johannesburg" = "JNB",
    "cape town" = "CPT",
    "casablanca" = "CAS",

    # Oceania
    "sydney" = "SYD",
    "melbourne" = "MEL",
    "auckland" = "AKL"
  )

  city_lower <- tolower(trimws(city_name))
  metro_code <- metro_codes[[city_lower]]

  return(metro_code)
}

#' Normalize Location Codes
#'
#' @description
#' Internal function to normalize a mix of airport codes, city codes, and full city names
#' to standardized 3-letter codes. Automatically converts full city names to metropolitan
#' area codes when available (unless expand_cities=TRUE), otherwise to individual airport codes.
#'
#' @param locations Character vector of mixed airport codes, city codes, and city names
#' @param expand_cities Logical. If TRUE, expands city names to all individual airports.
#'   If FALSE (default), uses metropolitan area codes when available.
#'
#' @return Character vector of 3-letter codes with duplicates removed
#'
#' @keywords internal
normalize_location_codes <- function(locations, expand_cities = FALSE) {
  if (is.null(locations) || length(locations) == 0) {
    return(NULL)
  }

  normalized <- character()

  for (loc in locations) {
    # If it's already a 3-letter code, use it as-is
    if (nchar(loc) == 3) {
      normalized <- c(normalized, loc)
    } else {
      # Check if there's a metropolitan area code for this city
      metro_code <- get_metropolitan_code(loc)

      if (!is.null(metro_code) && !expand_cities) {
        # Use the metropolitan area code
        normalized <- c(normalized, metro_code)
      } else {
        # Try to convert from city name to airport codes
        codes <- city_name_to_code(loc)
        normalized <- c(normalized, codes)
      }
    }
  }

  # Remove duplicates and return
  unique(normalized)
}
