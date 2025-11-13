# Find Best Travel Dates

Identifies and returns the top N dates with the cheapest average prices
across all routes. This helps quickly identify the best travel dates
when planning a flexible trip.

## Usage

``` r
fa_find_best_dates(results, n = 10, by = "min")
```

## Arguments

- results:

  Either: - A data frame with columns: Date and Price - A list of flight
  querys (from fa_create_date_range with multiple origins) - A single
  flight query (from fa_create_date_range with single origin)

- n:

  Integer. Number of best dates to return. Default is 10.

- by:

  Character. How to calculate best dates: "mean" (average price across
  routes), "median", or "min" (lowest price on that date). Default is
  "mean".

## Value

A data frame with columns: Date, Price (average/median/min), and
N_Routes (number of routes with data for that date). Sorted by price
(cheapest first).

## Examples

``` r
if (FALSE) { # \dontrun{
# Option 1: Pass list of flight querys directly
queries <- fa_create_date_range(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
for (code in names(queries)) {
  queries[[code]] <- fa_fetch_flights(queries[[code]])
}
best_dates <- fa_find_best_dates(queries, n = 5, by = "mean")

# Option 2: Pass processed data frame
best_dates <- fa_find_best_dates(my_data_frame, n = 5, by = "mean")
} # }
```
