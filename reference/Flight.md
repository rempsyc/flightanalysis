# Flight Class

Creates a Flight object that represents a single flight with all its
details.

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

## Examples

``` r
if (FALSE) { # \dontrun{
flight <- Flight("2025-12-25", "JFKIST", "9:00AM", "5:00PM+1",
                 "8 hr 0 min", "Nonstop", "150 kg CO2", "10% emissions", "$450")
} # }
```
