
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
- **NEW:** Flexible date search across multiple airports and date ranges
- **NEW:** Summary tables showing prices by city and date with average
  calculations
- **NEW:** Automatic identification of cheapest travel dates

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

#### One-Way Trip

``` r
# Create a one-way flight query
query <- fa_define_query("JFK", "IST", "2025-07-20")
query
```

    ## Flight Query( {Not Yet Fetched}
    ## 2025-07-20: JFK --> IST
    ## )

#### Round-Trip

``` r
# Create a round-trip flight query
query <- fa_define_query("JFK", "IST", "2025-07-20", "2025-08-20")
query
```

    ## Flight Query( {Not Yet Fetched}
    ## 2025-07-20: JFK --> IST
    ## 2025-08-20: IST --> JFK
    ## )

#### Chain-Trip

Chain-trips are defined as a sequence of one-way flights that have no
direct relation to each other, other than being in chronological order.

``` r
# Chain-trip format: origin, dest, date, origin, dest, date, ...
query <- fa_define_query("JFK", "IST", "2025-08-20", "RDU", "LGA", "2025-12-25", "EWR", "SFO", "2026-01-20")
query
```

    ## Flight Query( {Not Yet Fetched}
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
query <- fa_define_query("JFK", "2025-09-20", "IST", "2025-09-25", "CDG", "2025-10-10", "LHR", "2025-11-01", "JFK")
query
```

    ## Flight Query( {Not Yet Fetched}
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
query <- fa_define_query("JFK", "IST", "2025-12-20", "2026-01-05")

# Scrape the data (runs in headless mode by default)
query <- fa_fetch_flights(query)
```

    ##   Segment 1/2: JFK -> IST on 2025-12-20
    ##   [OK] Successfully parsed 8 flights
    ##   Segment 2/2: IST -> JFK on 2026-01-05
    ##   [OK] Successfully parsed 7 flights
    ##   [OK] Total flights retrieved: 15

``` r
# View the scraped data
head(query$data) |>
  knitr::kable()
```

| departure_datetime | arrival_datetime | origin | destination | airlines | travel_time | price | num_stops | layover | access_date | co2_emission_kg | emission_diff_pct |
|:---|:---|:---|:---|:---|:---|---:|---:|:---|:---|---:|---:|
| 2025-12-20 22:35:00 | 2025-12-22 00:40:00 | JFK | IST | LOT | 18 hr 5 min | 1475 | 1 | 6 hr 50 min WAW | 2025-11-12 17:15:33 | 633 | NA |
| 2025-12-20 21:20:00 | 2025-12-21 16:55:00 | JFK | IST | KLMDelta | 11 hr 35 min | 1770 | 1 | 1 hr 5 min AMS | 2025-11-12 17:15:33 | 444 | NA |
| 2025-12-20 00:20:00 | 2025-12-20 18:10:00 | JFK | IST | Turkish AirlinesJetBlue | 9 hr 50 min | 1921 | 0 | NA | 2025-11-12 17:15:33 | 528 | NA |
| 2025-12-20 12:50:00 | 2025-12-21 06:45:00 | JFK | IST | Turkish Airlines | 9 hr 55 min | 1952 | 0 | NA | 2025-11-12 17:15:33 | 414 | NA |
| 2025-12-20 20:05:00 | 2025-12-21 14:05:00 | JFK | IST | Price graph | 10 hr | 1982 | 0 | NA | 2025-11-12 17:15:33 | 528 | NA |
| 2025-12-20 01:00:00 | 2025-12-21 03:50:00 | JFK | IST | Air FranceDelta, KLM | 18 hr 50 min | 1469 | 1 | 8 hr 15 min CDG | 2025-11-12 17:15:33 | 551 | 0 |

The `fa_fetch_flights()` function will: 1. **Run pre-flight checks** -
Verify Chrome installation and internet connectivity 2. **Automatically
connect to Chrome** - Using Chrome DevTools Protocol (no drivers!) 3.
**Navigate to Google Flights URLs** - With proper wait times for page
loading 4. **Extract flight information** - Parse prices, times,
airlines, stops, and emissions 5. **Store results** - Save data in the
query object’s `data` field 6. **Handle errors gracefully** - Provide
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
    ## 1  8 hr 0 min   450         0      NA 2025-11-12 17:15:36             150
    ## 2  4 hr 0 min   300         0      NA 2025-11-12 17:15:36             100
    ## 3  8 hr 0 min   500         1      NA 2025-11-12 17:15:36             200
    ##   emission_diff_pct
    ## 1                10
    ## 2                 5
    ## 3                15

## Flexible Date Search (NEW!)

The package now supports flexible date search across multiple airports
and dates, making it easy to find the cheapest flights when you have
flexibility in your travel plans.

### Basic Workflow

``` r
# Step 1: Create query objects for all routes and dates
scrapes <- fa_create_date_range(
  origin = c("BOM", "DEL", "VNS", "PAT"),
  dest = "JFK",
  date_min = "2025-12-28",
  date_max = "2026-01-03"
)

# Step 2: Scrape each origin
scraped <- fa_fetch_flights(queries)
```

    ## Scraping 4 objects...
    ## 
    ## [1/4]   Segment 1/7: BOM -> JFK on 2025-12-28
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 2/7: BOM -> JFK on 2025-12-29
    ##   [OK] Successfully parsed 11 flights
    ##   Segment 3/7: BOM -> JFK on 2025-12-30
    ##   [OK] Successfully parsed 14 flights
    ##   Segment 4/7: BOM -> JFK on 2025-12-31
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 5/7: BOM -> JFK on 2026-01-01
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 6/7: BOM -> JFK on 2026-01-02
    ##   [OK] Successfully parsed 12 flights
    ##   Segment 7/7: BOM -> JFK on 2026-01-03
    ##   [OK] Successfully parsed 10 flights
    ##   [OK] Total flights retrieved: 77
    ## [2/4]   Segment 1/7: DEL -> JFK on 2025-12-28
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 2/7: DEL -> JFK on 2025-12-29
    ##   [OK] Successfully parsed 11 flights
    ##   Segment 3/7: DEL -> JFK on 2025-12-30
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 4/7: DEL -> JFK on 2025-12-31
    ##   [OK] Successfully parsed 11 flights
    ##   Segment 5/7: DEL -> JFK on 2026-01-01
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 6/7: DEL -> JFK on 2026-01-02
    ##   [OK] Successfully parsed 13 flights
    ##   Segment 7/7: DEL -> JFK on 2026-01-03
    ##   [OK] Successfully parsed 10 flights
    ##   [OK] Total flights retrieved: 72
    ## [3/4]   Segment 1/7: VNS -> JFK on 2025-12-28
    ##   [OK] Successfully parsed 13 flights
    ##   Segment 2/7: VNS -> JFK on 2025-12-29
    ##   [OK] Successfully parsed 13 flights
    ##   Segment 3/7: VNS -> JFK on 2025-12-30
    ##   [OK] Successfully parsed 13 flights
    ##   Segment 4/7: VNS -> JFK on 2025-12-31
    ##   [OK] Successfully parsed 15 flights
    ##   Segment 5/7: VNS -> JFK on 2026-01-01
    ##   [OK] Successfully parsed 13 flights
    ##   Segment 6/7: VNS -> JFK on 2026-01-02
    ##   [OK] Successfully parsed 8 flights
    ##   Segment 7/7: VNS -> JFK on 2026-01-03
    ##   [OK] Successfully parsed 10 flights
    ##   [OK] Total flights retrieved: 85
    ## [4/4]   Segment 1/7: PAT -> JFK on 2025-12-28
    ##   [OK] Successfully parsed 12 flights
    ##   Segment 2/7: PAT -> JFK on 2025-12-29
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 3/7: PAT -> JFK on 2025-12-30
    ##   [OK] Successfully parsed 14 flights
    ##   Segment 4/7: PAT -> JFK on 2025-12-31
    ##   [OK] Successfully parsed 8 flights
    ##   Segment 5/7: PAT -> JFK on 2026-01-01
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 6/7: PAT -> JFK on 2026-01-02
    ##   [OK] Successfully parsed 16 flights
    ##   Segment 7/7: PAT -> JFK on 2026-01-03
    ##   [OK] Successfully parsed 12 flights
    ##   [OK] Total flights retrieved: 81

``` r
# Step 3: Analyze directly with list of query objects

# Create wide summary table (City × Date with Average Price)
summary_table <- fa_summarize_prices(scraped)
summary_table |>
  knitr::kable()
```

| City | Airport | 2025-12-28 | 2025-12-29 | 2025-12-30 | 2025-12-31 | 2026-01-01 | 2026-01-02 | 2026-01-03 | Average_Price |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| BOM | BOM | \$ 693 | \$ 756 | \$ 773 | \$ 908 | \$1,055 | \$1,631 | \$1,492 | $1,044        |
|DEL  |DEL     |$ 605 |
| PAT | PAT | \$1,059 | \$1,166 | \$1,419 | \$1,490 | \$1,868 | \$2,471 | \$2,469 | $1,706        |
|VNS  |VNS     |$ 934 |

``` r
# Find the top 10 cheapest dates
best_dates <- fa_find_best_dates(scraped, n = 10, by = "mean")
best_dates |>
  knitr::kable()
```

| Date       |    Price | N_Routes |
|:-----------|---------:|---------:|
| 2025-12-28 | 1140.950 |       40 |
| 2025-12-29 | 1353.829 |       41 |
| 2025-12-30 | 1477.630 |       46 |
| 2025-12-31 | 1546.075 |       40 |
| 2026-01-01 | 2037.081 |       37 |
| 2026-01-02 | 2735.711 |       45 |
| 2026-01-03 | 3037.079 |       38 |

**Key Features:** - **Per-origin query objects**: Each origin gets its
own chain-trip query object (required due to strict date ordering in
chain-trips) - **Simple workflow**: (1) Create list of query objects
with `fa_create_date_range()`, (2) Scrape each with
`fa_fetch_flights()`, (3) Pass directly to analysis functions - **Direct
query object support**: `fa_summarize_prices()` and `fa_find_best_dates()` accept
lists of query objects directly - no manual data processing needed! -
Search multiple origin airports and dates efficiently - Automatically
leverages existing chain-trip functionality - Automatic filtering of
placeholder rows - Create wide summary tables for easy price
comparison - Identify cheapest travel dates automatically - Optional
currency formatting with the `scales` package

### Single Origin Example

``` r
# For single origin, returns one query object (not a list)
query <- fa_create_date_range(
  origin = "BOM",
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2026-01-05"
)

# Scrape directly
scraped <- fa_fetch_flights(query, verbose = TRUE)
```

    ##   Segment 1/19: BOM -> JFK on 2025-12-18
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 2/19: BOM -> JFK on 2025-12-19
    ##   [OK] Successfully parsed 11 flights
    ##   Segment 3/19: BOM -> JFK on 2025-12-20
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 4/19: BOM -> JFK on 2025-12-21
    ##   [OK] Successfully parsed 8 flights
    ##   Segment 5/19: BOM -> JFK on 2025-12-22
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 6/19: BOM -> JFK on 2025-12-23
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 7/19: BOM -> JFK on 2025-12-24
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 8/19: BOM -> JFK on 2025-12-25
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 9/19: BOM -> JFK on 2025-12-26
    ##   [OK] Successfully parsed 14 flights
    ##   Segment 10/19: BOM -> JFK on 2025-12-27
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 11/19: BOM -> JFK on 2025-12-28
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 12/19: BOM -> JFK on 2025-12-29
    ##   [OK] Successfully parsed 11 flights
    ##   Segment 13/19: BOM -> JFK on 2025-12-30
    ##   [OK] Successfully parsed 14 flights
    ##   Segment 14/19: BOM -> JFK on 2025-12-31
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 15/19: BOM -> JFK on 2026-01-01
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 16/19: BOM -> JFK on 2026-01-02
    ##   [OK] Successfully parsed 12 flights
    ##   Segment 17/19: BOM -> JFK on 2026-01-03
    ##   [OK] Successfully parsed 10 flights
    ##   Segment 18/19: BOM -> JFK on 2026-01-04
    ##   [OK] Successfully parsed 9 flights
    ##   Segment 19/19: BOM -> JFK on 2026-01-05
    ##   [OK] Successfully parsed 9 flights
    ##   [OK] Total flights retrieved: 193

``` r
# Analyze with helper functions
summary_table <- fa_summarize_prices(scraped)
summary_table |>
  knitr::kable()
```

| City | Airport | 2025-12-18 | 2025-12-19 | 2025-12-20 | 2025-12-21 | 2025-12-22 | 2025-12-23 | 2025-12-24 | 2025-12-25 | 2025-12-26 | 2025-12-27 | 2025-12-28 | 2025-12-29 | 2025-12-30 | 2025-12-31 | 2026-01-01 | 2026-01-02 | 2026-01-03 | 2026-01-04 | 2026-01-05 | Average_Price |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| BOM | BOM | \$361 | \$365 | \$413 | \$365 | \$342 | \$361 | \$373 | \$418 | \$563 | \$616 | \$693 | \$756 | \$773 | \$908 | \$1,055 | \$1,631 | \$1,492 | \$1,151 | \$1,364 | \$737 |

``` r
best_dates <- fa_find_best_dates(scraped, n = 5)
best_dates |>
  knitr::kable()
```

| Date       | Price | N_Routes |
|:-----------|------:|---------:|
| 2025-12-22 |   342 |        9 |
| 2025-12-18 |   361 |        8 |
| 2025-12-23 |   361 |        8 |
| 2025-12-19 |   365 |       10 |
| 2025-12-21 |   365 |        7 |

### Using fa_summarize_prices()

The `fa_summarize_prices()` function creates a wide summary table showing
prices by city/airport and date:

``` r
# Create summary table from scraped data
summary_table <- fa_summarize_prices(scraped)

# Optional: customize the output
summary_table <- fa_summarize_prices(
  scraped,
  include_comment = TRUE,     # Include comment column if available
  currency_symbol = "$",      # Currency symbol for formatting
  round_prices = TRUE         # Round prices to nearest integer
)
```

**Output format:** - Rows: One per city/airport combination - Columns:
One per date, plus an Average_Price column - Values: Minimum (cheapest)
price for each date - Automatically filters out placeholder rows (e.g.,
“Price graph”)

### Using fa_find_best_dates()

The `fa_find_best_dates()` function identifies the cheapest travel dates:

``` r
# Find the 10 cheapest dates by mean price
best_dates <- fa_find_best_dates(scraped, n = 10, by = "mean")
best_dates
```

    ##          Date    Price N_Routes
    ## 1  2025-12-18 403.2500        8
    ## 2  2025-12-22 443.2222        9
    ## 3  2025-12-23 467.1250        8
    ## 4  2025-12-21 472.2857        7
    ## 5  2025-12-24 498.5000        8
    ## 6  2025-12-19 514.4000       10
    ## 7  2025-12-20 555.8750        8
    ## 8  2025-12-25 569.1111        9
    ## 9  2025-12-26 695.6154       13
    ## 10 2025-12-27 833.5000        8

``` r
# Alternative aggregation methods
best_dates_median <- fa_find_best_dates(scraped, n = 5, by = "median")
best_dates_median
```

    ##         Date Price N_Routes
    ## 1 2025-12-18 376.5        8
    ## 2 2025-12-22 427.0        9
    ## 3 2025-12-21 436.0        7
    ## 4 2025-12-23 442.0        8
    ## 5 2025-12-24 474.0        8

``` r
best_dates_min <- fa_find_best_dates(scraped, n = 5, by = "min")
best_dates_min
```

    ##         Date Price N_Routes
    ## 1 2025-12-22   342        9
    ## 2 2025-12-18   361        8
    ## 3 2025-12-23   361        8
    ## 4 2025-12-19   365       10
    ## 5 2025-12-21   365        7

**Parameters:** - `n`: Number of best dates to return (default: 10) -
`by`: Aggregation method - “mean” (average), “median”, or “min”
(default: “mean”)

**Output:** - `Date`: The date - `Price`: Aggregated price
(mean/median/min depending on `by` parameter) - `N_Routes`: Number of
routes with data for that date

## Trip Types

The package supports multiple trip types:

- **One-way**: Single flight from origin to destination
- **Round-trip**: Flight to destination and return
- **Chain-trip**: Sequence of unrelated one-way flights in chronological
  order
- **Perfect-chain**: Sequence where each destination becomes the next
  origin, forming a cycle

## Updates & New Features

**November 2025**: - ✅ Full R package implementation with equivalent
functionality to the Python version! - ✅ Complete web scraping with
**chromote** - driver-free browser automation - ✅ No more driver
installation/compatibility issues - uses Chrome DevTools Protocol
directly - ✅ Headless mode support for server environments - ✅
**NEW:** Flexible date search with `fa_create_date_range()` for
searching multiple airports and dates - ✅ **NEW:** Wide summary tables
with `fa_summarize_prices()` for easy price comparison - ✅ **NEW:** Best date
identification with `fa_find_best_dates()` for finding cheapest travel dates

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
