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
#'   \item Ability to store data locally or to SQL tables
#'   \item Base analytical tools/methods for price forecasting/summary
#' }
#'
#' @section Main Functions:
#' \describe{
#'   \item{\code{\link{Scrape}}}{Create a flight query object}
#'   \item{\code{\link{ScrapeObjects}}}{Execute flight queries (requires RSelenium)}
#'   \item{\code{\link{Flight}}}{Create a flight data object}
#'   \item{\code{\link{CacheControl}}}{Cache flight data to disk or database}
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
