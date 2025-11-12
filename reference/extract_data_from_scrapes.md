# Extract and Process Data from Scrape Objects

Internal helper that extracts data from Scrape objects (single or list),
filters placeholder rows, and formats for use with fa_flex_table and
fa_best_dates.

## Usage

``` r
extract_data_from_scrapes(scrapes)
```

## Arguments

- scrapes:

  A single Scrape object or a named list of Scrape objects

## Value

A data frame with columns: Airport, Date, Price, and City (if named
list)
