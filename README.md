
# Flight Analysis - R Package

[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An R package for analyzing, forecasting, and collecting flight data and
prices from Google Flights.

## Features

- Detailed scraping and querying tools for Google Flights using chromote
- Support for multiple trip types: one-way, round-trip, chain-trip, and
  perfect-chain
- Flexible date search across multiple airports and date ranges
- Summary tables showing prices by city and date
- Automatic identification of cheapest travel dates

## Installation

You can install the development version of flightanalysis from GitHub:

``` r
install.packages('flightanalysis', 
  repos = c('https://rempsyc.r-universe.dev', 'https://cloud.r-project.org'))

# Or if you need the version from the last hour, install through `remotes`
# install.packages("remotes")
remotes::install_github("rempsyc/flightanalysis")
```

## Usage

### Loading the Package

``` r
library(flightanalysis)
```

### Creating Flight Queries and Fetching the Data

The main scraping function that makes up the backbone of most
functionalities is `fa_define_query()`. It serves as a data object,
preserving the flight information as well as meta-data from your query.
`fa_fetch_flights()` then fetches flight information from that query.

``` r
# Round-trip
query <- fa_define_query("JFK", "IST", "2025-12-20", "2026-01-05")
query
```

    ## Flight Query( {Not Yet Fetched}
    ## 2025-12-20: JFK --> IST
    ## 2026-01-05: IST --> JFK
    ## )

``` r
# Fetch the flight data
flights <- fa_fetch_flights(query)
```

    ##   Segment 1/2: JFK -> IST on 2025-12-20
    ##   [OK] Successfully parsed 8 flights
    ##   Segment 2/2: IST -> JFK on 2026-01-05
    ##   [OK] Successfully parsed 8 flights
    ##   [OK] Total flights retrieved: 16

``` r
# View the flight data
head(flights$data) |>
  knitr::kable()
```

| departure_datetime | arrival_datetime | origin | destination | airlines | travel_time | price | num_stops | layover | access_date | co2_emission_kg | emission_diff_pct |
|:---|:---|:---|:---|:---|:---|---:|---:|:---|:---|---:|---:|
| 2025-12-20 22:35:00 | 2025-12-22 00:40:00 | JFK | IST | LOT | 18 hr 5 min | 1475 | 1 | 6 hr 50 min WAW | 2025-11-15 11:44:34 | 633 | NA |
| 2025-12-20 21:20:00 | 2025-12-21 16:55:00 | JFK | IST | KLMDelta | 11 hr 35 min | 1770 | 1 | 1 hr 5 min AMS | 2025-11-15 11:44:34 | 444 | NA |
| 2025-12-20 00:20:00 | 2025-12-20 18:10:00 | JFK | IST | Turkish AirlinesJetBlue | 9 hr 50 min | 1921 | 0 | NA | 2025-11-15 11:44:34 | 528 | NA |
| 2025-12-20 12:50:00 | 2025-12-21 06:45:00 | JFK | IST | Turkish Airlines | 9 hr 55 min | 1952 | 0 | NA | 2025-11-15 11:44:34 | 414 | NA |
| 2025-12-20 20:05:00 | 2025-12-21 14:05:00 | JFK | IST | Price graph | 10 hr | 1982 | 0 | NA | 2025-11-15 11:44:34 | 528 | NA |
| 2025-12-20 01:00:00 | 2025-12-21 03:50:00 | JFK | IST | Air FranceDelta, KLM | 18 hr 50 min | 1469 | 1 | 8 hr 15 min CDG | 2025-11-15 11:44:34 | 551 | 0 |

The package supports multiple trip types:

- **One-way**: `fa_define_query("JFK", "IST", "2025-07-20")`
- **Round-trip**:
  `fa_define_query("JFK", "IST", "2025-07-20", "2025-08-20")`
- **Chain-trip**:
  `fa_define_query("JFK", "IST", "2025-08-20", "RDU", "LGA", "2025-12-25")`
- **Perfect-chain**:
  `fa_define_query("JFK", "2025-09-20", "IST", "2025-09-25", "JFK")`

## Flexible Date Search

The package supports flexible date search across multiple airports and
dates:

``` r
# Create query objects for multiple origins and dates
queries <- fa_define_query_range(
  origin = c("BOM", "DEL"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2025-12-22"
)

# Fetch all flights
flights <- fa_fetch_flights(queries)
```

    ## Scraping 2 objects...
    ## 
    ## [1/2]   Segment 1/5: BOM -> JFK on 2025-12-18
    ##   [OK] Successfully parsed 13 flights
    ##   Segment 2/5: BOM -> JFK on 2025-12-19
    ##   [OK] Successfully parsed 12 flights
    ##   Segment 3/5: BOM -> JFK on 2025-12-20
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 4/5: BOM -> JFK on 2025-12-21
    ##   [OK] Successfully parsed 8 flights
    ##   Segment 5/5: BOM -> JFK on 2025-12-22
    ##   [OK] Successfully parsed 8 flights
    ##   [OK] Total flights retrieved: 50
    ## [2/2]   Segment 1/5: DEL -> JFK on 2025-12-18
    ##   [OK] Successfully parsed 8 flights
    ##   Segment 2/5: DEL -> JFK on 2025-12-19
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 3/5: DEL -> JFK on 2025-12-20
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 4/5: DEL -> JFK on 2025-12-21
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 5/5: DEL -> JFK on 2025-12-22
    ##   [OK] Successfully parsed 9 flights
    ##   [OK] Total flights retrieved: 45

``` r
# Create summary table (City × Date with prices)
fa_summarize_prices(flights) |>
  knitr::kable()
```

| City | Origin | 2025-12-18 | 2025-12-19 | 2025-12-20 | 2025-12-21 | 2025-12-22 | Average_Price |
|:---|:---|:---|:---|:---|:---|:---|:---|
| Mumbai | BOM | \$361 | \$365 | \$478 | \$413 | \$413 | \$406 |
| Delhi | DEL | \$361 | \$361 | \$463 | \$463 | \$373 | \$404 |
| Best | Day | X |  |  |  |  |  |

``` r
# Find the cheapest dates
fa_find_best_dates(
  flights, 
  n = 5,
  by = "min",
  price_max = 1400,
  max_stops = 1,
  travel_time_max = 26  # 26 hours (numeric = hours, or use "26 hr" format)
  ) |>
  knitr::kable()
```

| departure_date | departure_time | origin | price | num_stops | layover | travel_time | co2_emission_kg | airlines | n_routes |
|:---|:---|:---|---:|---:|:---|:---|---:|:---|---:|
| 2025-12-18 | 01:30:00 | DEL | 408 | 1 | 2 hr CDG | 19 hr 45 min | 794 | Air FranceDelta, KLM | 1 |
| 2025-12-18 | 02:00:00 | DEL | 577 | 0 | NA | 17 hr 30 min | 747 | Air India | 1 |
| 2025-12-18 | 02:20:00 | BOM | 438 | 1 | 2 hr 45 min CDG | 21 hr 5 min | 749 | Air FranceDelta, KLM | 1 |
| 2025-12-18 | 04:25:00 | DEL | 463 | 1 | 2 hr 45 min AUH | 21 hr 30 min | 871 | Etihad | 1 |
| 2025-12-18 | 04:40:00 | BOM | 413 | 1 | 3 hr 15 min AUH | 21 hr 15 min | 852 | Etihad | 1 |

## Original Python Package

**Credits:** This package is an R implementation inspired by the
original Python package
[google-flight-analysis](https://github.com/celebi-pkg/flight-analysis)
by Kaya Celebi.
