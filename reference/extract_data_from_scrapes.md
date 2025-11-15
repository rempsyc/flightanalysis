# Extract and Process Data from Query Objects

Internal helper that extracts data from query objects (single or list),
filters placeholder rows, and formats for use with fa_summarize_prices
and fa_find_best_dates.

## Usage

``` r
extract_data_from_scrapes(scrapes)
```

## Arguments

- scrapes:

  A single query object, a flight_results object, or a named list of
  query objects

## Value

A data frame with columns: Airport, Date, Price, City (if named list),
and additional columns: departure_datetime, airlines, travel_time,
num_stops, layover, co2_emission_kg (when available)
