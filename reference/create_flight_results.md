# Create Flight Results Object

Creates a flight_results object from a list of flight queries. Merges
data from all queries into a single data frame accessible via \$data,
while preserving individual query objects in named list elements.

## Usage

``` r
create_flight_results(queries)
```

## Arguments

- queries:

  Named list of flight_query objects

## Value

A flight_results object (S3 class) containing: - \$data: Merged data
frame from all queries - Named elements for each origin query (e.g.,
\$BOM, \$DEL)
