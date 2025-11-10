# Create a Scrape Object

Creates a Scrape object representing a Google Flights query. Supports
one-way, round-trip, chain-trip, and perfect-chain trip types.

## Usage

``` r
Scrape(...)
```

## Arguments

- ...:

  Arguments defining the trip. Format depends on trip type: - One-way:
  origin, dest, date - Round-trip: origin, dest, date_leave,
  date_return - Chain-trip: org1, dest1, date1, org2, dest2, date2,
  ... - Perfect-chain: org1, date1, org2, date2, ..., final_dest

## Value

A Scrape object (S3 class)

## Examples

``` r
if (FALSE) { # \dontrun{
# One-way trip
scrape1 <- Scrape("JFK", "BOS", "2025-12-20")

# Round-trip
scrape2 <- Scrape("JFK", "YUL", "2025-12-20", "2025-12-25")

# Chain-trip
scrape3 <- Scrape("JFK", "YYZ", "2025-12-20", "RDU", "LGA", "2025-12-25")
} # }
```
