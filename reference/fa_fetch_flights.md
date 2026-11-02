# Fetch Flight Data

Fetches flight data from Google Flights using chromote. This function
will automatically set up a Chrome browser connection, navigate to
Google Flights URLs, and extract flight information. Uses the Chrome
DevTools Protocol for reliable, driver-free browser automation. The
browser runs in headless mode by default (no visible GUI).

## Usage

``` r
fa_fetch_flights(queries, verbose = TRUE)
```

## Arguments

- queries:

  A flight query object or list of query objects (from
  fa_define_query()). All departure dates must be between today and 330
  days ahead (inclusive). This is checked again at fetch time, so saved
  queries may expire.

- verbose:

  Logical. If TRUE, shows detailed progress information (default)

## Value

A flight_results object containing the merged flight data. Access the
data via \`result\$data\`. \*\*Important:\*\* You must capture the
return value to get the flight data: \`result \<-
fa_fetch_flights(query)\`

## Examples

``` r
if (FALSE) { # \dontrun{
departure <- Sys.Date() + 30
query <- fa_define_query("NYC", "IST", as.character(departure),
                         as.character(departure + 7))
flights <- fa_fetch_flights(query)
flights$data
} # }
```
