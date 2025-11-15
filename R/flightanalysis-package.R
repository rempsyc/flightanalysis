#' @keywords internal
"_PACKAGE"

# Suppress R CMD check notes for ggplot2 NSE variables
utils::globalVariables(c("price", "origin", "origin_label", "date", "rank", ".data"))

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
#'   \item{\code{\link{fa_define_query}}}{Create a flight query object}
#'   \item{\code{\link{fa_fetch_flights}}}{Execute flight queries (requires chromote)}
#'   \item{\code{\link{fa_define_query_range}}}{Create queries for flexible date search}
#'   \item{\code{\link{fa_summarize_prices}}}{Create wide summary table for price comparison}
#'   \item{\code{\link{fa_find_best_dates}}}{Identify cheapest travel dates}
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
