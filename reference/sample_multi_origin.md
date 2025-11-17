# Sample Multiple Origin Queries

Sample query objects for multiple origins created with
\`fa_define_query_range()\`. Demonstrates searching multiple airports
over a date range.

## Usage

``` r
sample_multi_origin
```

## Format

A named list of 2 flight_query objects (BOM and DEL to JFK)

- BOM:

  query object for Mumbai (BOM) to JFK

- DEL:

  query object for Delhi (DEL) to JFK

## Examples

``` r
sample_multi_origin
#> $BOM
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: BOM --> JFK
#> 2025-12-19: BOM --> JFK
#> 2025-12-20: BOM --> JFK
#> 2025-12-21: BOM --> JFK
#> 2025-12-22: BOM --> JFK
#> )
#> $DEL
#> Flight Query( {Not Yet Fetched}
#> 2025-12-18: DEL --> JFK
#> 2025-12-19: DEL --> JFK
#> 2025-12-20: DEL --> JFK
#> 2025-12-21: DEL --> JFK
#> 2025-12-22: DEL --> JFK
#> )
```
