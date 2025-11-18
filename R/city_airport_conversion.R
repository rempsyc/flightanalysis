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
#' Throws an error if a city name is not found in the database.
#'
#' @param city_names Character vector of city names
#'
#' @return Character vector of 3-letter IATA airport codes. For cities with multiple
#'   airports, all valid codes are returned (e.g., "New York" returns c("JFK", "LGA", "EWR")).
#'   Invalid codes (like "\\N") are filtered out.
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
      
      all_codes <- list()
      for (i in seq_along(city_names)) {
        # Try exact match first (case-insensitive)
        city_matches <- which(tolower(ap$City) == tolower(city_names[i]))
        
        if (length(city_matches) > 0) {
          # Get all IATA codes for this city
          codes <- ap$IATA[city_matches]
          
          # Filter out invalid codes (like \\N, NA, empty strings)
          codes <- codes[!is.na(codes) & codes != "" & codes != "\\N" & nchar(codes) == 3]
          
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
            "City name '%s' not found in airport database. Please use a 3-letter airport or city code instead.",
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

#' Normalize Location Codes
#'
#' @description
#' Internal function to normalize a mix of airport codes, city codes, and full city names
#' to standardized 3-letter codes. Automatically converts full city names to all their
#' associated airport codes.
#'
#' @param locations Character vector of mixed airport codes, city codes, and city names
#'
#' @return Character vector of 3-letter codes with duplicates removed
#'
#' @keywords internal
normalize_location_codes <- function(locations) {
  if (is.null(locations) || length(locations) == 0) {
    return(NULL)
  }
  
  normalized <- character()
  
  for (loc in locations) {
    # If it's already a 3-letter code, use it as-is
    if (nchar(loc) == 3) {
      normalized <- c(normalized, loc)
    } else {
      # Try to convert from city name to airport codes
      codes <- city_name_to_code(loc)
      normalized <- c(normalized, codes)
    }
  }
  
  # Remove duplicates and return
  unique(normalized)
}
