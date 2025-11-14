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
data(sample_query)
str(sample_query)
#> List of 6
#>  $ origin:List of 2
#>   ..$ : chr "JFK"
#>   ..$ : chr "IST"
#>  $ dest  :List of 2
#>   ..$ : chr "IST"
#>   ..$ : chr "JFK"
#>  $ date  :List of 2
#>   ..$ : chr "2025-12-20"
#>   ..$ : chr "2025-12-27"
#>  $ data  :'data.frame':  0 obs. of  0 variables
#>  $ url   :List of 2
#>   ..$ : chr "https://www.google.com/travel/flights?hl=en&q=Flights%20to%20IST%20from%20JFK%20on%202025-12-20%20oneway"
#>   ..$ : chr "https://www.google.com/travel/flights?hl=en&q=Flights%20to%20JFK%20from%20IST%20on%202025-12-27%20oneway"
#>  $ type  : chr "round-trip"
#>  - attr(*, "class")= chr "flight_query"
print(sample_query)
#> Flight Query( {Not Yet Fetched}
#> 2025-12-20: JFK --> IST
#> 2025-12-27: IST --> JFK
#> )
```
