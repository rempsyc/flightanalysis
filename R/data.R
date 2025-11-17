#' @title Sample Flight Query
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
#' sample_query
#'
#' @title Sample Flight Data
#' @description
#' Sample flight data for testing analysis functions
#' like `fa_find_best_dates()` and `fa_summarize_prices()` without internet access.
#'
#' @format A data frame with 6 rows and 14 variables:
#' \describe{
#'   \item{departure_date}{Character, departure date (YYYY-MM-DD)}
#'   \item{departure_time}{Character, departure time (HH:MM)}
#'   \item{arrival_date}{Character, arrival date (YYYY-MM-DD)}
#'   \item{arrival_time}{Character, arrival time (HH:MM)}
#'   \item{origin}{Character, 3-letter origin airport code}
#'   \item{destination}{Character, 3-letter destination airport code}
#'   \item{airlines}{Character, airline name(s)}
#'   \item{travel_time}{Character, total travel time}
#'   \item{price}{Numeric, ticket price in USD}
#'   \item{num_stops}{Integer, number of stops}
#'   \item{layover}{Character, layover details (NA if nonstop)}
#'   \item{access_date}{Character, when data was accessed}
#'   \item{co2_emission_kg}{Numeric, CO2 emissions in kg}
#'   \item{emission_diff_pct}{Numeric, emission difference percentage}
#' }
#'
#' @examples
#' head(sample_flights)
#'
#' # Note: sample_flights is a data frame for demonstration purposes only.
#' # Analysis functions now require flight_results objects from fa_fetch_flights().
#' # Use sample_flight_results instead:
#' \dontrun{
#' fa_find_best_dates(sample_flight_results, n = 3)
#' fa_summarize_prices(sample_flight_results)
#' }
#'
#' @title Sample Multiple Origin Queries
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
#' sample_multi_origin
#'
#' @title Sample Flight Results Dataset
#' @description
#' A comprehensive sample dataset containing flight data from 5 Indian origins
#' (BOM, DEL, VNS, PAT, GAY) to JFK spanning from December 18, 2025 to January 5, 2026.
#' This dataset demonstrates realistic pricing patterns including a Christmas/New Year
#' price spike, making it ideal for testing and demonstrating flight analysis functions.
#'
#' @format A flight_results object (S3 class) with the following structure:
#' \describe{
#'   \item{data}{A data frame with 95 rows (5 origins × 19 days) containing:
#'     \itemize{
#'       \item \code{departure_date}: Character, departure date in "YYYY-MM-DD" format
#'       \item \code{departure_time}: Character, departure time in "HH:MM" format
#'       \item \code{arrival_date}: Character, arrival date in "YYYY-MM-DD" format
#'       \item \code{arrival_time}: Character, arrival time in "HH:MM" format
#'       \item \code{origin}: Character, origin airport code (BOM, DEL, VNS, PAT, GAY)
#'       \item \code{destination}: Character, destination airport code (JFK)
#'       \item \code{airlines}: Character, airline name
#'       \item \code{travel_time}: Character, total travel time in "XX hr YY min" format
#'       \item \code{price}: Numeric, ticket price in USD
#'       \item \code{num_stops}: Integer, number of stops (0-2)
#'       \item \code{layover}: Character, layover information (if applicable)
#'       \item \code{access_date}: Character, timestamp when data was accessed
#'       \item \code{co2_emission_kg}: Numeric, estimated CO2 emissions in kg
#'       \item \code{emission_diff_pct}: Numeric, emission difference percentage
#'     }
#'   }
#'   \item{BOM, DEL, VNS, PAT, GAY}{Query objects for each origin containing
#'     the data subset and query parameters}
#' }
#'
#' @details
#' The dataset features:
#' \itemize{
#'   \item Realistic travel times varying by origin (15.5-18.5 hours)
#'   \item Base prices varying by origin ($580-$700)
#'   \item Christmas/New Year price spike (Dec 23 - Jan 3) with 1.3x-4.5x multiplier
#'   \item Peak prices around January 1-2
#'   \item Weekend price adjustments (10\% increase)
#'   \item Random variation to simulate real-world data
#' }
#'
#' This dataset is particularly useful for:
#' \itemize{
#'   \item Demonstrating \code{\link{fa_plot_prices}} with seasonal patterns
#'   \item Testing \code{\link{fa_summarize_prices}} with multiple origins
#'   \item Showing \code{\link{fa_find_best_dates}} functionality
#'   \item Creating visually appealing examples with the size_by parameter
#' }
#'
#' @seealso
#' \code{\link{sample_flights}} for a simpler data frame example,
#' \code{\link{fa_plot_prices}} for plotting functions,
#' \code{\link{fa_summarize_prices}} for price summary tables
#'
#' @examples
#' # Load and examine the dataset
#' head(sample_flight_results$data)
#'
#' \dontrun{
#' # Plot with automatic Christmas spike visualization
#' fa_plot_prices(sample_flight_results)
#'
#' # Size points by travel time
#' fa_plot_prices(sample_flight_results, size_by = "travel_time")
#'
#' # Create price summary table
#' fa_summarize_prices(sample_flight_results)
#'
#' # Find best dates
#' fa_find_best_dates(sample_flight_results, n = 5)
#' }
#'
