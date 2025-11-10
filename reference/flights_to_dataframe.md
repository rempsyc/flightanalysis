# Convert Flight objects to data frame

Converts a list of Flight objects into a data frame.

## Usage

``` r
flights_to_dataframe(flights)
```

## Arguments

- flights:

  List of Flight objects

## Value

A data frame with flight information

## Examples

``` r
if (FALSE) { # \dontrun{
flight1 <- Flight("2025-12-25", "JFKIST", "$450", "Nonstop")
flight2 <- Flight("2025-12-26", "ISTCDG", "$300", "1 stop")
flight3 <- Flight("2025-12-27", "CDGJFK", "$500", "Nonstop")
flights <- list(flight1, flight2, flight3)
df <- flights_to_dataframe(flights)
} # }
```
