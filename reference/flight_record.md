# Flight Record Class

Creates a flight_record object that represents a single flight with all
its details. Internal function used by fetch_flights() for parsing
flight data.

## Usage

``` r
flight_record(date, ...)
```

## Arguments

- date:

  Character string representing the flight date in format "YYYY-MM-DD"

- ...:

  Additional arguments containing flight details

## Value

A flight_record object (S3 class)
