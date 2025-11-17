# Sample Flight Query

A sample flight query object created with \`fa_define_query()\`. Useful
for testing and documentation examples without making API calls.

## Usage

``` r
sample_query
```

## Format

A flight_query object for JFK to IST round-trip

- origin:

  List of origin airport codes

- dest:

  List of destination airport codes

- dates:

  List of travel dates

- type:

  Trip type (round-trip)

- url:

  Google Flights URLs

## Examples

``` r
sample_query
#> Flight Query( {Not Yet Fetched}
#> 2025-12-20: JFK --> IST
#> 2025-12-27: IST --> JFK
#> )
```
