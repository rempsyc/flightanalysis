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
data(sample_flights)
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
#> 1 2025-11-15 18:06:44             550                 5
#> 2 2025-11-15 18:06:44             580                10
#> 3 2025-11-15 18:06:44             600                15
#> 4 2025-11-15 18:06:44             570                 8
#> 5 2025-11-15 18:06:44             540                 3
#> 6 2025-11-15 18:06:44             575                 9
# Use with analysis functions directly
fa_find_best_dates(sample_flights, n = 3)
#>   departure_date departure_time arrival_date arrival_time origin price
#> 1     2025-12-20          09:00   2025-12-20        22:00    JFK   650
#> 2     2025-12-20          22:00   2025-12-21        11:30    JFK   580
#> 3     2025-12-27          08:30   2025-12-27        21:15    IST   620
#>   num_stops         layover  travel_time co2_emission_kg            airlines
#> 1         0            <NA>  13 hr 0 min             550    Turkish Airlines
#> 2         1 3 hr 15 min WAW 13 hr 30 min             600 LOT Polish Airlines
#> 3         0            <NA> 12 hr 45 min             540    Turkish Airlines
#>   n_routes
#> 1        1
#> 2        1
#> 3        1
fa_summarize_prices(sample_flights)
#>   City Origin 2025-12-20 2025-12-21 2025-12-27 Average_Price
#> 1  JFK    JFK       $580       $695       <NA>          $638
#> 2  IST    IST       <NA>       <NA>       $620          $620
#> 3 Best    Day          X                                    
```
