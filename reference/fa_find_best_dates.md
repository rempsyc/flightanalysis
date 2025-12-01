# Find Best Travel Dates

Identifies and returns the top N dates with the cheapest average prices
across all routes. This helps quickly identify the best travel dates
when planning a flexible trip. Supports filtering by various criteria
such as departure time, airlines, travel time, stops, and emissions.

## Usage

``` r
fa_find_best_dates(
  flight_results,
  n = 10,
  by = "min",
  time_min = NULL,
  time_max = NULL,
  airlines = NULL,
  price_min = NULL,
  price_max = NULL,
  travel_time_max = NULL,
  max_stops = NULL,
  max_layover = NULL,
  max_emissions = NULL,
  excluded_airports = NULL
)
```

## Arguments

- flight_results:

  A flight_results object from fa_fetch_flights(). This function no
  longer accepts data frames or query objects directly.

- n:

  Integer. Number of best dates to return. Default is 10.

- by:

  Character. How to calculate best dates: "mean" (average price across
  routes), "median", or "min" (lowest price on that date). Default is
  "min".

- time_min:

  Character. Minimum departure time in "HH:MM" format (24-hour). Filters
  flights departing at or after this time. Default is NULL (no filter).

- time_max:

  Character. Maximum departure time in "HH:MM" format (24-hour). Filters
  flights departing at or before this time. Default is NULL (no filter).

- airlines:

  Character vector. Filter by specific airlines. Default is NULL (no
  filter).

- price_min:

  Numeric. Minimum price. Default is NULL (no filter).

- price_max:

  Numeric. Maximum price. Default is NULL (no filter).

- travel_time_max:

  Numeric or character. Maximum travel time. If numeric, interpreted as
  hours. If character, use format "XX hr XX min". Default is NULL (no
  filter).

- max_stops:

  Integer. Maximum number of stops. Default is NULL (no filter).

- max_layover:

  Character. Maximum layover time in format "XX hr XX min". Default is
  NULL (no filter).

- max_emissions:

  Numeric. Maximum CO2 emissions in kg. Default is NULL (no filter).

- excluded_airports:

  Character vector. Airport codes to exclude from results. Default is
  NULL (no additional filtering beyond global excluded_airports list).

## Value

A data frame with columns: departure_date, departure_time (or date if
datetime not available), origin, price (average/median/min), n_routes,
num_stops, layover, travel_time, co2_emission_kg, airlines,
arrival_date, arrival_time. All column names are lowercase. Returns the
top N dates with best (lowest) prices, sorted by departure time for
display. Additional columns are aggregated using mean/median for numeric
values and most common value for categorical. Note: arrival_date and
arrival_time represent the most common values when multiple flights are
aggregated and may not correspond exactly to the specific departure
times shown.

## Examples

``` r
# Find best dates
fa_find_best_dates(sample_flight_results, n = 3, by = "min")
#>   departure_date departure_time arrival_date arrival_time origin price
#> 1     2025-12-18          08:00   2025-12-18        19:00    DEL   564
#> 2     2025-12-22          08:00   2025-12-22        08:30    DEL   541
#> 3     2026-01-05          07:00   2026-01-05        11:45    DEL   567
#>   num_stops         layover  travel_time co2_emission_kg airlines n_routes
#> 1         1 5 hr 15 min FRA 16 hr 46 min             923   United        1
#> 2         2 4 hr 30 min DXB 15 hr 55 min             882   United        2
#> 3         1 3 hr 45 min IST 16 hr 44 min             895   United        1

# With filters
fa_find_best_dates(
  sample_flight_results,
  n = 2,
  max_stops = 0
)
#>   departure_date departure_time arrival_date arrival_time origin price
#> 1     2026-01-04          14:00   2026-01-04        10:30    BOM   615
#> 2     2026-01-05          12:45   2026-01-05        14:45    BOM   618
#>   num_stops  travel_time co2_emission_kg  airlines n_routes
#> 1         0 15 hr 35 min             885 Lufthansa        1
#> 2         0 16 hr 10 min             871    United        1
```
