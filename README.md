
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
query <- fa_define_query("JFK", "IST", "2025-12-18", "2026-01-02")

# Scrape the data
flights <- fa_fetch_flights(query)
```

    ##   Segment 1/2: JFK -> IST on 2025-12-18
    ##   [OK] Successfully parsed 7 flights
    ##   Segment 2/2: IST -> JFK on 2026-01-02
    ##   [OK] Successfully parsed 8 flights
    ##   [OK] Total flights retrieved: 15

``` r
# View the scraped data
head(flights$data) |>
  knitr::kable()
```

| departure_datetime | arrival_datetime | origin | destination | airlines | travel_time | price | num_stops | layover | access_date | co2_emission_kg | emission_diff_pct |
|:---|:---|:---|:---|:---|:---|---:|---:|:---|:---|---:|---:|
| 2025-12-18 21:20:00 | 2025-12-19 16:55:00 | JFK | IST | KLMDelta | 11 hr 35 min | 1470 | 1 | 1 hr 5 min AMS | 2025-11-13 19:38:30 | 444 | NA |
| 2025-12-18 00:20:00 | 2025-12-18 18:10:00 | JFK | IST | Turkish AirlinesJetBlue | 9 hr 50 min | 1692 | 0 | NA | 2025-11-13 19:38:30 | 528 | NA |
| 2025-12-18 12:50:00 | 2025-12-19 06:45:00 | JFK | IST | Turkish Airlines | 9 hr 55 min | 1692 | 0 | NA | 2025-11-13 19:38:30 | 414 | NA |
| 2025-12-18 20:05:00 | 2025-12-19 14:05:00 | JFK | IST | Price graph | 10 hr | 1722 | 0 | NA | 2025-11-13 19:38:30 | 528 | NA |
| 2025-12-18 01:00:00 | 2025-12-19 03:50:00 | JFK | IST | Air FranceDelta, KLM | 18 hr 50 min | 1244 | 1 | 8 hr 15 min CDG | 2025-11-13 19:38:30 | 551 | 0 |
| 2025-12-18 16:40:00 | 2025-12-19 16:55:00 | JFK | IST | Delta, KLM | 16 hr 15 min | 1470 | 1 | 5 hr 40 min AMS | 2025-11-13 19:38:30 | 450 | NA |

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
  date_max = "2025-12-20"
)
queries
```

    ## $BOM
    ## Flight Query( {Not Yet Fetched}
    ## 2025-12-18: BOM --> JFK
    ## 2025-12-19: BOM --> JFK
    ## 2025-12-20: BOM --> JFK
    ## )
    ## $DEL
    ## Flight Query( {Not Yet Fetched}
    ## 2025-12-18: DEL --> JFK
    ## 2025-12-19: DEL --> JFK
    ## 2025-12-20: DEL --> JFK
    ## )

``` r
# Scrape all queries
flights <- fa_fetch_flights(queries)
```

    ## Scraping 2 objects...
    ## 
    ## [1/2]   Segment 1/3: BOM -> JFK on 2025-12-18
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 2/3: BOM -> JFK on 2025-12-19
    ##   [OK] Successfully parsed 11 flights
    ##   Segment 3/3: BOM -> JFK on 2025-12-20
    ##   [OK] Successfully parsed 9 flights
    ##   [OK] Total flights retrieved: 29
    ## [2/2]   Segment 1/3: DEL -> JFK on 2025-12-18
    ##   [OK] Successfully parsed 8 flights
    ##   Segment 2/3: DEL -> JFK on 2025-12-19
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 3/3: DEL -> JFK on 2025-12-20
    ##   [OK] Successfully parsed 8 flights
    ##   [OK] Total flights retrieved: 26

``` r
# Create summary table (City × Date with prices)
fa_summarize_prices(flights) |>
  knitr::kable()
```

| City | Airport | 2025-12-18 | 2025-12-19 | 2025-12-20 | Average_Price |
|:-----|:--------|:-----------|:-----------|:-----------|:--------------|
| BOM  | BOM     | \$360      | \$401      | \$463      | \$408         |
| DEL  | DEL     | \$361      | \$361      | \$412      | \$378         |

``` r
# Find the cheapest dates
fa_find_best_dates(flights, by = "min") |>
  knitr::kable()
```

| Date       | Price | N_Routes |
|:-----------|------:|---------:|
| 2025-12-18 |   360 |       15 |
| 2025-12-19 |   361 |       19 |
| 2025-12-20 |   412 |       15 |

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
