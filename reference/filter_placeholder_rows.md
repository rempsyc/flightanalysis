# Filter Out Placeholder Rows from Flight Data

Removes placeholder rows from scraped flight data, such as "Price
graph", "Price unavailable", etc.

## Usage

``` r
filter_placeholder_rows(data)
```

## Arguments

- data:

  A data frame of flight data with an 'airlines' column

## Value

A filtered data frame with placeholder rows removed
