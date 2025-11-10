# Scrape Flight Objects

Scrapes flight data from Google Flights using chromote. This function
will automatically set up a Chrome browser connection, navigate to
Google Flights URLs, and extract flight information. Uses the Chrome
DevTools Protocol for reliable, driver-free browser automation.

## Usage

``` r
ScrapeObjects(objs, deep_copy = FALSE, headless = TRUE, verbose = TRUE)
```

## Arguments

- objs:

  A Scrape object or list of Scrape objects

- deep_copy:

  Logical. If TRUE, returns a copy of the objects

- headless:

  Logical. If TRUE, runs browser in headless mode (no GUI, default)

- verbose:

  Logical. If TRUE, shows detailed progress information (default)

## Value

Modified Scrape object(s) with scraped data. \*\*Important:\*\* You must
capture the return value to get the scraped data: \`scrape \<-
ScrapeObjects(scrape)\`

## Examples

``` r
if (FALSE) { # \dontrun{
scrape <- Scrape("JFK", "IST", "2025-12-20", "2025-12-25")
scrape <- ScrapeObjects(scrape)
scrape$data
} # }
```
