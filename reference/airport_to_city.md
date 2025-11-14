# Convert Airport Codes to City Names

Attempts to convert IATA airport codes to city names using the airportr
package. Falls back to the provided fallback value if conversion fails
or package is not available.

## Usage

``` r
airport_to_city(airport_codes, fallback = airport_codes)
```

## Arguments

- airport_codes:

  Character vector of IATA airport codes

- fallback:

  Character vector of fallback values (same length as airport_codes)

## Value

Character vector of city names
