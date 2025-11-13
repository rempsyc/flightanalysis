# flightanalysis (development version)

## Major API Redesign (v2.0)

This release includes a comprehensive API redesign to follow Tidyverse style guidelines with verb-based, descriptive function names.

### Breaking Changes (with deprecation support)

**Core Function Renames:**
- `Scrape()` → `define_query()` - Create flight query objects
- `ScrapeObjects()` / `scrape_objects()` → `fetch_flights()` - Fetch flight data from Google
- `fa_create_date_range_scrape()` → `create_date_range()` - Create date range queries

**Internal Changes:**
- `Flight()` is now internal (not exported) - only used internally for parsing
- `flights_to_dataframe()` is now internal - only used by fetch_flights()
- S3 class renamed: `Scrape` → `flight_query` (backward compatible)

**All old function names remain available as deprecated aliases** with warnings to guide users to the new API. Both old and new class names are supported.

### New API Examples

```r
# Old way
scrape <- Scrape("JFK", "IST", "2025-12-20")
scrape <- scrape_objects(scrape)

# New way
query <- define_query("JFK", "IST", "2025-12-20")
result <- fetch_flights(query)

# Old way
scrapes <- fa_create_date_range_scrape(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")

# New way
queries <- create_date_range(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
```

### Migration Guide

1. Replace `Scrape()` with `define_query()`
2. Replace `ScrapeObjects()` or `scrape_objects()` with `fetch_flights()`
3. Replace `fa_create_date_range_scrape()` with `create_date_range()`
4. Remove direct use of `Flight()` (it's internal now)
5. Remove direct use of `flights_to_dataframe()` (it's internal now)

All existing code will continue to work with deprecation warnings.

## Previous Changes

### Minor Improvements from v1.0.2

* Added `fa_create_date_range_scrape()` function for creating flexible date range Scrape objects. This function:
  - Creates chain-trip Scrape objects from origin airports and date range
  - For single origin: returns one Scrape object
  - For multiple origins: returns a named list of Scrape objects (one per origin)
  - Generates all date permutations without scraping (use with `scrape_objects()`)
  - Parameter `origin` (not `airports`) for consistency with original Python package
  - Each origin gets its own Scrape object to satisfy chain-trip's strictly increasing date requirement

* Added `fa_flex_table()` function for creating wide summary tables. This function:
  - Accepts data frames, single Scrape objects, or lists of Scrape objects
  - Automatically extracts and processes data from Scrape objects
  - Reshapes results into City × Date format
  - Calculates average prices across dates
  - Optionally includes comment column from routes
  - Formats prices with currency symbols
  - Sorts date columns chronologically

* Added `fa_best_dates()` function for identifying cheapest travel dates. This function:
  - Accepts data frames, single Scrape objects, or lists of Scrape objects
  - Automatically extracts and processes data from Scrape objects
  - Aggregates prices by date using mean, median, or min
  - Returns top N cheapest dates
  - Includes route count per date
  - Sorts results by price (cheapest first)

## Minor Improvements

* Added internal `filter_placeholder_rows()` helper function
* Added internal `extract_data_from_scrapes()` helper function for processing Scrape objects
* Updated package documentation to describe new flexible date search features
* Split functions into separate files for better organization (fa_create_date_range_scrape.R, fa_flex_table.R, fa_best_dates.R, filter_placeholder_rows.R)
* Added comprehensive examples in `examples/flexible_date_search.R`
* Added test coverage for new functions in `tests/testthat/test-flex_search.R`
* Added `scales` and `tibble` to suggested dependencies

# flightanalysis 1.0.0

* Initial CRAN-ready release
* Full R package implementation with chromote-based scraping
* Support for one-way, round-trip, chain-trip, and perfect-chain queries
* Driver-free browser automation using Chrome DevTools Protocol
