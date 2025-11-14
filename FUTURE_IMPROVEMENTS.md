# Future Improvements

This document outlines planned improvements for the flightanalysis
package.

## Completed: v2.0.0 API Redesign

✅ **Consistent fa\_ Prefix** - Applied `fa_` prefix to all user-facing
functions - Follows R/Tidyverse conventions for namespace clarity -
Improves discoverability via auto-completion

✅ **Core Functions** -
[`fa_define_query()`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query.md) -
Create flight queries (formerly `define_query`, `Scrape`) -
[`fa_fetch_flights()`](https://rempsyc.github.io/flightanalysis/reference/fa_fetch_flights.md) -
Fetch flight data (formerly `fetch_flights`, `scrape_objects`,
`ScrapeObjects`) -
[`fa_create_date_range()`](https://rempsyc.github.io/flightanalysis/reference/fa_create_date_range.md) -
Create date range queries (formerly `create_date_range`,
`fa_create_date_range_scrape`) -
[`fa_summarize_prices()`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md) -
Create price summary tables (formerly `fa_flex_table`) -
[`fa_find_best_dates()`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md) -
Find cheapest travel dates (formerly `fa_best_dates`)

✅ **Clean Slate** - Removed all deprecated functions and backward
compatibility code - No migration guides needed (unpublished package) -
Consistent terminology throughout documentation - Updated all examples,
tests, and documentation

## Completed: Phase 2 - Sample Datasets

✅ **Sample Datasets for Offline Testing**

**Rationale:** Following R package conventions, provide sample data
for: - Testing functions without internet access - Documentation
examples - User exploration without API calls

**Completed Implementation:** - ✅ Created `data-raw/` directory with
dataset generation script - ✅ Added three sample datasets: -
`sample_query` - Example flight query object (JFK to IST round-trip) -
`sample_flights` - Sample scraped flight data (6 flights) -
`sample_multi_origin` - Multiple origin queries (BOM and DEL to JFK) -
✅ Created `R/data.R` with complete documentation for all datasets - ✅
Generated man pages with roxygen2 - ✅ Updated README.md with sample
dataset section - ✅ Updated `.Rbuildignore` to exclude `data-raw/` - ✅
All datasets are small (\<1 KB each) and contain realistic mock data -
✅ Verified datasets work with analysis functions

**Usage Example:**

``` r
library(flightanalysis)

# Load sample data
data(sample_query)
data(sample_flights)
data(sample_multi_origin)

# Use with analysis functions
sample_query$data <- sample_flights
fa_find_best_dates(sample_query, n = 3)
fa_summarize_prices(sample_query)
```

## Phase 3: Documentation Improvements (Next PR)

### Generate Man Pages

After completing code changes:

``` r
roxygen2::roxygenize()
```

### Regenerate README

``` r
rmarkdown::render("README.Rmd")
```

## Phase 4: Testing & Validation (Future)

### Documentation Review

- Check all man pages render correctly
- Verify examples run
- Update pkgdown site if applicable

## Instructions for Next PR Agent (Phase 3: Documentation Improvements)

### Overview

Improve package documentation following R package best practices.

### Prerequisites

- R must be installed with `roxygen2`, `rmarkdown`, and `usethis`
  packages
- Understanding of R package documentation conventions

### Tasks

**1. Regenerate README from README.Rmd:**

``` bash
Rscript -e "rmarkdown::render('README.Rmd')"
```

**3. Review and Update Documentation:** - Check all man pages render
correctly - Verify examples run without errors - Update pkgdown site
configuration if applicable - Ensure consistency across all
documentation

### Validation

README.md is up-to-date with README.Rmd

All man pages render correctly

All examples run without errors

Documentation follows R package best practices

## Notes for Maintainers

- TBD

## Maintainer Notes

- Consider whether we can deal with the warnings of airportr without
  usign `invokeRestart("muffleWarning")`, for example by loading the
  data set through `data(airportr::airports)`

This doesn’t work

``` r
data(airportr::airports)
#> Warning in data(airportr::airports): data set 'airportr::airports' not found
```

but this does

``` r
airports <- airportr::airports
airports
#> # A tibble: 7,698 × 17
#>    `OpenFlights ID` Name                City  IATA  ICAO  Country `Country Code`
#>               <dbl> <chr>               <chr> <chr> <chr> <chr>   <chr>         
#>  1                1 Goroka Airport      Goro… GKA   AYGA  Papua … 598           
#>  2                2 Madang Airport      Mada… MAG   AYMD  Papua … 598           
#>  3                3 Mount Hagen Kagamu… Moun… HGU   AYMH  Papua … 598           
#>  4                4 Nadzab Airport      Nadz… LAE   AYNZ  Papua … 598           
#>  5                5 Port Moresby Jacks… Port… POM   AYPY  Papua … 598           
#>  6                6 Wewak Internationa… Wewak WWK   AYWK  Papua … 598           
#>  7                7 Narsarsuaq Airport  Nars… UAK   BGBW  Greenl… 304           
#>  8                8 Godthaab / Nuuk Ai… Godt… GOH   BGGH  Greenl… 304           
#>  9                9 Kangerlussuaq Airp… Sond… SFJ   BGSF  Greenl… 304           
#> 10               10 Thule Air Base      Thule THU   BGTL  Greenl… 304           
#> # ℹ 7,688 more rows
#> # ℹ 10 more variables: `Country Code (Alpha-2)` <chr>,
#> #   `Country Code (Alpha-3)` <chr>, Latitude <dbl>, Longitude <dbl>,
#> #   Altitude <dbl>, UTC <dbl>, DST <chr>, Timezone <chr>, Type <chr>,
#> #   Source <chr>
```

^(Created on 2025-11-13 with [reprex v2.1.1](https://reprex.tidyverse.org))
