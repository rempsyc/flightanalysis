# Define Flight Query

Defines a flight query for Google Flights. Supports one-way, round-trip,
chain-trip, and perfect-chain trip types.

Accepts airport codes (e.g., "JFK", "LGA"), city codes (e.g., "NYC" for
all New York City airports), and full city names (e.g., "New York").
Full city names are automatically converted to their first associated
airport code. Common city codes include: "NYC" (New York), "LON"
(London), "PAR" (Paris), "TYO" (Tokyo), "BUE" (Buenos Aires), etc.

## Usage

``` r
fa_define_query(...)
```

## Arguments

- ...:

  Arguments defining the trip. Locations can be 3-letter codes or full
  city names. Format depends on trip type: - One-way: origin, dest,
  date - Round-trip: origin, dest, date_leave, date_return - Chain-trip:
  org1, dest1, date1, org2, dest2, date2, ... - Perfect-chain: org1,
  date1, org2, date2, ..., final_dest

## Value

A flight query object (S3 class "flight_query")

## Examples

``` r
# One-way trip with airport codes
fa_define_query("JFK", "BOS", "2025-12-20")
#> Flight Query( {Not Yet Fetched}
#> 2025-12-20: JFK --> BOS
#> )

# One-way trip with city codes
fa_define_query("NYC", "LON", "2025-12-20")
#> Flight Query( {Not Yet Fetched}
#> 2025-12-20: NYC --> LON
#> )

# One-way trip with full city names (auto-converted)
fa_define_query("New York", "Istanbul", "2025-12-20")
#> Flight Query( {Not Yet Fetched}
#> 2025-12-20: NYC --> IST
#> )

# Round-trip with mixed formats
fa_define_query("JFK", "Paris", "2025-12-20", "2025-12-25")
#> Flight Query( {Not Yet Fetched}
#> 2025-12-20: JFK --> PAR
#> 2025-12-25: PAR --> JFK
#> )

# Chain-trip
fa_define_query("JFK", "YYZ", "2025-12-20", "RDU", "LGA", "2025-12-25")
#> Flight Query( {Not Yet Fetched}
#> 2025-12-20: JFK --> YYZ
#> 2025-12-25: RDU --> LGA
#> )
```
