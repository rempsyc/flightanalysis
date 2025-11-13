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
  fa_define_query())

- verbose:

  Logical. If TRUE, shows detailed progress information (default)

## Value

Modified query object(s) with scraped data. \*\*Important:\*\* You must
capture the return value to get the scraped data: \`result \<-
fa_fetch_flights(query)\`

## Examples

``` r
if (FALSE) { # \dontrun{
query <- fa_define_query("JFK", "IST", "2025-12-20", "2025-12-25")
result <- fa_fetch_flights(query)
result$data
} # }
```
