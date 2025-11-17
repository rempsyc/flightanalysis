# Changelog

## flightanalysis 3.0.0 (Development)

### Breaking Changes

- **flight_results-only API**: All data processing functions
  ([`fa_summarize_prices()`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md),
  [`fa_plot_prices()`](https://rempsyc.github.io/flightanalysis/reference/fa_plot_prices.md),
  and
  [`fa_find_best_dates()`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md))
  now **only** accept `flight_results` objects returned from
  [`fa_fetch_flights()`](https://rempsyc.github.io/flightanalysis/reference/fa_fetch_flights.md).
  - Removed support for direct data frame input
  - Removed support for query object or list of query objects input
  - Users must use
    [`fa_fetch_flights()`](https://rempsyc.github.io/flightanalysis/reference/fa_fetch_flights.md)
    to create `flight_results` objects before using analysis functions
  - Clear error messages guide users to the correct workflow

### Rationale

This change simplifies the API by enforcing a consistent workflow: 1.
Create queries with
[`fa_define_query()`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query.md)
or
[`fa_define_query_range()`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query_range.md)
2. Fetch data with
[`fa_fetch_flights()`](https://rempsyc.github.io/flightanalysis/reference/fa_fetch_flights.md)
to get `flight_results` objects 3. Analyze data with processing
functions

## flightanalysis 2.1.0

### API Improvements

#### Breaking Changes

- **Function Rename**: `fa_create_date_range()` has been renamed to
  [`fa_define_query_range()`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query_range.md)
  for consistency with
  [`fa_define_query()`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query.md).
  The old function has been removed.

#### New Features

- **flight_results Class**: When fetching data for multiple queries
  (e.g., from
  [`fa_define_query_range()`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query_range.md)),
  [`fa_fetch_flights()`](https://rempsyc.github.io/flightanalysis/reference/fa_fetch_flights.md)
  now returns a `flight_results` object that:
  - Contains a merged `$data` field with all flight data accessible
    directly
  - Preserves individual query objects as named elements (e.g., `$BOM`,
    `$DEL`)
  - Has a dedicated print method for better display

#### Enhancements

- **Parameter Renaming**:
  [`fa_summarize_prices()`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md)
  and
  [`fa_find_best_dates()`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md)
  now use `flight_results` as the parameter name instead of `results`
  for clarity and type safety
- **Improved Documentation**: Updated all examples and documentation to
  use the new function names
- **Better Data Access**: No need to manually merge data from multiple
  origins - access unified data via `flights$data` directly

#### Example

``` r
# Create queries for multiple origins
queries <- fa_define_query_range(
  origin = c("BOM", "DEL"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2025-12-22"
)

# Fetch data - returns flight_results object with merged data
flights <- fa_fetch_flights(queries)

# Access merged data directly
flights$data

# Or access individual origin data
flights$BOM$data
flights$DEL$data

# Use with analysis functions
fa_summarize_prices(flights)
fa_find_best_dates(flights, n = 5)
```

## flightanalysis 2.0.0

### Major API Redesign

This release represents a complete redesign of the package API following
Tidyverse conventions with consistent `fa_` prefixing for all
user-facing functions.

#### Core Functions

**Query Creation:** -
[`fa_define_query()`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query.md) -
Create flight query objects for one-way, round-trip, chain-trip, or
perfect-chain searches -
[`fa_define_query_range()`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query_range.md) -
Create query objects for multiple origins and dates

**Data Fetching:** -
[`fa_fetch_flights()`](https://rempsyc.github.io/flightanalysis/reference/fa_fetch_flights.md) -
Fetch flight data from Google Flights using chromote

**Analysis Functions:** -
[`fa_summarize_prices()`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md) -
Create wide summary table showing prices by city/airport and date -
[`fa_find_best_dates()`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md) -
Identify cheapest travel dates across routes

#### Example Usage

``` r
library(flightanalysis)

# Create a query
query <- fa_define_query("JFK", "IST", "2025-12-20", "2025-12-27")

# Fetch flight data
result <- fa_fetch_flights(query)

# Analyze results
summary <- fa_summarize_prices(result)
best <- fa_find_best_dates(result, n = 5)
```

#### Date Range Search

``` r
# Search multiple origins over a date range
queries <- fa_define_query_range(
  origin = c("BOM", "DEL", "VNS"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2026-01-05"
)

# Fetch data for each origin
for (code in names(queries)) {
  queries[[code]] <- fa_fetch_flights(queries[[code]])
}

# Analyze all results
summary <- fa_summarize_prices(queries)
best_dates <- fa_find_best_dates(queries, n = 10, by = "mean")
```

#### Internal Functions

The following functions are internal and not exported: - `Flight()` -
Used internally for parsing scraped data -
[`flights_to_dataframe()`](https://rempsyc.github.io/flightanalysis/reference/flights_to_dataframe.md) -
Converts flight objects to data frames

#### Package Organization

- Functions organized by purpose:
  - `fa_define_query_range.R` - Date range query creation
  - `fa_summarize_prices.R` - Price summary tables
  - `fa_find_best_dates.R` - Best date identification
  - `filter_placeholder_rows.R` - Data cleaning helpers
  - `scrape.R` - Core query and fetching functionality
- Comprehensive examples in `examples/` directory
- Full test coverage in `tests/testthat/`
- Suggested dependencies: `chromote`, `progress`

## flightanalysis 1.0.0

- Initial CRAN-ready release
- Full R package implementation with chromote-based scraping
- Support for one-way, round-trip, chain-trip, and perfect-chain queries
- Driver-free browser automation using Chrome DevTools Protocol
