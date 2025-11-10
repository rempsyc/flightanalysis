[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Flight Analysis - R Package

An R package for analyzing, forecasting, and collecting flight data and prices from Google Flights.

**Credits:** This is an R implementation inspired by the original [Python package](https://github.com/celebi-pkg/flightanalysis) by Kaya Celebi.

## Features

- Detailed scraping and querying tools for Google Flights using chromote
- Ability to store data locally or to SQL tables
- Support for multiple trip types: one-way, round-trip, chain-trip, and perfect-chain
- Driver-free web scraping using Chrome DevTools Protocol
- **NEW:** Flexible date search across multiple airports and date ranges
- **NEW:** Summary tables showing prices by city and date with average calculations
- **NEW:** Automatic identification of cheapest travel dates

## Installation

Install from GitHub:

```r
# Install devtools if you haven't already
install.packages("devtools")

# Install flightanalysis
devtools::install_github("rempsyc/flightanalysis")
```

Or source files directly:

```r
source('R/flight.R')
source('R/scrape.R')
```

## Usage

The R version provides similar functionality with R-native syntax:

```r
# Load the package
library(flightanalysis)
# Or source files directly:
# source('R/flight.R')
# source('R/scrape.R')

# One-way trip
scrape <- Scrape("JFK", "IST", "2026-07-20")
print(scrape)

# Round-trip
scrape <- Scrape("JFK", "IST", "2026-07-20", "2026-08-20")

# Chain-trip
scrape <- Scrape("JFK", "IST", "2026-08-20", "RDU", "LGA", "2026-12-25")

# Perfect-chain
scrape <- Scrape("JFK", "2026-09-20", "IST", "2026-09-25", "CDG", "2026-10-10", "JFK")

# Create Flight objects
flight1 <- Flight("2026-07-20", "JFKIST", "9:00AM", "5:00PM", 
                  "8 hr 0 min", "Nonstop", "150 kg CO2", "10% emissions", "$450")
flight2 <- Flight("2026-07-21", "ISTCDG", "10:00AM", "2:00PM", 
                  "4 hr 0 min", "Nonstop", "100 kg CO2", "5% emissions", "$300")
flight3 <- Flight("2026-07-22", "CDGJFK", "11:00AM", "1:00PM", 
                  "8 hr 0 min", "1 stop", "200 kg CO2", "15% emissions", "$500")

# Convert flights to data frame
df <- flights_to_dataframe(list(flight1, flight2, flight3))

# Scrape live data (requires chromote package)
install.packages(c("chromote", "progress"))
scrape <- ScrapeObjects(scrape)  # Must capture return value! Uses Chrome directly - no drivers!
print(scrape$data)
```

For more examples and detailed documentation, see [README.Rmd](README.Rmd).

## Flexible Date Search (NEW!)

The package now supports flexible date search across multiple airports and dates, making it easy to find the cheapest flights when you have flexibility in your travel plans.

```r
library(flightanalysis)
library(tibble)  # optional, for better data frame display

# Define routes to search
routes <- tribble(
  ~City,      ~Airport, ~Dest, ~Comment,
  "Mumbai",   "BOM",    "JFK", "Original flight",
  "Delhi",    "DEL",    "JFK", "",
  "Varanasi", "VNS",    "JFK", "",
  "Patna",    "PAT",    "JFK", "",
  "Gaya",     "GAY",    "JFK", ""
)

# Define date range
dates <- seq(as.Date("2025-12-18"), as.Date("2026-01-05"), by = "day")

# Scrape cheapest flights per day across all routes and dates
results <- fa_scrape_best_oneway(
  routes = routes,
  dates = dates,
  keep_offers = FALSE,  # Only keep cheapest per day
  pause = 3,            # Wait 3 seconds between requests
  verbose = TRUE
)

# Create wide summary table (City × Date with Average Price)
summary_table <- fa_flex_table(results)
print(summary_table)

# Find the top 10 cheapest dates
best_dates <- fa_best_dates(results, n = 10, by = "mean")
print(best_dates)
```

**Key Features:**
- Search multiple airports and dates in one function call
- Automatically filters out placeholder rows ("Price graph", "Price unavailable")
- Create wide summary tables for easy price comparison
- Identify cheapest travel dates automatically
- Built-in rate limiting to be respectful of Google Flights
- Optional currency formatting with the `scales` package

## Updates & New Features

**November 2025**: 
- ✅ Full R package implementation with equivalent functionality to the Python version!
- ✅ Complete web scraping with **chromote** - driver-free browser automation
- ✅ No more driver installation/compatibility issues - uses Chrome DevTools Protocol directly
- ✅ Headless mode support for server environments

Performing a complete revamp of this package, including new addition to PyPI. Documentation is being updated frequently, contact for any questions.


<!--
## Cache Data

The caching system for this application is mainly designed to make the loading of data more efficient. For the moment, this component of the application hasn't been designed well for the public to easily use so I would suggest that most people leave it alone, or fork the repository and modify some of the functions to create folders in the destinations that they would prefer. The key caching functions are:

- `cache_data`
- `load_cached`
- `iterative_caching`
- `clean_cache`
- `cache_condition`
- `check_cached`

All of these functions are clearly documented in the `scraping.py` file.
-->
<!--## To Do

- [x] Scrape data and clean it
- [x] Testing for scraping
- [x] Add scraping docs
- [ ] Split Airlines
- [ ] Add day of week as a feature
- [ ] Support for Day of booking!! ("Delayed by x hr")
- [ ] Detail most common airports and automatically cache
- [ ] Algorithm to check over multiple days and return summary
- [x] Determine caching method: wait for request and cache? periodically cache?
- [ ] Model for observing change in flight price
	- Predict how much it'll maybe change
- [ ] UI for showing flights that are 'perfect' to constraint / flights that are close to constraints, etc
- [ ] Caching/storing data, uses predictive model to estimate how good this is

-->
## Real Usage

Here are some great flights I was able to find and actually booked when planning my travel/vacations:

- NYC ➡️ AMS (May 9), AMS ➡️ IST (May 12), IST ➡️ NYC (May 23) | Trip Total: $611 as of March 7, 2022
