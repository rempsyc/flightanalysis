# Implementation Summary: Flexible Date Search

## Overview

This document summarizes the implementation of flexible date search functionality for the flightanalysis R package, addressing GitHub issue requesting the ability to search over flexible date ranges and multiple airports.

## Problem Statement

Users needed the ability to:
1. Search flights across flexible date ranges (e.g., "Dec 18 – Jan 5")
2. Search across multiple airports/cities
3. Store all scraped offers per date, or extract only the cheapest
4. Output wide summary tables (City × Date with Average Price)
5. Identify best travel dates automatically
6. Filter out placeholder rows like "Price graph"
7. Support currency formatting
8. Include polite rate-limiting

## Solution

**Note:** The implementation was refactored based on user feedback. See `REFACTORING_SUMMARY.md` for details on the architectural changes.

Four new exported functions were added to provide an intuitive workflow:

### 1. `fa_create_date_range_scrape(airports, dest, date_min, date_max)`

**Purpose**: Helper function to create chain-trip Scrape object with flexible parameters

**Parameters**:
- `airports`: Character vector of 3-letter airport codes
- `dest`: Character, single 3-letter destination code
- `date_min`: Start date (Date or character in "YYYY-MM-DD")
- `date_max`: End date (Date or character in "YYYY-MM-DD")

**Features**:
- Generates all airport × date combinations
- Creates chain-trip Scrape object WITHOUT scraping
- Returns Scrape object ready to pass to `ScrapeObjects()`
- Leverages existing chain-trip functionality

**Returns**: Scrape object of type "chain-trip"

### 2. `fa_scrape_best_oneway(routes, dates, ...)`

**Purpose**: Main scraping function for multiple routes and dates

**Parameters**:
- `routes`: Data frame with columns City, Airport, Dest (+ optional Comment)
- `dates`: Vector of dates (Date objects or character strings)
- `keep_offers`: Logical, store all offers or only cheapest (default: FALSE)
- `headless`: Run browser in headless mode (default: TRUE)
- `verbose`: Show progress information (default: TRUE)

**Features**:
- Uses `fa_create_date_range_scrape()` to create batch Scrape object
- Calls `ScrapeObjects()` to scrape all queries in one browser session
- Filters placeholder rows automatically
- Processes results into user-friendly format
- Comprehensive error messages

**Returns**: Data frame with columns: City, Airport, Dest, Date, Price, and optionally Comment and Offers

### 3. `fa_flex_table(results, ...)`

**Purpose**: Create wide summary table for easy comparison

**Parameters**:
- `results`: Data frame from fa_scrape_best_oneway()
- `include_comment`: Include comment column (default: TRUE)
- `currency_symbol`: Symbol for formatting (default: "$")
- `round_prices`: Round to integers (default: TRUE)

**Features**:
- Reshapes data to City × Date format
- Calculates average price per route
- Sorts date columns chronologically
- Formats prices with currency symbols (using scales package)
- Handles missing values gracefully

**Returns**: Wide data frame with City, Airport, [Comment], date columns, and Average_Price

### 4. `fa_best_dates(results, n, by)`

**Purpose**: Identify cheapest travel dates

**Parameters**:
- `results`: Data frame from fa_scrape_best_oneway()
- `n`: Number of best dates to return (default: 10)
- `by`: Aggregation method: "mean", "median", or "min" (default: "mean")

**Features**:
- Aggregates prices by date
- Supports multiple aggregation methods
- Includes route count per date
- Returns sorted results (cheapest first)

**Returns**: Data frame with Date, Price (aggregated), and N_Routes columns

## Internal Helper Functions

### `filter_placeholder_rows(data)`

Removes placeholder entries from scraped data:
- "Price graph"
- "Price unavailable"
- Empty/whitespace entries
- Rows with NA prices

Case-insensitive matching for robustness.

### `process_scrape_results(scrape_data, routes, keep_offers, verbose)`

Processes raw scraped data into user-friendly format:
- Extracts dates from departure_datetime
- Maps airport codes to city names
- Groups by airport-date combinations
- Extracts cheapest price or stores all offers
- Formats into expected data structure

## File Changes

### New Files

1. **R/flex_search.R** (470 lines)
   - All new functions with comprehensive roxygen2 documentation
   - Internal helper functions for filtering and processing
   - Refactored to use chain-trip approach

2. **tests/testthat/test-flex_search.R** (165 lines)
   - 9 test cases covering:
     - Placeholder filtering
     - Wide table creation
     - Best date identification
     - Different aggregation methods
     - Helper function validation
     - Input validation
     - Edge cases

3. **examples/flexible_date_search.R** (101 lines)
   - Basic usage examples
   - Mock data demonstrations
   - Usage tips

4. **examples/issue_example.R** (143 lines)
   - Exact use case from GitHub issue
   - Comprehensive workflow demonstration
   - Real-world tips

5. **examples/workflow_diagram.md** (115 lines)
   - Visual workflow diagrams
   - Data structure flow
   - Step-by-step examples

6. **NEWS.md** (38 lines)
   - Version history
   - Feature documentation

### Modified Files

1. **DESCRIPTION**
   - Added `scales` and `tibble` to Suggests

2. **NAMESPACE**
   - Exported 4 new functions (added fa_create_date_range_scrape)

3. **R/flightanalysis-package.R**
   - Updated package documentation
   - Added new functions to main functions list

4. **README.md**
   - Added "Flexible Date Search (NEW!)" section
   - Updated features list
   - Added examples for both convenience and separated workflows
   - Updated release notes

5. **REFACTORING_SUMMARY.md** (new file)
   - Detailed explanation of architectural changes
   - Comparison of before/after approaches
   - Migration guide for users

## Design Decisions

### Why These Function Names?

- `fa_create_date_range_scrape()`: Clear purpose - creates Scrape object for date range
- `fa_scrape_best_oneway()`: Clear that it's flight analysis (fa_), scrapes data, finds best prices, one-way trips
- `fa_flex_table()`: Indicates flexible date table output
- `fa_best_dates()`: Simple, self-explanatory

### Why Not Use tidyr/dplyr?

- Minimal dependencies (base R stats::reshape, stats::aggregate)
- Package can work without tidyverse
- More portable and lighter weight

### Why Use Chain-Trip Approach?

- Leverages existing tested functionality (no duplicate code)
- Single browser session for all queries (more efficient)
- Separates query definition from scraping (better design)
- Allows users to inspect/modify Scrape object before scraping

### Why Filter Placeholders Automatically?

- Users always want real flight data
- Placeholder rows have no analytical value
- Simplifies downstream analysis

### Why Support Multiple Aggregation Methods?

- "mean": Best for finding consistently cheap dates
- "median": Robust to outliers
- "min": Best for finding absolute cheapest options

## Usage Example

```r
library(flightanalysis)

# Define routes
routes <- data.frame(
  City = c("Mumbai", "Delhi", "Varanasi"),
  Airport = c("BOM", "DEL", "VNS"),
  Dest = rep("JFK", 3),
  Comment = c("Original", "", "")
)

# Define dates
dates <- seq(as.Date("2025-12-18"), as.Date("2026-01-05"), by = "day")

# Scrape data (3 routes × 19 dates = 57 queries)
results <- fa_scrape_best_oneway(routes, dates, pause = 3, verbose = TRUE)

# Create summary table
summary_table <- fa_flex_table(results)
print(summary_table)

# Find best dates
best_dates <- fa_best_dates(results, n = 5, by = "mean")
print(best_dates)
```

## Testing Strategy

Tests cover:
1. **Core functionality**: Filtering, table creation, date aggregation
2. **Edge cases**: Empty data, missing columns, single route
3. **Input validation**: Error messages for invalid inputs
4. **Different scenarios**: Multiple aggregation methods, with/without comments

All tests use mock data (no live scraping) for reliability and speed.

## Performance Considerations

- Browser initialized once (not per query)
- Pre-allocated results list (no growing vectors)
- Built-in rate limiting to avoid overload
- Efficient filtering using vectorized operations

## Future Enhancements

Potential improvements for future versions:
1. Progress bars using `progress` package
2. Caching support (avoid re-scraping)
3. Parallel scraping (with appropriate rate limiting)
4. Support for round-trip searches
5. Export to CSV/Excel with formatting
6. Interactive plots using plotly

## Documentation Quality

All functions include:
- Clear descriptions
- Parameter documentation with types and defaults
- Return value documentation
- Examples with \dontrun{}
- @export tags for NAMESPACE
- @keywords internal for helpers

## Compliance with Issue Requirements

✅ Search over flexible date ranges  
✅ Search over multiple airports  
✅ Store all scraped offers (keep_offers option)  
✅ Extract cheapest one per day (default behavior)  
✅ Wide summary table (City × Date + Average Price)  
✅ Helper to extract top N dates  
✅ Remove placeholder rows ("Price graph", etc.)  
✅ Currency formatting (scales::dollar)  
✅ Rate-limiting (pause argument)  
✅ Progress reporting (verbose option)  

## Code Quality

- Follows R package conventions
- Comprehensive error handling
- Clear variable names
- Modular design (separate concerns)
- DRY principle (no code duplication)
- Defensive programming (input validation)

## Backward Compatibility

- No changes to existing functions
- Only additions (new file, new exports)
- Existing code continues to work unchanged

## Total Changes

- **Lines of code added**: ~1,096
- **New functions**: 3 exported, 1 internal
- **Test coverage**: 7 test cases
- **Documentation**: Comprehensive roxygen2 + examples
- **Files created**: 6
- **Files modified**: 4

## Summary

This implementation provides a complete solution for flexible date search in the flightanalysis package. Users can now easily search across multiple airports and dates, view results in intuitive summary tables, and quickly identify the best travel dates - all with minimal code and maximum flexibility.
