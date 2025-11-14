# Clean Flight Data by Removing Invalid Entries

Removes invalid and placeholder rows from flight data, such as "Price
graph", "Price unavailable", empty entries, and rows with missing
prices. This is a data cleaning function used internally.

## Usage

``` r
filter_placeholder_rows(data)
```

## Arguments

- data:

  A data frame of flight data with an 'airlines' column

## Value

A filtered data frame with placeholder rows removed
