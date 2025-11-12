#' @keywords internal
"_PACKAGE"

#' flightanalysis: Google Flight Analysis and Scraping
#'
#' @description
#' This package provides tools and models for users to analyze, forecast, and
#' collect data regarding flights and prices. Current features include:
#'
#' \itemize{
#'   \item Detailed scraping and querying tools for Google Flights
#'   \item Support for multiple trip types (one-way, round-trip, chain, perfect-chain)
#'   \item Flexible date search across multiple airports and date ranges
#'   \item Summary tables and best date identification for travel planning
#'   \item Base analytical tools/methods for price forecasting/summary
#' }
#'
#' @section Main Functions:
#' \describe{
#'   \item{\code{\link{Scrape}}}{Create a flight query object}
#'   \item{\code{\link{ScrapeObjects}}}{Execute flight queries (requires chromote)}
#'   \item{\code{\link{Flight}}}{Create a flight data object}
#'   \item{\code{\link{flights_to_dataframe}}}{Convert Flight objects to data frame}
#'   \item{\code{\link{fa_create_date_range_scrape}}}{Create Scrape objects for flexible date search}
#'   \item{\code{\link{fa_flex_table}}}{Create wide summary table for price comparison}
#'   \item{\code{\link{fa_best_dates}}}{Identify cheapest travel dates}
#' }
#'
#' @section Trip Types:
#' The package supports multiple trip types:
#' \itemize{
#'   \item \strong{One-way}: Single flight from origin to destination
#'   \item \strong{Round-trip}: Flight to destination and return
#'   \item \strong{Chain-trip}: Sequence of unrelated one-way flights
#'   \item \strong{Perfect-chain}: Sequence where each destination becomes the next origin
#' }
#'
#' @docType _PACKAGE
#' @name flightanalysis-package
NULL
