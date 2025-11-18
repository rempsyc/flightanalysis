# Normalize Location Codes

Internal function to normalize a mix of airport codes, city codes, and
full city names to standardized 3-letter codes. Automatically converts
full city names to metropolitan area codes when available (unless
expand_cities=TRUE), otherwise to individual airport codes.

## Usage

``` r
normalize_location_codes(locations, expand_cities = FALSE)
```

## Arguments

- locations:

  Character vector of mixed airport codes, city codes, and city names

- expand_cities:

  Logical. If TRUE, expands city names to all individual airports. If
  FALSE (default), uses metropolitan area codes when available.

## Value

Character vector of 3-letter codes with duplicates removed
