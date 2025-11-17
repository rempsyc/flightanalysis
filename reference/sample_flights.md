# Sample Flight Data

Sample flight data for testing analysis functions like
\`fa_find_best_dates()\` and \`fa_summarize_prices()\` without internet
access.

## Usage

``` r
sample_flights
```

## Format

A data frame with 6 rows and 14 variables:

- departure_date:

  Character, departure date (YYYY-MM-DD)

- departure_time:

  Character, departure time (HH:MM)

- arrival_date:

  Character, arrival date (YYYY-MM-DD)

- arrival_time:

  Character, arrival time (HH:MM)

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

  Character, when data was accessed

- co2_emission_kg:

  Numeric, CO2 emissions in kg

- emission_diff_pct:

  Numeric, emission difference percentage

## Examples

``` r
head(sample_flights)
#>   departure_date departure_time arrival_date arrival_time origin destination
#> 1     2025-12-20          09:00   2025-12-20        22:00    JFK         IST
#> 2     2025-12-20          14:30   2025-12-21        03:45    JFK         IST
#> 3     2025-12-20          22:00   2025-12-21        11:30    JFK         IST
#> 4     2025-12-21          10:15   2025-12-21        23:30    JFK         IST
#> 5     2025-12-27          08:30   2025-12-27        21:15    IST         JFK
#> 6     2025-12-27          15:45   2025-12-28        05:00    IST         JFK
#>              airlines  travel_time price num_stops         layover
#> 1    Turkish Airlines  13 hr 0 min   650         0            <NA>
#> 2           Lufthansa 13 hr 15 min   720         1 2 hr 30 min FRA
#> 3 LOT Polish Airlines 13 hr 30 min   580         1 3 hr 15 min WAW
#> 4          Air France 13 hr 15 min   695         1 2 hr 45 min CDG
#> 5    Turkish Airlines 12 hr 45 min   620         0            <NA>
#> 6     United Airlines 13 hr 15 min   685         1 3 hr 10 min EWR
#>           access_date co2_emission_kg emission_diff_pct
#> 1 2025-11-16 16:19:56             550                 5
#> 2 2025-11-16 16:19:56             580                10
#> 3 2025-11-16 16:19:56             600                15
#> 4 2025-11-16 16:19:56             570                 8
#> 5 2025-11-16 16:19:56             540                 3
#> 6 2025-11-16 16:19:56             575                 9

# Note: sample_flights is a data frame for demonstration purposes only.
# Analysis functions now require flight_results objects from fa_fetch_flights().
# Use sample_flight_results instead:
if (FALSE) { # \dontrun{
fa_find_best_dates(sample_flight_results, n = 3)
fa_summarize_prices(sample_flight_results)
} # }
```
