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
  max_emissions = NULL
)
```

## Arguments

- flight_results:

  Either: - A data frame with columns: Date and Price (and optionally
  other filter columns) - A flight_results object (from fa_fetch_flights
  with multiple origins) - A list of flight queries (from
  fa_define_query_range with multiple origins) - A single flight query
  (from fa_define_query_range with single origin)

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

## Value

A data frame with columns: departure_date, departure_time (or date if
datetime not available), origin, price (average/median/min), n_routes,
num_stops, layover, travel_time, co2_emission_kg, and airlines. All
column names are lowercase. Returns the top N dates with best (lowest)
prices, sorted by departure time for display. Additional columns are
aggregated using mean/median for numeric values and most common value
for categorical.

## Examples

``` r
# Using sample data
data(sample_query)
data(sample_flights)

# Attach flight data to query object
sample_query$data <- sample_flights

# Find best dates
fa_find_best_dates(sample_query, n = 3, by = "min")
#>   departure_date departure_time origin price num_stops         layover
#> 1     2025-12-20       14:00:00    JFK   650         0            <NA>
#> 2     2025-12-21       03:00:00    JFK   580         1 3 hr 15 min WAW
#> 3     2025-12-27       13:30:00    IST   620         0            <NA>
#>    travel_time co2_emission_kg            airlines n_routes
#> 1  13 hr 0 min             550    Turkish Airlines        1
#> 2 13 hr 30 min             600 LOT Polish Airlines        1
#> 3 12 hr 45 min             540    Turkish Airlines        1

# With filters
fa_find_best_dates(
  sample_query,
  n = 2,
  max_stops = 0
)
#>   departure_date departure_time origin price num_stops  travel_time
#> 1     2025-12-20       14:00:00    JFK   650         0  13 hr 0 min
#> 2     2025-12-27       13:30:00    IST   620         0 12 hr 45 min
#>   co2_emission_kg         airlines n_routes
#> 1             550 Turkish Airlines        1
#> 2             540 Turkish Airlines        1
```
