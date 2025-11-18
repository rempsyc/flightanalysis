# Convert City Names to Airport Codes

Converts full city names to 3-letter IATA airport codes using the
airportr package. Returns all valid matching airport codes for cities
with multiple airports. Automatically filters out heliports to return
only commercial airports. Throws an error if a city name is not found in
the database.

## Usage

``` r
city_name_to_code(city_names)
```

## Arguments

- city_names:

  Character vector of city names

## Value

Character vector of 3-letter IATA airport codes. For cities with
multiple airports, all valid codes are returned (e.g., "New York"
returns c("LGA", "JFK")). Heliports and invalid codes are automatically
filtered out.

## Examples

``` r
city_name_to_code("New York")
#> [1] "EWR" "LGA" "JFK"
city_name_to_code(c("New York", "London"))
#>  [1] "EWR" "LGA" "JFK" "YXU" "LTN" "LGW" "LCY" "LHR" "STN" "LOZ"
```
