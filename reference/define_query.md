# Define Flight Query

Defines a flight query for Google Flights. Supports one-way, round-trip,
chain-trip, and perfect-chain trip types.

## Usage

``` r
define_query(...)

Scrape(...)
```

## Arguments

- ...:

  Arguments defining the trip. Format depends on trip type: - One-way:
  origin, dest, date - Round-trip: origin, dest, date_leave,
  date_return - Chain-trip: org1, dest1, date1, org2, dest2, date2,
  ... - Perfect-chain: org1, date1, org2, date2, ..., final_dest

## Value

A flight query object (S3 class "flight_query")

## Examples

``` r
if (FALSE) { # \dontrun{
# One-way trip
query1 <- define_query("JFK", "BOS", "2025-12-20")

# Round-trip
query2 <- define_query("JFK", "YUL", "2025-12-20", "2025-12-25")

# Chain-trip
query3 <- define_query("JFK", "YYZ", "2025-12-20", "RDU", "LGA", "2025-12-25")
} # }
```
