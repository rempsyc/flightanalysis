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
#'   \item{\code{\link{define_query}}}{Create a flight query object}
#'   \item{\code{\link{fetch_flights}}}{Execute flight queries (requires chromote)}
#'   \item{\code{\link{create_date_range}}}{Create queries for flexible date search}
#'   \item{\code{\link{fa_flex_table}}}{Create wide summary table for price comparison}
#'   \item{\code{\link{fa_best_dates}}}{Identify cheapest travel dates}
#' }
#'
#' @section Deprecated Functions:
#' The following functions are deprecated but still available for backward compatibility:
#' \itemize{
#'   \item \code{Scrape()} - use \code{define_query()} instead
#'   \item \code{ScrapeObjects()} and \code{scrape_objects()} - use \code{fetch_flights()} instead
#'   \item \code{fa_create_date_range_scrape()} - use \code{create_date_range()} instead
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
