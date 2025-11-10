# flightanalysis (development version)

## New Features

* Added `fa_scrape_best_oneway()` function for scraping cheapest flights across multiple dates and airports. This function:
  - Searches all combinations of routes and dates
  - Returns only the cheapest offer per day (or all offers with `keep_offers=TRUE`)
  - Includes built-in rate limiting via `pause` parameter
  - Filters out placeholder rows like "Price graph" and "Price unavailable"
  - Supports verbose progress reporting

* Added `fa_flex_table()` function for creating wide summary tables. This function:
  - Reshapes results into City × Date format
  - Calculates average prices across dates
  - Optionally includes comment column from routes
  - Formats prices with currency symbols
  - Sorts date columns chronologically

* Added `fa_best_dates()` function for identifying cheapest travel dates. This function:
  - Aggregates prices by date using mean, median, or min
  - Returns top N cheapest dates
  - Includes route count per date
  - Sorts results by price (cheapest first)

## Minor Improvements

* Added internal `filter_placeholder_rows()` helper function
* Updated package documentation to describe new flexible date search features
* Added comprehensive examples in `examples/flexible_date_search.R`
* Added test coverage for new functions in `tests/testthat/test-flex_search.R`
* Added `scales` and `tibble` to suggested dependencies

# flightanalysis 1.0.0

* Initial CRAN-ready release
* Full R package implementation with chromote-based scraping
* Support for one-way, round-trip, chain-trip, and perfect-chain queries
* Driver-free browser automation using Chrome DevTools Protocol
