# Sample Flight Results Dataset

A comprehensive sample dataset containing flight data from 5 Indian
origins (BOM, DEL, VNS, PAT, GAY) to JFK spanning from December 18, 2025
to January 5, 2026. This dataset demonstrates realistic pricing patterns
including a Christmas/New Year price spike, making it ideal for testing
and demonstrating flight analysis functions.

## Usage

``` r
sample_flight_results
```

## Format

A flight_results object (S3 class) with the following structure:

- data:

  A data frame with 95 rows (5 origins × 19 days) containing:

  - `departure_date`: Character, departure date in "YYYY-MM-DD" format

  - `departure_time`: Character, departure time in "HH:MM" format

  - `arrival_date`: Character, arrival date in "YYYY-MM-DD" format

  - `arrival_time`: Character, arrival time in "HH:MM" format

  - `origin`: Character, origin airport code (BOM, DEL, VNS, PAT, GAY)

  - `destination`: Character, destination airport code (JFK)

  - `airlines`: Character, airline name

  - `travel_time`: Character, total travel time in "XX hr YY min" format

  - `price`: Numeric, ticket price in USD

  - `num_stops`: Integer, number of stops (0-2)

  - `layover`: Character, layover information (if applicable)

  - `access_date`: Character, timestamp when data was accessed

  - `co2_emission_kg`: Numeric, estimated CO2 emissions in kg

  - `emission_diff_pct`: Numeric, emission difference percentage

- BOM, DEL, VNS, PAT, GAY:

  Query objects for each origin containing the data subset and query
  parameters

## Details

The dataset features:

- Realistic travel times varying by origin (15.5-18.5 hours)

- Base prices varying by origin (\$580-\$700)

- Christmas/New Year price spike (Dec 23 - Jan 3) with 1.3x-4.5x
  multiplier

- Peak prices around January 1-2

- Weekend price adjustments (10% increase)

- Random variation to simulate real-world data

This dataset is particularly useful for:

- Demonstrating
  [`fa_plot_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_plot_prices.md)
  with seasonal patterns

- Testing
  [`fa_summarize_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md)
  with multiple origins

- Showing
  [`fa_find_best_dates`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md)
  functionality

- Creating visually appealing examples with the size_by parameter

## See also

[`sample_flights`](https://rempsyc.github.io/flightanalysis/reference/sample_flights.md)
for a simpler data frame example,
[`fa_plot_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_plot_prices.md)
for plotting functions,
[`fa_summarize_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md)
for price summary tables

## Examples

``` r
# Load and examine the dataset
head(sample_flight_results$data)
#>   departure_date departure_time arrival_date arrival_time origin destination
#> 1     2025-12-18          08:15   2025-12-18        16:00    BOM         JFK
#> 2     2025-12-19          14:00   2025-12-19        08:45    BOM         JFK
#> 3     2025-12-20          17:30   2025-12-20        15:00    BOM         JFK
#> 4     2025-12-21          11:00   2025-12-21        07:00    BOM         JFK
#> 5     2025-12-22          20:00   2025-12-22        20:15    BOM         JFK
#> 6     2025-12-23          21:00   2025-12-23        22:15    BOM         JFK
#>           airlines  travel_time price num_stops         layover
#> 1         Emirates 15 hr 25 min   624         1 3 hr 15 min FRA
#> 2           United  15 hr 3 min   587         1 4 hr 15 min FRA
#> 3        Air India  15 hr 2 min   658         0            <NA>
#> 4 Turkish Airlines 16 hr 17 min   609         1 5 hr 45 min DXB
#> 5         Emirates 16 hr 13 min   625         1 4 hr 45 min IST
#> 6         Emirates 16 hr 10 min   679         2  2 hr 0 min LHR
#>           access_date co2_emission_kg emission_diff_pct
#> 1 2025-11-16 16:19:56             838              -0.1
#> 2 2025-11-16 16:19:56             878              10.9
#> 3 2025-11-16 16:19:56             837               0.3
#> 4 2025-11-16 16:19:56             907              11.2
#> 5 2025-11-16 16:19:56             873               3.4
#> 6 2025-11-16 16:19:56             884               7.0

if (FALSE) { # \dontrun{
# Plot with automatic Christmas spike visualization
fa_plot_prices(sample_flight_results)

# Size points by travel time
fa_plot_prices(sample_flight_results, size_by = "travel_time")

# Create price summary table
fa_summarize_prices(sample_flight_results)

# Find best dates
fa_find_best_dates(sample_flight_results, n = 5)
} # }
```
