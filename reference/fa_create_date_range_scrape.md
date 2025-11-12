# Create Flexible Date Range Scrape Objects

Creates Scrape objects for multiple origin airports and date range. This
is a helper function that generates all permutations of origins and
dates without actually scraping. Each origin gets its own chain-trip
Scrape object (to satisfy the chain-trip requirement that dates must be
strictly increasing). The resulting list of Scrape objects can be passed
to ScrapeObjects() one at a time.

## Usage

``` r
fa_create_date_range_scrape(origin, dest, date_min, date_max)
```

## Arguments

- origin:

  Character vector of 3-letter airport codes to search from.

- dest:

  Character. 3-letter destination airport code.

- date_min:

  Character or Date. Start date in "YYYY-MM-DD" format.

- date_max:

  Character or Date. End date in "YYYY-MM-DD" format.

## Value

If single origin: A Scrape object of type "chain-trip" containing all
dates. If multiple origins: A named list of Scrape objects, one per
origin.

## Examples

``` r
if (FALSE) { # \dontrun{
# Single origin - returns one Scrape object
scrape <- fa_create_date_range_scrape(
  origin = "BOM",
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2026-01-05"
)
scrape <- ScrapeObjects(scrape)

# Multiple origins - returns list of Scrape objects
scrapes <- fa_create_date_range_scrape(
  origin = c("BOM", "DEL", "VNS"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2026-01-05"
)

# Scrape each origin
results <- list()
for (i in seq_along(scrapes)) {
  scrapes[[i]] <- ScrapeObjects(scrapes[[i]])
  results[[i]] <- scrapes[[i]]$data
}

# Combine all results
all_data <- do.call(rbind, results)
} # }
```
