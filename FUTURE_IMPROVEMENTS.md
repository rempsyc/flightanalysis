# Future Improvements

This document outlines planned improvements for the flightanalysis package.

## Completed: v2.0.0 API Redesign

✅ **Consistent fa_ Prefix**
- Applied `fa_` prefix to all user-facing functions
- Follows R/Tidyverse conventions for namespace clarity
- Improves discoverability via auto-completion

✅ **Core Functions**
- `fa_define_query()` - Create flight queries (formerly `define_query`, `Scrape`)
- `fa_fetch_flights()` - Fetch flight data (formerly `fetch_flights`, `scrape_objects`, `ScrapeObjects`)
- `fa_create_date_range()` - Create date range queries (formerly `create_date_range`, `fa_create_date_range_scrape`)
- `fa_summarize_prices()` - Create price summary tables (formerly `fa_flex_table`)
- `fa_find_best_dates()` - Find cheapest travel dates (formerly `fa_best_dates`)

✅ **Clean Slate**
- Removed all deprecated functions and backward compatibility code
- No migration guides needed (unpublished package)
- Consistent terminology throughout documentation
- Updated all examples, tests, and documentation

## Completed: Phase 2 - Sample Datasets

✅ **Sample Datasets for Offline Testing**

**Rationale:** Following R package conventions, provide sample data for:
- Testing functions without internet access
- Documentation examples
- User exploration without API calls

**Completed Implementation:**
- ✅ Created `data-raw/` directory with dataset generation script
- ✅ Added three sample datasets:
  - `sample_query` - Example flight query object (JFK to IST round-trip)
  - `sample_flights` - Sample scraped flight data (6 flights)
  - `sample_multi_origin` - Multiple origin queries (BOM and DEL to JFK)
- ✅ Created `R/data.R` with complete documentation for all datasets
- ✅ Generated man pages with roxygen2
- ✅ Updated README.md with sample dataset section
- ✅ Updated `.Rbuildignore` to exclude `data-raw/`
- ✅ All datasets are small (<1 KB each) and contain realistic mock data
- ✅ Verified datasets work with analysis functions

**Usage Example:**
```r
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
```r
roxygen2::roxygenize()
```

### Regenerate README
```r
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
- R must be installed with `roxygen2`, `rmarkdown`, and `usethis` packages
- Understanding of R package documentation conventions

### Tasks

**1. Regenerate README from README.Rmd:**
```bash
Rscript -e "rmarkdown::render('README.Rmd')"
```

**3. Review and Update Documentation:**
- Check all man pages render correctly
- Verify examples run without errors
- Update pkgdown site configuration if applicable
- Ensure consistency across all documentation

### Validation
- [ ] README.md is up-to-date with README.Rmd
- [ ] All man pages render correctly
- [ ] All examples run without errors
- [ ] Documentation follows R package best practices

## Notes for Maintainers
- TBD

## Maintainer Notes
- TBD
