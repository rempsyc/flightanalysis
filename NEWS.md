# flightanalysis (development version)

## New Features

* Added `fa_create_date_range_scrape()` function for creating flexible date range Scrape objects. This function:
  - Creates chain-trip Scrape objects from origin airports and date range
  - For single origin: returns one Scrape object
  - For multiple origins: returns a named list of Scrape objects (one per origin)
  - Generates all date permutations without scraping (use with `ScrapeObjects()`)
  - Parameter `origin` (not `airports`) for consistency with original Python package
  - Each origin gets its own Scrape object to satisfy chain-trip's strictly increasing date requirement

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
