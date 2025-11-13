# Create Date Range Queries

Creates flight queries for multiple origin airports across a date range.
This helper function generates all permutations of origins and dates
without actually fetching data. Each origin gets its own query object.

## Usage

``` r
create_date_range(origin, dest, date_min, date_max)

fa_create_date_range_scrape(origin, dest, date_min, date_max)
```

## Arguments

- origin:

  Character vector of 3-letter airport codes to search from.

- dest:

  Character. 3-letter destination airport code.

- date_min:

  Character or Date. Start date in "YYYY-MM-DD" format.

- date_max:

  Character or Date. End date in "YYYY-MM-DD" format.

## Value

If single origin: A flight query object containing all dates. If
multiple origins: A named list of flight query objects, one per origin.

## Examples

``` r
if (FALSE) { # \dontrun{
# Single origin - returns one query object
query <- create_date_range(
  origin = "BOM",
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2026-01-05"
)
result <- fetch_flights(query)

# Multiple origins - returns list of query objects
queries <- create_date_range(
  origin = c("BOM", "DEL", "VNS"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2026-01-05"
)

# Fetch data for each origin
results <- list()
for (i in seq_along(queries)) {
  results[[i]] <- fetch_flights(queries[[i]])
}

# Combine all results
all_data <- do.call(rbind, lapply(results, function(x) x$data))
} # }
```
