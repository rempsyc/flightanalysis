# Future Improvements

This document outlines planned improvements for the flightanalysis package.

## Completed: v2.0.0 API Redesign

✅ **Consistent fa_ Prefix**
- Applied `fa_` prefix to all user-facing functions
- Follows R/Tidyverse conventions for namespace clarity
- Improves discoverability via auto-completion

✅ **Core Functions**
- `fa_define_query()` - Create flight queries (formerly `fa_define_query`, `Scrape`)
- `fa_fa_fetch_flights()` - Fetch flight data (formerly `fa_fetch_flights`, `scrape_objects`, `ScrapeObjects`)
- `fa_create_date_range()` - Create date range queries (formerly `fa_create_date_range`, `fa_fa_create_date_range_scrape`)
- `fa_summarize_prices()` - Create price summary tables (formerly `fa_summarize_prices`)
- `fa_find_best_dates()` - Find cheapest travel dates (formerly `fa_find_best_dates`)

✅ **Clean Slate**
- Removed all deprecated functions and backward compatibility code
- No migration guides needed (unpublished package)
- Consistent terminology throughout documentation
- Updated all examples, tests, and documentation

## Phase 2: Sample Datasets (Next PR)

### Add Toy Datasets for Offline Testing

**Rationale:** Following R package conventions, provide sample data for:
- Testing functions without internet access
- Documentation examples
- User exploration without API calls

**Implementation:**

1. Create `data/` directory
2. Add datasets:
   - `sample_query` - Example flight query object
   - `sample_flights` - Example flight data (data.frame)
   - `sample_multi_origin` - Example multiple origin queries

3. Add documentation in `R/data.R`:
```r
#' Sample Flight Query
#'
#' @description
#' A sample flight query object created with fa_define_query().
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
#' Sample scraped flight data. Use for testing fa_find_best_dates()
#' and fa_summarize_prices() without internet access.
#'
#' @format A data frame with 10 rows and 12 variables
#' @examples
#' data(sample_flights)
#' head(sample_flights)
"sample_flights"
```

4. Create datasets:
```r
# In data-raw/create_datasets.R
sample_query <- fa_define_query("JFK", "IST", "2025-12-20", "2025-12-27")
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

## Phase 3: Documentation Improvements (Ongoing)

### Generate Man Pages
After completing code changes:
```r
roxygen2::roxygenize()
```

### Regenerate README
```r
rmarkdown::render("README.Rmd")
```

### Create Migration Guide
Add to package vignettes:
```r
usethis::use_vignette("migration-guide-v2")
```

Content should include:
- Side-by-side comparison of old vs new API
- Common migration patterns
- Troubleshooting deprecated warnings
- Examples for each renamed function

## Phase 4: Testing & Validation

### Test Coverage
- Verify all deprecated functions still work
- Test both old and new class names (`Scrape` and `flight_query`)
- Ensure backward compatibility

### Documentation Review  
- Check all man pages render correctly
- Verify examples run
- Update pkgdown site if applicable

## Instructions for Next PR Agent (Phase 2: Sample Datasets)

### Overview
Implement sample datasets following R package conventions to enable offline testing and better documentation examples.

### Prerequisites
- R must be installed with `usethis`, `roxygen2`, and base packages
- Understanding of R package data conventions

### Step-by-Step Implementation

**1. Create directory structure:**
```bash
mkdir -p data-raw
```

**2. Create `data-raw/create_datasets.R` with this content:**
```r
# Generate sample datasets for flightanalysis package

library(flightanalysis)

# Sample 1: Simple query object
sample_query <- fa_define_query("JFK", "IST", "2025-12-20", "2025-12-27")
usethis::use_data(sample_query, overwrite = TRUE)

# Sample 2: Sample flight data
sample_flights <- data.frame(
  departure_datetime = as.POSIXct(c(
    "2025-12-20 09:00:00", "2025-12-20 14:30:00",
    "2025-12-20 22:00:00", "2025-12-21 10:15:00",
    "2025-12-27 08:30:00", "2025-12-27 15:45:00"
  )),
  arrival_datetime = as.POSIXct(c(
    "2025-12-20 22:00:00", "2025-12-21 03:45:00",
    "2025-12-21 11:30:00", "2025-12-21 23:30:00",
    "2025-12-27 21:15:00", "2025-12-28 05:00:00"
  )),
  origin = c("JFK", "JFK", "JFK", "JFK", "IST", "IST"),
  destination = c("IST", "IST", "IST", "IST", "JFK", "JFK"),
  airlines = c(
    "Turkish Airlines", "Lufthansa", "LOT Polish Airlines",
    "Air France", "Turkish Airlines", "United Airlines"
  ),
  travel_time = c(
    "13 hr 0 min", "13 hr 15 min", "13 hr 30 min",
    "13 hr 15 min", "12 hr 45 min", "13 hr 15 min"
  ),
  price = c(650, 720, 580, 695, 620, 685),
  num_stops = c(0, 1, 1, 1, 0, 1),
  layover = c(NA, "2 hr 30 min FRA", "3 hr 15 min WAW", 
              "2 hr 45 min CDG", NA, "3 hr 10 min EWR"),
  access_date = rep(Sys.time(), 6),
  co2_emission_kg = c(550, 580, 600, 570, 540, 575),
  emission_diff_pct = c(5, 10, 15, 8, 3, 9),
  stringsAsFactors = FALSE
)
usethis::use_data(sample_flights, overwrite = TRUE)

# Sample 3: Multiple origin queries
sample_multi_origin <- fa_create_date_range(
  origin = c("BOM", "DEL"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2025-12-22"
)
usethis::use_data(sample_multi_origin, overwrite = TRUE)

cat("✓ All sample datasets created successfully!\n")
cat("  - sample_query: Simple round-trip query\n")
cat("  - sample_flights: Sample flight data (6 flights)\n")
cat("  - sample_multi_origin: Multiple origin queries\n")
```

**3. Create `R/data.R` with dataset documentation:**
```r
#' Sample Flight Query
#'
#' @description
#' A sample flight query object created with `fa_define_query()`.
#' Useful for testing and documentation examples without making API calls.
#'
#' @format A flight_query object for JFK to IST round-trip
#' \describe{
#'   \item{origin}{List of origin airport codes}
#'   \item{dest}{List of destination airport codes}
#'   \item{dates}{List of travel dates}
#'   \item{type}{Trip type (round-trip)}
#'   \item{url}{Google Flights URLs}
#' }
#'
#' @examples
#' data(sample_query)
#' str(sample_query)
#' print(sample_query)
"sample_query"

#' Sample Flight Data
#'
#' @description
#' Sample scraped flight data for testing analysis functions
#' like `fa_find_best_dates()` and `fa_summarize_prices()` without internet access.
#'
#' @format A data frame with 6 rows and 12 variables:
#' \describe{
#'   \item{departure_datetime}{POSIXct departure date and time}
#'   \item{arrival_datetime}{POSIXct arrival date and time}
#'   \item{origin}{Character, 3-letter origin airport code}
#'   \item{destination}{Character, 3-letter destination airport code}
#'   \item{airlines}{Character, airline name(s)}
#'   \item{travel_time}{Character, total travel time}
#'   \item{price}{Numeric, ticket price in USD}
#'   \item{num_stops}{Integer, number of stops}
#'   \item{layover}{Character, layover details (NA if nonstop)}
#'   \item{access_date}{POSIXct, when data was accessed}
#'   \item{co2_emission_kg}{Numeric, CO2 emissions in kg}
#'   \item{emission_diff_pct}{Numeric, emission difference percentage}
#' }
#'
#' @examples
#' data(sample_flights)
#' head(sample_flights)
#' # Use with analysis functions
#' \dontrun{
#' fa_find_best_dates(sample_flights, n = 3)
#' }
"sample_flights"

#' Sample Multiple Origin Queries
#'
#' @description
#' Sample query objects for multiple origins created with `fa_create_date_range()`.
#' Demonstrates searching multiple airports over a date range.
#'
#' @format A named list of 2 flight_query objects (BOM and DEL to JFK)
#' \describe{
#'   \item{BOM}{query object for Mumbai (BOM) to JFK}
#'   \item{DEL}{query object for Delhi (DEL) to JFK}
#' }
#'
#' @examples
#' data(sample_multi_origin)
#' names(sample_multi_origin)
#' print(sample_multi_origin$BOM)
"sample_multi_origin"
```

**4. Execute the setup:**
```bash
# Run the dataset creation script
cd /path/to/flightanalysis
Rscript data-raw/create_datasets.R

# Regenerate documentation
Rscript -e "roxygen2::roxygenize()"
```

**5. Verify datasets work:**
```bash
# Test loading datasets
Rscript -e "library(flightanalysis); data(sample_query); str(sample_query)"
Rscript -e "library(flightanalysis); data(sample_flights); head(sample_flights)"
Rscript -e "library(flightanalysis); data(sample_multi_origin); names(sample_multi_origin)"
```

**6. Update documentation:**
- Add note in README.md about sample datasets under "Usage" section
- Update examples in man pages to optionally use sample data
- Consider adding to vignettes if they exist

### Validation Checklist

- [ ] `data-raw/` directory created
- [ ] `data-raw/create_datasets.R` script created and runs without errors
- [ ] `data/` directory contains 3 `.rda` files: `sample_query.rda`, `sample_flights.rda`, `sample_multi_origin.rda`
- [ ] `R/data.R` created with complete documentation for all 3 datasets
- [ ] `roxygen2::roxygenize()` runs successfully
- [ ] `data(sample_query)` loads successfully
- [ ] `data(sample_flights)` loads successfully
- [ ] `data(sample_multi_origin)` loads successfully
- [ ] Man pages (`?sample_query`, `?sample_flights`, `?sample_multi_origin`) display correctly
- [ ] Examples in man pages run without errors
- [ ] README.md updated to mention sample datasets
- [ ] Consider adding `.Rbuildignore` entry for `^data-raw$` if not already present

### Expected Outcome

After completion, users should be able to:
```r
library(flightanalysis)

# Load sample data
data(sample_query)
data(sample_flights)
data(sample_multi_origin)

# Use in examples
fa_find_best_dates(sample_flights, n = 3)
fa_summarize_prices(sample_flights)
print(sample_query)
```

### Notes
- Sample datasets should be small (<100 KB each)
- Use realistic but mock data (not real API responses)
- Ensure dates are in the future to match typical usage
- Follow R package data conventions from Writing R Extensions manual

## Notes for Maintainers

**Version Numbering:**
- Current changes warrant v2.0.0 (major API redesign)
- Include migration guide in release notes
- Consider a blog post or announcement for users

**Deprecation Timeline:**
- Keep deprecated functions for at least 2 minor versions
- Add removal date to deprecation messages in v2.2.0
- Remove deprecated functions in v3.0.0

**Communication:**
- Update package website with migration guide
- Post in R-packages mailing list
- Update GitHub README with prominent migration notice
