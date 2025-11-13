# Future API Improvements - Phase 2

This document outlines additional improvements to be implemented in
future PRs.

## Completed in Current PR

✅ **Core Function Renames (Tidyverse Style)** -
[`Scrape()`](https://rempsyc.github.io/flightanalysis/reference/define_query.md)
→
[`define_query()`](https://rempsyc.github.io/flightanalysis/reference/define_query.md) -
[`ScrapeObjects()`](https://rempsyc.github.io/flightanalysis/reference/fetch_flights.md)/[`scrape_objects()`](https://rempsyc.github.io/flightanalysis/reference/fetch_flights.md)
→
[`fetch_flights()`](https://rempsyc.github.io/flightanalysis/reference/fetch_flights.md) -
[`fa_create_date_range_scrape()`](https://rempsyc.github.io/flightanalysis/reference/create_date_range.md)
→
[`create_date_range()`](https://rempsyc.github.io/flightanalysis/reference/create_date_range.md)

✅ **Code Organization** - Made
[`Flight()`](https://rempsyc.github.io/flightanalysis/reference/Flight.md)
and
[`flights_to_dataframe()`](https://rempsyc.github.io/flightanalysis/reference/flights_to_dataframe.md)
internal - Added S3 class `flight_query` (backward compatible with
`Scrape`) - Updated all R source files, examples, tests, and
documentation - Kept all old function names as deprecated aliases

## Phase 2: Sample Datasets (Next PR)

### Add Toy Datasets for Offline Testing

**Rationale:** Following R package conventions, provide sample data
for: - Testing functions without internet access - Documentation
examples - User exploration without API calls

**Implementation:**

1.  Create `data/` directory
2.  Add datasets:
    - `sample_query` - Example flight query object
    - `sample_flights` - Example flight data (data.frame)
    - `sample_multi_origin` - Example multiple origin queries
3.  Add documentation in `R/data.R`:

``` r
#' Sample Flight Query
#'
#' @description
#' A sample flight query object created with define_query().
#' Can be used for testing and examples.
#'
#' @format A flight_query object for JFK to IST round-trip
#' @examples
#' data(sample_query)
#' str(sample_query)
"sample_query"

#' Sample Flight Data
#'
#' @description  
#' Sample scraped flight data. Use for testing fa_best_dates()
#' and fa_flex_table() without internet access.
#'
#' @format A data frame with 10 rows and 12 variables
#' @examples
#' data(sample_flights)
#' head(sample_flights)
"sample_flights"
```

4.  Create datasets:

``` r
# In data-raw/create_datasets.R
sample_query <- define_query("JFK", "IST", "2025-12-20", "2025-12-27")
usethis::use_data(sample_query, overwrite = TRUE)

sample_flights <- data.frame(
  departure_datetime = c("2025-12-20 09:00:00", "2025-12-20 14:30:00"),
  arrival_datetime = c("2025-12-20 22:00:00", "2025-12-21 03:45:00"),
  origin = c("JFK", "JFK"),
  destination = c("IST", "IST"),
  airlines = c("Turkish Airlines", "Lufthansa"),
  travel_time = c("13 hr 0 min", "13 hr 15 min"),
  price = c(650, 720),
  num_stops = c(0, 1),
  layover = c(NA, "2 hr 30 min FRA"),
  access_date = rep(Sys.time(), 2),
  co2_emission_kg = c(550, 580),
  emission_diff_pct = c(5, 10),
  stringsAsFactors = FALSE
)
usethis::use_data(sample_flights, overwrite = TRUE)
```

## Phase 3: Consider fa\_ Prefix Removal (Future PR)

**Current State:** -
[`fa_best_dates()`](https://rempsyc.github.io/flightanalysis/reference/fa_best_dates.md) -
already good -
[`fa_flex_table()`](https://rempsyc.github.io/flightanalysis/reference/fa_flex_table.md) -
already good

**Consideration:** The `fa_` prefix might be redundant since these
functions are in the `flightanalysis` package.

**Options:** 1. **Keep as is** - `fa_` provides namespace clarity 2.
**Remove prefix** - `best_dates()`, `flex_table()` 3. **More
descriptive** - `find_best_dates()`, `create_summary_table()`

**Recommendation:** Keep as is for now. The `fa_` prefix is helpful
for: - Avoiding conflicts with user functions - Grouping related
functions - Maintaining consistency with existing code

If removing, would need: - Deprecated aliases for
[`fa_best_dates()`](https://rempsyc.github.io/flightanalysis/reference/fa_best_dates.md)
and
[`fa_flex_table()`](https://rempsyc.github.io/flightanalysis/reference/fa_flex_table.md) -
Update all documentation and examples - Another major version bump

## Phase 4: Documentation Improvements (Ongoing)

### Generate Man Pages

After completing code changes:

``` r
roxygen2::roxygenize()
```

### Regenerate README

``` r
rmarkdown::render("README.Rmd")
```

### Create Migration Guide

Add to package vignettes:

``` r
usethis::use_vignette("migration-guide-v2")
```

Content should include: - Side-by-side comparison of old vs new API -
Common migration patterns - Troubleshooting deprecated warnings -
Examples for each renamed function

## Phase 5: Testing & Validation

### Test Coverage

- Verify all deprecated functions still work
- Test both old and new class names (`Scrape` and `flight_query`)
- Ensure backward compatibility

### Documentation Review

- Check all man pages render correctly
- Verify examples run
- Update pkgdown site if applicable

## Implementation Checklist for Future Contributor

When implementing Phase 2 (datasets):

Create `data-raw/` directory  

Create `data-raw/create_datasets.R` script

Run script to generate `.rda` files in `data/`

Create `R/data.R` with documentation

Update NAMESPACE (datasets auto-exported)

Run `roxygen2::roxygenize()`

Test with `data(sample_query)` and `data(sample_flights)`

Update examples to optionally use sample data

Add note in README about sample datasets

## Notes for Maintainers

**Version Numbering:** - Current changes warrant v2.0.0 (major API
redesign) - Include migration guide in release notes - Consider a blog
post or announcement for users

**Deprecation Timeline:** - Keep deprecated functions for at least 2
minor versions - Add removal date to deprecation messages in v2.2.0 -
Remove deprecated functions in v3.0.0

**Communication:** - Update package website with migration guide - Post
in R-packages mailing list - Update GitHub README with prominent
migration notice
