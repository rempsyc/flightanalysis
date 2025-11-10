
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

- Detailed scraping and querying tools for Google Flights using chromote
- Support for multiple trip types: one-way, round-trip, chain-trip, and perfect-chain
- Driver-free web scraping using Chrome DevTools Protocol
- **NEW:** Flexible date search across multiple airports and date ranges
- **NEW:** Summary tables showing prices by city and date with average calculations
- **NEW:** Automatic identification of cheapest travel dates

## Installation

You can install the development version of flightanalysis from GitHub:

``` r
# Install devtools if you haven't already
# install.packages("devtools")

# Install flightanalysis
devtools::install_github("rempsyc/flightanalysis")
```

    ## Using GitHub PAT from the git credential store.

    ## Downloading GitHub repo rempsyc/flightanalysis@HEAD

    ## ── R CMD build ─────────────────────────────────────────────────────────────────
    ##          checking for file 'C:\Users\there\AppData\Local\Temp\RtmpUbeWk7\remotesb0bc439a3fa6\rempsyc-flightanalysis-42cffe0/DESCRIPTION' ...  ✔  checking for file 'C:\Users\there\AppData\Local\Temp\RtmpUbeWk7\remotesb0bc439a3fa6\rempsyc-flightanalysis-42cffe0/DESCRIPTION' (505ms)
    ##       ─  preparing 'flightanalysis':
    ##    checking DESCRIPTION meta-information ...  ✔  checking DESCRIPTION meta-information
    ##       ─  checking for LF line-endings in source and make files and shell scripts (464ms)
    ##   ─  checking for empty or unneeded directories
    ##      Omitted 'LazyData' from DESCRIPTION
    ##       ─  building 'flightanalysis_1.0.0.tar.gz'
    ##      
    ## 

    ## Installing package into 'C:/Users/there/AppData/Local/R/win-library/4.5'
    ## (as 'lib' is unspecified)

## Usage

### Loading the Package

``` r
library(flightanalysis)
```

### Creating Flight Queries

The main scraping function that makes up the backbone of most
functionalities is `Scrape()`. It serves as a data object, preserving
the flight information as well as meta-data from your query.

#### One-Way Trip

``` r
# Create a one-way flight query
scrape <- Scrape("JFK", "IST", "2025-07-20")
scrape
```

    ## Scrape( {Query Not Yet Used}
    ## 2025-07-20: JFK --> IST
    ## )

#### Round-Trip

``` r
# Create a round-trip flight query
scrape <- Scrape("JFK", "IST", "2025-07-20", "2025-08-20")
scrape
```

    ## Scrape( {Query Not Yet Used}
    ## 2025-07-20: JFK --> IST
    ## 2025-08-20: IST --> JFK
    ## )

#### Chain-Trip

Chain-trips are defined as a sequence of one-way flights that have no
direct relation to each other, other than being in chronological order.

``` r
# Chain-trip format: origin, dest, date, origin, dest, date, ...
scrape <- Scrape("JFK", "IST", "2025-08-20", "RDU", "LGA", "2025-12-25", "EWR", "SFO", "2026-01-20")
scrape
```

    ## Scrape( {Query Not Yet Used}
    ## 2025-08-20: JFK --> IST
    ## 2025-12-25: RDU --> LGA
    ## 2026-01-20: EWR --> SFO
    ## )

#### Perfect-Chain

Perfect-chains are defined as a sequence of one-way flights such that
the destination of the previous flight is the origin of the next, and
the origin of the chain is the final destination (a cycle).

``` r
# Perfect-chain format: origin, date, origin, date, ..., first_origin
scrape <- Scrape("JFK", "2025-09-20", "IST", "2025-09-25", "CDG", "2025-10-10", "LHR", "2025-11-01", "JFK")
scrape
```

    ## Scrape( {Query Not Yet Used}
    ## 2025-09-20: JFK --> IST
    ## 2025-09-25: IST --> CDG
    ## 2025-10-10: CDG --> LHR
    ## 2025-11-01: LHR --> JFK
    ## )

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
    ##   Retrieved 154 lines of page content
    ##   Parsing 154 lines of content...
    ##   Found 18 potential flight time markers
    ##   Time markers at indices: 35, 37, 46, 48, 57, 59, 67, 69, 88, 90, 99, 101, 110, 112, 121, 123, 132, 134
    ##   Time marker values: 3:00 PM, 8:35 PM, 8:05 AM, 11:05 AM, 7:30 PM, 10:25 PM, 3:15 PM, 6:10 PM, 6:50 PM, 10:15 AM+1
    ##   After filtering: 9 markers (indices: 35, 46, 57, 67, 88)
    ##   Flight 1 data (range 35-45, 11 elements, has_times=TRUE): 3:00 PM |  | 8:35 PM...
    ##   Time elements found: 3:00 PM, 8:35 PM
    ##   Flight 1 parsed: 2 times captured (dep=OK, arr=OK)
    ##   Flight 2 data (range 46-56, 11 elements, has_times=TRUE): 8:05 AM |  | 11:05 AM...
    ##   Time elements found: 8:05 AM, 11:05 AM
    ##   Flight 2 parsed: 2 times captured (dep=OK, arr=OK)
    ##   Flight 3 data (range 57-66, 10 elements, has_times=TRUE): 7:30 PM |  | 10:25 PM...
    ##   Time elements found: 7:30 PM, 10:25 PM
    ##   Flight 3 parsed: 2 times captured (dep=OK, arr=OK)
    ##   [OK] Successfully parsed 8 flights
    ##   Segment 2/2: IST -> JFK on 2026-01-05
    ##   Navigating to Google Flights...
    ##   Waiting for page content to load...
    ##   Retrieved 175 lines of page content
    ##   Parsing 175 lines of content...
    ##   Found 22 potential flight time markers
    ##   Time markers at indices: 35, 37, 46, 48, 56, 58, 77, 79, 88, 90, 99, 101, 110, 112, 121, 123, 132, 134, 143, 145, 153, 155
    ##   Time marker values: 12:45 PM, 1:00 PM+1, 12:20 AM, 6:10 PM, 8:05 PM, 2:05 PM+1, 12:45 PM, 5:50 PM+1, 3:55 PM, 5:55 PM+1
    ##   After filtering: 11 markers (indices: 35, 46, 56, 77, 88)
    ##   Flight 1 data (range 35-45, 11 elements, has_times=TRUE): 12:45 PM |  | 1:00 PM+1...
    ##   Time elements found: 12:45 PM
    ##   Flight 1 parsed: 2 times captured (dep=OK, arr=OK)
    ##   Flight 2 data (range 46-55, 10 elements, has_times=TRUE): 12:20 AM |  | 6:10 PM...
    ##   Time elements found: 12:20 AM, 6:10 PM
    ##   Flight 2 parsed: 2 times captured (dep=OK, arr=OK)
    ##   Flight 3 data (range 56-76, 21 elements, has_times=TRUE): 8:05 PM |  | 2:05 PM+1...
    ##   Time elements found: 8:05 PM
    ##   Flight 3 parsed: 2 times captured (dep=OK, arr=OK)
    ##   [OK] Successfully parsed 10 flights
    ##   [OK] Total flights retrieved: 18
    ## 
    ## Closing browser...

``` r
# View the scraped data
head(scrape$data)
```

    ##    departure_datetime    arrival_datetime origin destination         airlines
    ## 1 2025-12-20 15:00:00 2025-12-20 20:35:00    IST         JFK              LOT
    ## 2 2025-12-20 08:05:00 2025-12-20 11:05:00    IST         JFK Turkish Airlines
    ## 3 2025-12-20 19:30:00 2025-12-20 22:25:00    IST         JFK Turkish Airlines
    ## 4 2025-12-20 15:15:00 2025-12-20 18:10:00    IST         JFK      Price graph
    ## 5 2025-12-20 18:50:00 2025-12-21 10:15:00    IST         JFK         EgyptAir
    ## 6 2025-12-20 14:05:00 2025-12-21 16:15:00    IST         JFK  Royal Jordanian
    ##    travel_time price num_stops         layover         access_date
    ## 1 13 hr 35 min   551         1 1 hr 15 min WAW 2025-11-10 10:54:59
    ## 2        11 hr   648         0            <NA> 2025-11-10 10:54:59
    ## 3 10 hr 55 min   648         0            <NA> 2025-11-10 10:54:59
    ## 4 10 hr 55 min   668         0            <NA> 2025-11-10 10:54:59
    ## 5 23 hr 25 min   552         1 9 hr 25 min CAI 2025-11-10 10:54:59
    ## 6 34 hr 10 min   574         1 19 hr 5 min AMM 2025-11-10 10:54:59
    ##   co2_emission_kg emission_diff_pct
    ## 1             593                18
    ## 2             375               -25
    ## 3             479                 0
    ## 4             479                 0
    ## 5             715                42
    ## 6             717                43

The `ScrapeObjects()` function will: 1. **Run pre-flight checks** -
Verify Chrome installation and internet connectivity 2. **Automatically
connect to Chrome** - Using Chrome DevTools Protocol (no drivers!) 3.
**Navigate to Google Flights URLs** - With proper wait times for page
loading 4. **Extract flight information** - Parse prices, times,
airlines, stops, and emissions 5. **Store results** - Save data in the
Scrape object’s `data` field 6. **Handle errors gracefully** - Provide
detailed troubleshooting tips if issues occur

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

    ##    departure_datetime    arrival_datetime origin destination airlines
    ## 1 2025-12-25 09:00:00 2025-12-25 17:00:00    JFK         IST       NA
    ## 2 2025-12-26 10:00:00 2025-12-26 14:00:00    IST         CDG       NA
    ## 3 2025-12-27 11:00:00 2025-12-27 13:00:00    CDG         JFK       NA
    ##   travel_time price num_stops layover         access_date co2_emission_kg
    ## 1  8 hr 0 min   450         0      NA 2025-11-10 10:55:03             150
    ## 2  4 hr 0 min   300         0      NA 2025-11-10 10:55:03             100
    ## 3  8 hr 0 min   500         1      NA 2025-11-10 10:55:03             200
    ##   emission_diff_pct
    ## 1                10
    ## 2                 5
    ## 3                15

## Trip Types

The package supports multiple trip types:

- **One-way**: Single flight from origin to destination
- **Round-trip**: Flight to destination and return
- **Chain-trip**: Sequence of unrelated one-way flights in chronological
  order
- **Perfect-chain**: Sequence where each destination becomes the next
  origin, forming a cycle

## Package Structure

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
# This creates a chain-trip Scrape object and uses ScrapeObjects() internally
results <- fa_scrape_best_oneway(
  routes = routes,
  dates = dates,
  keep_offers = FALSE,  # Only keep cheapest per day
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
- **Efficient batching**: Creates a single chain-trip Scrape object, reducing browser initialization overhead
- **Two-step workflow**: (1) Create Scrape object with `fa_create_date_range_scrape()`, (2) Scrape with `ScrapeObjects()`, (3) Analyze with filter functions
- Search multiple airports and dates in one function call
- Automatically filters out placeholder rows ("Price graph", "Price unavailable")
- Create wide summary tables for easy price comparison
- Identify cheapest travel dates automatically
- Optional currency formatting with the `scales` package

**Advanced Usage:**
```r
# For more control, create Scrape object separately
scrape <- fa_create_date_range_scrape(
  airports = c("BOM", "DEL", "VNS"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2026-01-05"
)

# Then scrape when ready
scrape <- ScrapeObjects(scrape, verbose = TRUE)

# Filter and analyze the results
results <- scrape$data
# ... apply custom filters or use fa_flex_table(), fa_best_dates()
```

## Updates & New Features

**November 2025**: 
- ✅ Full R package implementation with equivalent functionality to the Python version!
- ✅ Complete web scraping with **chromote** - driver-free browser automation
- ✅ No more driver installation/compatibility issues - uses Chrome DevTools Protocol directly
- ✅ Headless mode support for server environments
- ✅ **NEW:** Flexible date search with `fa_scrape_best_oneway()` for searching multiple airports and dates
- ✅ **NEW:** Wide summary tables with `fa_flex_table()` for easy price comparison
- ✅ **NEW:** Best date identification with `fa_best_dates()` for finding cheapest travel dates

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
