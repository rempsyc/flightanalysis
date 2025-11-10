# Flight Analysis - R Package

An R package for analyzing, forecasting, and collecting flight data and
prices from Google Flights.

**Credits:** This is an R implementation inspired by the original
[Python package](https://github.com/celebi-pkg/flightanalysis) by Kaya
Celebi.

## Features

- Detailed scraping and querying tools for Google Flights using chromote
- Ability to store data locally or to SQL tables
- Support for multiple trip types: one-way, round-trip, chain-trip, and
  perfect-chain
- Driver-free web scraping using Chrome DevTools Protocol

## Installation

Install from GitHub:

``` r
# Install devtools if you haven't already
install.packages("devtools")

# Install flightanalysis
devtools::install_github("rempsyc/flightanalysis")
```

Or source files directly:

``` r
source('R/flight.R')
source('R/scrape.R')
source('R/cache.R')
```

## Usage

The R version provides similar functionality with R-native syntax:

``` r
# Load the package
library(flightanalysis)
# Or source files directly:
# source('R/flight.R')
# source('R/scrape.R')
# source('R/cache.R')

# One-way trip
scrape <- Scrape("JFK", "IST", "2026-07-20")
print(scrape)

# Round-trip
scrape <- Scrape("JFK", "IST", "2026-07-20", "2026-08-20")

# Chain-trip
scrape <- Scrape("JFK", "IST", "2026-08-20", "RDU", "LGA", "2026-12-25")

# Perfect-chain
scrape <- Scrape("JFK", "2026-09-20", "IST", "2026-09-25", "CDG", "2026-10-10", "JFK")

# Create a Flight object
flight <- Flight("2026-07-20", "JFKIST", "9:00AM", "5:00PM", 
                 "8 hr 0 min", "Nonstop", "150 kg CO2", "10% emissions", "$450")

# Convert flights to data frame
df <- flights_to_dataframe(list(flight1, flight2, flight3))

# Scrape live data (requires chromote package)
install.packages(c("chromote", "progress"))
scrape <- ScrapeObjects(scrape)  # Must capture return value! Uses Chrome directly - no drivers!
print(scrape$data)
```

For more examples and detailed documentation, see
[README.Rmd](https://rempsyc.github.io/flightanalysis/README.Rmd).

## Updates & New Features

**November 2025**: - ✅ Full R package implementation with equivalent
functionality to the Python version! - ✅ Complete web scraping with
**chromote** - driver-free browser automation - ✅ No more driver
installation/compatibility issues - uses Chrome DevTools Protocol
directly - ✅ Headless mode support for server environments

Performing a complete revamp of this package, including new addition to
PyPI. Documentation is being updated frequently, contact for any
questions.

## Real Usage

Here are some great flights I was able to find and actually booked when
planning my travel/vacations:

- NYC ➡️ AMS (May 9), AMS ➡️ IST (May 12), IST ➡️ NYC (May 23) \| Trip
  Total: \$611 as of March 7, 2022
