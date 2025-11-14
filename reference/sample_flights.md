# Sample Flight Data

Sample flight data for testing analysis functions like
\`fa_find_best_dates()\` and \`fa_summarize_prices()\` without internet
access.

## Usage

``` r
sample_flights
```

## Format

A data frame with 6 rows and 12 variables:

- departure_datetime:

  POSIXct departure date and time

- arrival_datetime:

  POSIXct arrival date and time

- origin:

  Character, 3-letter origin airport code

- destination:

  Character, 3-letter destination airport code

- airlines:

  Character, airline name(s)

- travel_time:

  Character, total travel time

- price:

  Numeric, ticket price in USD

- num_stops:

  Integer, number of stops

- layover:

  Character, layover details (NA if nonstop)

- access_date:

  POSIXct, when data was accessed

- co2_emission_kg:

  Numeric, CO2 emissions in kg

- emission_diff_pct:

  Numeric, emission difference percentage

## Examples

``` r
data(sample_flights)
head(sample_flights)
#>    departure_datetime    arrival_datetime origin destination
#> 1 2025-12-20 14:00:00 2025-12-21 03:00:00    JFK         IST
#> 2 2025-12-20 19:30:00 2025-12-21 08:45:00    JFK         IST
#> 3 2025-12-21 03:00:00 2025-12-21 16:30:00    JFK         IST
#> 4 2025-12-21 15:15:00 2025-12-22 04:30:00    JFK         IST
#> 5 2025-12-27 13:30:00 2025-12-28 02:15:00    IST         JFK
#> 6 2025-12-27 20:45:00 2025-12-28 10:00:00    IST         JFK
#>              airlines  travel_time price num_stops         layover
#> 1    Turkish Airlines  13 hr 0 min   650         0            <NA>
#> 2           Lufthansa 13 hr 15 min   720         1 2 hr 30 min FRA
#> 3 LOT Polish Airlines 13 hr 30 min   580         1 3 hr 15 min WAW
#> 4          Air France 13 hr 15 min   695         1 2 hr 45 min CDG
#> 5    Turkish Airlines 12 hr 45 min   620         0            <NA>
#> 6     United Airlines 13 hr 15 min   685         1 3 hr 10 min EWR
#>           access_date co2_emission_kg emission_diff_pct
#> 1 2025-11-13 23:35:40             550                 5
#> 2 2025-11-13 23:35:40             580                10
#> 3 2025-11-13 23:35:40             600                15
#> 4 2025-11-13 23:35:40             570                 8
#> 5 2025-11-13 23:35:40             540                 3
#> 6 2025-11-13 23:35:40             575                 9
# Use with analysis functions by attaching to a query object
if (FALSE) { # \dontrun{
data(sample_query)
sample_query$data <- sample_flights
fa_find_best_dates(sample_query, n = 3)
fa_summarize_prices(sample_query)
} # }
```
