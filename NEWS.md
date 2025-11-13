# flightanalysis 2.0.0

## Major API Redesign

This release represents a complete redesign of the package API following Tidyverse conventions with consistent `fa_` prefixing for all user-facing functions.

### Core Functions

**Query Creation:**
- `fa_define_query()` - Create flight query objects for one-way, round-trip, chain-trip, or perfect-chain searches
- `fa_create_date_range()` - Create query objects for multiple origins and dates

**Data Fetching:**
- `fa_fetch_flights()` - Fetch flight data from Google Flights using chromote

**Analysis Functions:**
- `fa_summarize_prices()` - Create wide summary table showing prices by city/airport and date
- `fa_find_best_dates()` - Identify cheapest travel dates across routes

### Example Usage

```r
library(flightanalysis)

# Create a query
query <- fa_define_query("JFK", "IST", "2025-12-20", "2025-12-27")

# Fetch flight data
result <- fa_fetch_flights(query)

# Analyze results
summary <- fa_summarize_prices(result)
best <- fa_find_best_dates(result, n = 5)
```

### Date Range Search

```r
# Search multiple origins over a date range
queries <- fa_create_date_range(
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

### Internal Functions

The following functions are internal and not exported:
- `Flight()` - Used internally for parsing scraped data
- `flights_to_dataframe()` - Converts flight objects to data frames

### Package Organization

* Functions organized by purpose:
  - `fa_create_date_range.R` - Date range query creation
  - `fa_summarize_prices.R` - Price summary tables
  - `fa_find_best_dates.R` - Best date identification
  - `filter_placeholder_rows.R` - Data cleaning helpers
  - `scrape.R` - Core query and fetching functionality

* Comprehensive examples in `examples/` directory
* Full test coverage in `tests/testthat/`
* Suggested dependencies: `chromote`, `scales`, `tibble`, `progress`

# flightanalysis 1.0.0

* Initial CRAN-ready release
* Full R package implementation with chromote-based scraping
* Support for one-way, round-trip, chain-trip, and perfect-chain queries
* Driver-free browser automation using Chrome DevTools Protocol
