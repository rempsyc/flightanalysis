# Define Flight Query Range

Creates flight queries for multiple origin airports across a date range.
This helper function generates all permutations of origins and dates
without actually fetching data. Each origin gets its own query object.
Similar to fa_define_query but for date ranges.

## Usage

``` r
fa_define_query_range(origin, dest, date_min, date_max)
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
# Single origin - returns one query object
fa_define_query_range(
  origin = "BOM",
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2025-12-20"
)
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: BOM --> JFK
#> 2025-12-19: BOM --> JFK
#> 2025-12-20: BOM --> JFK
#> )

# Multiple origins - returns named list of query objects
fa_define_query_range(
  origin = c("BOM", "DEL"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2025-12-20"
)
#> $BOM
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: BOM --> JFK
#> 2025-12-19: BOM --> JFK
#> 2025-12-20: BOM --> JFK
#> )
#> $DEL
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: DEL --> JFK
#> 2025-12-19: DEL --> JFK
#> 2025-12-20: DEL --> JFK
#> )
```
