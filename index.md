# Flight Analysis - R Package

[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An R package for analyzing, forecasting, and collecting flight data and
prices from Google Flights.

**Credits:** This package is an R implementation inspired by the
original Python package
[google-flight-analysis](https://github.com/celebi-pkg/flight-analysis)
by Kaya Celebi.

## Features

Current features include:

- Detailed scraping and querying tools for Google Flights
- Base analytical tools/methods for price forecasting/summary
- Support for multiple trip types: one-way, round-trip, chain-trip, and
  perfect-chain

## Installation

You can install the development version of flightanalysis from GitHub:

``` r
# Install devtools if you haven't already
# install.packages("devtools")

# Install flightanalysis
devtools::install_github("rempsyc/flightanalysis")
```

``` R
## Using GitHub PAT from the git credential store.

## Skipping install of 'flightanalysis' from a github remote, the SHA1 (4f4dc0b5) has not changed since last install.
##   Use `force = TRUE` to force installation
```

## Usage

### Loading the Package

``` r
library(flightanalysis)
```

### Creating Flight Queries

The main scraping function that makes up the backbone of most
functionalities is
[`Scrape()`](https://rempsyc.github.io/flightanalysis/reference/Scrape.md).
It serves as a data object, preserving the flight information as well as
meta-data from your query.

#### One-Way Trip

``` r
# Create a one-way flight query
scrape <- Scrape("JFK", "IST", "2025-07-20")
scrape
```

``` R
## Scrape( {Query Not Yet Used}
## 2025-07-20: JFK --> IST
## )
```

#### Round-Trip

``` r
# Create a round-trip flight query
scrape <- Scrape("JFK", "IST", "2025-07-20", "2025-08-20")
scrape
```

``` R
## Scrape( {Query Not Yet Used}
## 2025-07-20: JFK --> IST
## 2025-08-20: IST --> JFK
## )
```

#### Chain-Trip

Chain-trips are defined as a sequence of one-way flights that have no
direct relation to each other, other than being in chronological order.

``` r
# Chain-trip format: origin, dest, date, origin, dest, date, ...
scrape <- Scrape("JFK", "IST", "2025-08-20", "RDU", "LGA", "2025-12-25", "EWR", "SFO", "2026-01-20")
scrape
```

``` R
## Scrape( {Query Not Yet Used}
## 2025-08-20: JFK --> IST
## 2025-12-25: RDU --> LGA
## 2026-01-20: EWR --> SFO
## )
```

#### Perfect-Chain

Perfect-chains are defined as a sequence of one-way flights such that
the destination of the previous flight is the origin of the next, and
the origin of the chain is the final destination (a cycle).

``` r
# Perfect-chain format: origin, date, origin, date, ..., first_origin
scrape <- Scrape("JFK", "2025-09-20", "IST", "2025-09-25", "CDG", "2025-10-10", "LHR", "2025-11-01", "JFK")
scrape
```

``` R
## Scrape( {Query Not Yet Used}
## 2025-09-20: JFK --> IST
## 2025-09-25: IST --> CDG
## 2025-10-10: CDG --> LHR
## 2025-11-01: LHR --> JFK
## )
```

### Scraping Data

The package now includes full web scraping functionality using
**chromote**!

**Why chromote?** - ✅ No external driver files needed (uses Chrome
DevTools Protocol directly) - ✅ More reliable - no driver version
mismatches or port conflicts - ✅ Simpler installation - just install
the R package - ✅ Works on all platforms (Windows, macOS, Linux) - ✅
Fully headless by default

Then scrape flight data from Google Flights:

``` r
# Create a query
scrape <- Scrape("JFK", "IST", "2025-12-20", "2026-01-05")

# Scrape the data (runs in headless mode by default)
scrape <- ScrapeObjects(scrape)
```

``` R
## Running pre-flight checks...
## [OK] Chrome/Chromium detected
## [OK] Internet connection verified
## Initializing Chrome browser...
## [OK] Browser ready
## 
## Scraping 1 object(s)...
## 
## [1/1] Processing query...
##   Query has 2 segment(s)
##   Segment 1/2: JFK -> IST on 2025-12-20
##   Navigating to Google Flights...
##   Waiting for page content to load...
##   Retrieved 165 lines of page content
##   Parsing 165 lines of content...
##   Found 20 potential flight time markers
##   [OK] Successfully parsed 9 flights
##   Segment 2/2: IST -> JFK on 2026-01-05
##   Navigating to Google Flights...
##   Waiting for page content to load...
##   Retrieved 164 lines of page content
##   Parsing 164 lines of content...
##   Found 20 potential flight time markers
##   [OK] Successfully parsed 9 flights
##   [OK] Total flights retrieved: 18
## 
## Closing browser...
```

``` r
# View the scraped data
head(scrape$data)
```

``` R
##   departure_datetime arrival_datetime origin destination
## 1               <NA>             <NA>    IST         JFK
## 2               <NA>             <NA>    IST         JFK
## 3               <NA>             <NA>    IST         JFK
## 4               <NA>             <NA>    IST         JFK
## 5               <NA>             <NA>    IST         JFK
## 6               <NA>             <NA>    IST         JFK
##                                             airlines  travel_time price
## 1                                        593 kg CO2e 13 hr 35 min   551
## 2 Avoids as much CO2e as 7,731 trees absorb in a day        11 hr   648
## 3                                        479 kg CO2e 10 hr 55 min   648
## 4                                      Other flights 10 hr 55 min   668
## 5                                        715 kg CO2e 23 hr 25 min   552
## 6                                        717 kg CO2e 34 hr 10 min   574
##   num_stops         layover         access_date co2_emission_kg
## 1         1 1 hr 15 min WAW 2025-11-09 23:59:30              NA
## 2         0            <NA> 2025-11-09 23:59:30              NA
## 3         0            <NA> 2025-11-09 23:59:30              NA
## 4         0            <NA> 2025-11-09 23:59:30              NA
## 5         1 9 hr 25 min CAI 2025-11-09 23:59:30              NA
## 6         1 19 hr 5 min AMM 2025-11-09 23:59:30              NA
##   emission_diff_pct
## 1                18
## 2               -25
## 3                 0
## 4                 0
## 5                42
## 6                43
```

The
[`ScrapeObjects()`](https://rempsyc.github.io/flightanalysis/reference/ScrapeObjects.md)
function will: 1. **Run pre-flight checks** - Verify Chrome installation
and internet connectivity 2. **Automatically connect to Chrome** - Using
Chrome DevTools Protocol (no drivers!) 3. **Navigate to Google Flights
URLs** - With proper wait times for page loading 4. **Extract flight
information** - Parse prices, times, airlines, stops, and emissions 5.
**Store results** - Save data in the Scrape object’s `data` field 6.
**Handle errors gracefully** - Provide detailed troubleshooting tips if
issues occur

**Advantages over RSelenium:**

chromote eliminates common RSelenium issues: - ❌ No more “invalid
assignment for reference class field ‘port’” errors - ❌ No more driver
download/installation problems - ❌ No more version compatibility
issues - ❌ No more port conflicts - ✅ Just install chromote and it
works!

### Working with Flight Objects

``` r
# Create Flight objects
flight1 <- Flight("2025-12-25", "JFKIST", "9:00AM", "5:00PM", 
                  "8 hr 0 min", "Nonstop", "150 kg CO2", "10% emissions", "$450")
flight2 <- Flight("2025-12-26", "ISTCDG", "10:00AM", "2:00PM", 
                  "4 hr 0 min", "Nonstop", "100 kg CO2", "5% emissions", "$300")
flight3 <- Flight("2025-12-27", "CDGJFK", "11:00AM", "1:00PM", 
                  "8 hr 0 min", "1 stop", "200 kg CO2", "15% emissions", "$500")

# Convert multiple flights to a data frame
flights <- list(flight1, flight2, flight3)
df <- flights_to_dataframe(flights)
df
```

``` R
##    departure_datetime    arrival_datetime origin destination airlines
## 1 2025-12-25 09:00:00 2025-12-25 17:00:00    JFK         IST       NA
## 2 2025-12-26 10:00:00 2025-12-26 14:00:00    IST         CDG       NA
## 3 2025-12-27 11:00:00 2025-12-27 13:00:00    CDG         JFK       NA
##   travel_time price num_stops layover         access_date co2_emission_kg
## 1  8 hr 0 min   450         0      NA 2025-11-09 23:59:33             150
## 2  4 hr 0 min   300         0      NA 2025-11-09 23:59:33             100
## 3  8 hr 0 min   500         1      NA 2025-11-09 23:59:33             200
##   emission_diff_pct
## 1                10
## 2                 5
## 3                15
```

## Trip Types

The package supports multiple trip types:

- **One-way**: Single flight from origin to destination
- **Round-trip**: Flight to destination and return
- **Chain-trip**: Sequence of unrelated one-way flights in chronological
  order
- **Perfect-chain**: Sequence where each destination becomes the next
  origin, forming a cycle

## Package Structure

``` R
flightanalysis/
├── R/
│   ├── flight.R             # Flight class and methods
│   ├── scrape.R             # Scrape class and methods
│   └── flightanalysis-package.R  # Package documentation
├── tests/
│   └── testthat/            # Test files
│       ├── test-flight.R
│       └── test-scrape.R
├── DESCRIPTION              # Package metadata
├── NAMESPACE               # Package exports
└── README_R.md             # This file
```

## Differences from Python Version

This R package maintains the core functionality of the Python version
but with R-specific implementations:

- Uses S3 classes instead of Python classes
- chromote instead of Python’s selenium
- Base R data frames instead of pandas
- Native R date/time handling instead of Python’s datetime

## Development Status

This is a complete R port of the Python package. The core data
structures and API are fully implemented. Web scraping functionality
uses chromote (Chrome DevTools Protocol), which provides driver-free
browser automation without the configuration overhead of RSelenium.

## License

MIT License

## Original Python Package

This is a port of the
[google-flight-analysis](https://github.com/celebi-pkg/flight-analysis)
Python package by Kaya Celebi.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
