# Define Flight Query Range

Creates flight queries for multiple origin and/or destination
airports/cities across a date range. This helper function generates all
permutations of origins, destinations, and dates without actually
fetching data. Each origin-destination pair gets its own query object.
Similar to fa_define_query but for date ranges.

Supports airport codes (e.g., "JFK", "LGA"), city codes (e.g., "NYC" for
all New York City airports), and full city names (e.g., "New York").
Full city names are automatically converted to all associated airport
codes (excluding heliports). You can mix formats in the same vector.

## Usage

``` r
fa_define_query_range(origin, dest, date_min, date_max)
```

## Arguments

- origin:

  Character vector of airport codes, city codes, or full city names to
  search from. Can mix formats (e.g., c("JFK", "NYC", "New York")).
  Automatically expands city names to all associated airports (excluding
  heliports) and removes duplicates.

- dest:

  Character vector of airport codes, city codes, or full city names to
  search to. Can mix formats. Multiple destinations are supported;
  separate query objects will be created for each origin-destination
  pair.

- date_min:

  Character or Date. Start date in "YYYY-MM-DD" format.

- date_max:

  Character or Date. End date in "YYYY-MM-DD" format.

## Value

If single origin and destination: A flight query object containing all
dates. If multiple origins and/or destinations: A named list of flight
query objects, one per origin-destination pair (named as "ORIGIN-DEST").

## Examples

``` r
# Airport codes
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

# City codes
fa_define_query_range(
  origin = "NYC",
  dest = "LON",
  date_min = "2025-12-18",
  date_max = "2025-12-20"
)
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: NYC --> LON
#> 2025-12-19: NYC --> LON
#> 2025-12-20: NYC --> LON
#> )

# Full city names (auto-converted to airport codes)
fa_define_query_range(
  origin = "New York",
  dest = "Istanbul",
  date_min = "2025-12-18",
  date_max = "2025-12-20"
)
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: NYC --> IST
#> 2025-12-19: NYC --> IST
#> 2025-12-20: NYC --> IST
#> )

# Mix formats - codes and city names
fa_define_query_range(
  origin = c("New York", "JFK", "BOM", "Patna"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2025-12-20"
)
#> $NYC
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: NYC --> JFK
#> 2025-12-19: NYC --> JFK
#> 2025-12-20: NYC --> JFK
#> )
#> $JFK
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: JFK --> JFK
#> 2025-12-19: JFK --> JFK
#> 2025-12-20: JFK --> JFK
#> )
#> $BOM
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: BOM --> JFK
#> 2025-12-19: BOM --> JFK
#> 2025-12-20: BOM --> JFK
#> )
#> $PAT
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: PAT --> JFK
#> 2025-12-19: PAT --> JFK
#> 2025-12-20: PAT --> JFK
#> )

# Multiple destinations
fa_define_query_range(
  origin = "BOM",
  dest = c("JFK", "LON"),
  date_min = "2025-12-18",
  date_max = "2025-12-20"
)
#> $JFK
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: BOM --> JFK
#> 2025-12-19: BOM --> JFK
#> 2025-12-20: BOM --> JFK
#> )
#> $LON
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: BOM --> LON
#> 2025-12-19: BOM --> LON
#> 2025-12-20: BOM --> LON
#> )
```
