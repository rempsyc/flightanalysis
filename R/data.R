#' Sample Flight Query
#'
#' @description
#' A sample flight query object created with `fa_define_query()`.
#' Useful for testing and documentation examples without making API calls.
#'
#' @format A flight_query object for JFK to IST round-trip
#' \describe{
#'   \item{origin}{List of origin airport codes}
#'   \item{dest}{List of destination airport codes}
#'   \item{dates}{List of travel dates}
#'   \item{type}{Trip type (round-trip)}
#'   \item{url}{Google Flights URLs}
#' }
#'
#' @examples
#' data(sample_query)
#' str(sample_query)
#' print(sample_query)
"sample_query"

#' Sample Flight Data
#'
#' @description
#' Sample flight data for testing analysis functions
#' like `fa_find_best_dates()` and `fa_summarize_prices()` without internet access.
#'
#' @format A data frame with 6 rows and 12 variables:
#' \describe{
#'   \item{departure_datetime}{POSIXct departure date and time}
#'   \item{arrival_datetime}{POSIXct arrival date and time}
#'   \item{origin}{Character, 3-letter origin airport code}
#'   \item{destination}{Character, 3-letter destination airport code}
#'   \item{airlines}{Character, airline name(s)}
#'   \item{travel_time}{Character, total travel time}
#'   \item{price}{Numeric, ticket price in USD}
#'   \item{num_stops}{Integer, number of stops}
#'   \item{layover}{Character, layover details (NA if nonstop)}
#'   \item{access_date}{POSIXct, when data was accessed}
#'   \item{co2_emission_kg}{Numeric, CO2 emissions in kg}
#'   \item{emission_diff_pct}{Numeric, emission difference percentage}
#' }
#'
#' @examples
#' data(sample_flights)
#' head(sample_flights)
#' # Use with analysis functions by attaching to a query object
#' \dontrun{
#' data(sample_query)
#' sample_query$data <- sample_flights
#' fa_find_best_dates(sample_query, n = 3)
#' fa_summarize_prices(sample_query)
#' }
"sample_flights"

#' Sample Multiple Origin Queries
#'
#' @description
#' Sample query objects for multiple origins created with `fa_define_query_range()`.
#' Demonstrates searching multiple airports over a date range.
#'
#' @format A named list of 2 flight_query objects (BOM and DEL to JFK)
#' \describe{
#'   \item{BOM}{query object for Mumbai (BOM) to JFK}
#'   \item{DEL}{query object for Delhi (DEL) to JFK}
#' }
#'
#' @examples
#' data(sample_multi_origin)
#' names(sample_multi_origin)
#' print(sample_multi_origin$BOM)
"sample_multi_origin"
