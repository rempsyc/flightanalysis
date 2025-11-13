
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
- Support for multiple trip types: one-way, round-trip, chain-trip, and
  perfect-chain
- Driver-free web scraping using Chrome DevTools Protocol
- Flexible date search across multiple airports and date ranges
- Summary tables showing prices by city and date
- Automatic identification of cheapest travel dates

## Installation

You can install the development version of flightanalysis from GitHub:

``` r
# Install devtools if you haven't already
# install.packages("devtools")

# Install flightanalysis
devtools::install_github("rempsyc/flightanalysis")
```

## Usage

### Loading the Package

``` r
library(flightanalysis)
```

### Sample Datasets

The package includes sample datasets for testing and learning without
making API calls:

``` r
# Load sample flight query
data(sample_query)
print(sample_query)
```

    ## Flight Query( {Not Yet Fetched}
    ## 2025-12-20: JFK --> IST
    ## 2025-12-27: IST --> JFK
    ## )

``` r
# Load sample flight data (scraped flights)
data(sample_flights)
head(sample_flights)
```

    ##    departure_datetime    arrival_datetime origin destination
    ## 1 2025-12-20 14:00:00 2025-12-21 03:00:00    JFK         IST
    ## 2 2025-12-20 19:30:00 2025-12-21 08:45:00    JFK         IST
    ## 3 2025-12-21 03:00:00 2025-12-21 16:30:00    JFK         IST
    ## 4 2025-12-21 15:15:00 2025-12-22 04:30:00    JFK         IST
    ## 5 2025-12-27 13:30:00 2025-12-28 02:15:00    IST         JFK
    ## 6 2025-12-27 20:45:00 2025-12-28 10:00:00    IST         JFK
    ##              airlines  travel_time price num_stops         layover
    ## 1    Turkish Airlines  13 hr 0 min   650         0            <NA>
    ## 2           Lufthansa 13 hr 15 min   720         1 2 hr 30 min FRA
    ## 3 LOT Polish Airlines 13 hr 30 min   580         1 3 hr 15 min WAW
    ## 4          Air France 13 hr 15 min   695         1 2 hr 45 min CDG
    ## 5    Turkish Airlines 12 hr 45 min   620         0            <NA>
    ## 6     United Airlines 13 hr 15 min   685         1 3 hr 10 min EWR
    ##           access_date co2_emission_kg emission_diff_pct
    ## 1 2025-11-13 23:35:40             550                 5
    ## 2 2025-11-13 23:35:40             580                10
    ## 3 2025-11-13 23:35:40             600                15
    ## 4 2025-11-13 23:35:40             570                 8
    ## 5 2025-11-13 23:35:40             540                 3
    ## 6 2025-11-13 23:35:40             575                 9

``` r
# Load sample multi-origin queries
data(sample_multi_origin)
names(sample_multi_origin)
```

    ## [1] "BOM" "DEL"

These datasets are useful for: - Testing analysis functions like
`fa_find_best_dates()` and `fa_summarize_prices()` offline - Learning
the package structure without internet access - Running examples in
documentation

### Creating Flight Queries

The main scraping function that makes up the backbone of most
functionalities is `fa_define_query()`. It serves as a data object,
preserving the flight information as well as meta-data from your query.

``` r
# Round-trip
query <- fa_define_query("JFK", "IST", "2025-07-20", "2025-08-20")
query
```

    ## Flight Query( {Not Yet Fetched}
    ## 2025-07-20: JFK --> IST
    ## 2025-08-20: IST --> JFK
    ## )

The package supports multiple trip types:

- **One-way**: `fa_define_query("JFK", "IST", "2025-07-20")`
- **Round-trip**:
  `fa_define_query("JFK", "IST", "2025-07-20", "2025-08-20")`
- **Chain-trip**:
  `fa_define_query("JFK", "IST", "2025-08-20", "RDU", "LGA", "2025-12-25")`
- **Perfect-chain**:
  `fa_define_query("JFK", "2025-09-20", "IST", "2025-09-25", "JFK")`

### Scraping Data

The package includes full web scraping functionality using **chromote**:

``` r
# Create a query
query <- fa_define_query("JFK", "IST", "2025-12-20", "2026-01-05")

# Scrape the data (runs in headless mode by default)
query <- fa_fetch_flights(query)

# View the scraped data
head(query$data)
```

**Why chromote?** - ✅ No external driver files needed (uses Chrome
DevTools Protocol directly) - ✅ More reliable - no driver version
mismatches or port conflicts - ✅ Works on all platforms (Windows,
macOS, Linux) - ✅ Fully headless by default

## Flexible Date Search

The package supports flexible date search across multiple airports and
dates:

``` r
# Create query objects for multiple origins and dates
queries <- fa_create_date_range(
  origin = c("BOM", "DEL"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2025-12-22"
)

# Scrape all queries
scraped <- fa_fetch_flights(queries)

# Create summary table (City × Date with prices)
summary_table <- fa_summarize_prices(scraped)

# Find the cheapest dates
best_dates <- fa_find_best_dates(scraped, n = 5, by = "mean")
```

**Key Features:** - Search multiple origin airports and dates
efficiently - Create wide summary tables for easy price comparison -
Identify cheapest travel dates automatically - Direct query object
support - no manual data processing needed

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
