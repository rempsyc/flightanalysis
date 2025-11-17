# Flight Analysis: Find the best flights

An R package for analyzing, forecasting, and collecting flight data and
prices from Google Flights.

## Features

- Detailed scraping and querying tools for Google Flights using chromote
- Support for multiple trip types: one-way, round-trip, chain-trip, and
  perfect-chain
- Flexible date search across multiple airports and date ranges
- Summary tables showing prices by city and date
- Automatic identification of cheapest travel dates
- Visualization functions for price trends and best dates

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
functionalities is
[`fa_define_query()`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query.md).
It serves as a data object, preserving the flight information as well as
meta-data from your query.
[`fa_fetch_flights()`](https://rempsyc.github.io/flightanalysis/reference/fa_fetch_flights.md)
then fetches flight information from that query.

``` r
# Round-trip
query <- fa_define_query("JFK", "IST", "2025-12-20", "2026-01-05")
query
#> Flight Query( {Not Yet Fetched}
#> 2025-12-20: JFK --> IST
#> 2026-01-05: IST --> JFK
#> )

# Fetch the flight data
flights <- fa_fetch_flights(query)
#>   Segment 1/2: JFK -> IST on 2025-12-20
#>   [OK] Successfully parsed 7 flights
#>   Segment 2/2: IST -> JFK on 2026-01-05
#>   [OK] Successfully parsed 8 flights
#>   [OK] Total flights retrieved: 15

# View the flight data
head(flights$data[1:11]) |>
  knitr::kable()
```

| departure_date | departure_time | arrival_date | arrival_time | origin | destination | airlines             | travel_time  | price | num_stops | layover         |
|:---------------|:---------------|:-------------|:-------------|:-------|:------------|:---------------------|:-------------|------:|----------:|:----------------|
| 2025-12-20     | 22:35          | 2025-12-22   | 00:40        | JFK    | IST         | LOT                  | 18 hr 5 min  |  1475 |         1 | 6 hr 50 min WAW |
| 2025-12-20     | 21:20          | 2025-12-21   | 16:55        | JFK    | IST         | KLM, Delta           | 11 hr 35 min |  1770 |         1 | 1 hr 5 min AMS  |
| 2025-12-20     | 00:20          | 2025-12-20   | 18:10        | JFK    | IST         | Turkish Airlines     | 9 hr 50 min  |  1952 |         0 | NA              |
| 2025-12-20     | 12:50          | 2025-12-21   | 06:45        | JFK    | IST         | Turkish Airlines     | 9 hr 55 min  |  1952 |         0 | NA              |
| 2025-12-20     | 20:05          | 2025-12-21   | 14:05        | JFK    | IST         | Price graph          | 10 hr        |  1982 |         0 | NA              |
| 2025-12-20     | 23:30          | 2025-12-22   | 03:50        | JFK    | IST         | Air FranceDelta, KLM | 20 hr 20 min |  1469 |         1 | 9 hr 40 min CDG |

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
#> Scraping 2 objects...
#> 
#> [1/2]   Segment 1/5: BOM -> JFK on 2025-12-18
#>   [OK] Successfully parsed 13 flights
#>   Segment 2/5: BOM -> JFK on 2025-12-19
#>   [OK] Successfully parsed 11 flights
#>   Segment 3/5: BOM -> JFK on 2025-12-20
#>   [OK] Successfully parsed 8 flights
#>   Segment 4/5: BOM -> JFK on 2025-12-21
#>   [OK] Successfully parsed 8 flights
#>   Segment 5/5: BOM -> JFK on 2025-12-22
#>   [OK] Successfully parsed 9 flights
#>   [OK] Total flights retrieved: 49
#> [2/2]   Segment 1/5: DEL -> JFK on 2025-12-18
#>   [OK] Successfully parsed 8 flights
#>   Segment 2/5: DEL -> JFK on 2025-12-19
#>   [OK] Successfully parsed 9 flights
#>   Segment 3/5: DEL -> JFK on 2025-12-20
#>   [OK] Successfully parsed 10 flights
#>   Segment 4/5: DEL -> JFK on 2025-12-21
#>   [OK] Successfully parsed 8 flights
#>   Segment 5/5: DEL -> JFK on 2025-12-22
#>   [OK] Successfully parsed 9 flights
#>   [OK] Total flights retrieved: 44

# Create summary table (City × Date with prices)
fa_summarize_prices(flights) |>
  knitr::kable()
```

| City   | Origin | 2025-12-18 | 2025-12-19 | 2025-12-20 | 2025-12-21 | 2025-12-22 | Average_Price |
|:-------|:-------|:-----------|:-----------|:-----------|:-----------|:-----------|:--------------|
| Mumbai | BOM    | \$361      | \$365      | \$477      | \$413      | \$413      | \$406         |
| Delhi  | DEL    | \$361      | \$361      | \$463      | \$463      | \$386      | \$407         |
| Best   | Day    | X          |            |            |            |            |               |

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

| departure_date | departure_time | arrival_date | arrival_time | origin | price | num_stops | layover         | travel_time  | co2_emission_kg | airlines             | n_routes |
|:---------------|:---------------|:-------------|:-------------|:-------|------:|----------:|:----------------|:-------------|----------------:|:---------------------|---------:|
| 2025-12-18     | 01:30          | 2025-12-18   | 10:45        | DEL    |   408 |         1 | 2 hr CDG        | 19 hr 45 min |             794 | Air FranceDelta, KLM |        1 |
| 2025-12-18     | 04:40          | 2025-12-18   | 15:25        | BOM    |   413 |         1 | 3 hr 15 min AUH | 21 hr 15 min |             852 | Etihad               |        1 |
| 2025-12-19     | 04:40          | 2025-12-19   | 15:25        | BOM    |   365 |         1 | 3 hr 15 min AUH | 21 hr 15 min |             844 | Etihad               |        1 |
| 2025-12-19     | 20:55          | 2025-12-19   | 09:00        | DEL    |   392 |         1 | 3 hr 30 min AUH | 22 hr 35 min |             843 | Etihad               |        1 |
| 2025-12-19     | 23:15          | 2025-12-19   | 09:00        | BOM    |   413 |         1 | 2 hr 5 min AUH  | 20 hr 15 min |             763 | Akasa Air, Etihad    |        1 |

## Visualizing Price Data

The package includes plotting functions to visualize price trends and
best dates:

``` r
# Plot price trends across dates
fa_plot_prices(flights, 
               title = "Flight Prices: BOM/DEL to JFK",
               size_by = "travel_time",
               annotate_col = "travel_time")
```

![](reference/figures/README-plots-1.png)

``` r

# Plot best travel dates
fa_plot_best_dates(flights)
```

![](reference/figures/README-plots-2.png)

## Original Python Package

**Credits:** This package is an R implementation inspired by the
original Python package
[google-flight-analysis](https://github.com/celebi-pkg/flight-analysis)
by Kaya Celebi.
