# Process Query Data

Internal helper that processes a single query's data frame, extracting
and standardizing columns for use with fa_summarize_prices and
fa_find_best_dates.

## Usage

``` r
process_query_data(data, city_name = NULL)
```

## Arguments

- data:

  A data frame from a flight query

- city_name:

  Optional city name to use

## Value

A processed data frame with standardized columns
