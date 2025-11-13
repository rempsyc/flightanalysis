# Flight Class

Creates a Flight object that represents a single flight with all its
details. Internal function used by fetch_flights() for parsing scraped
data.

## Usage

``` r
Flight(date, ...)
```

## Arguments

- date:

  Character string representing the flight date in format "YYYY-MM-DD"

- ...:

  Additional arguments containing flight details

## Value

A Flight object (S3 class)
