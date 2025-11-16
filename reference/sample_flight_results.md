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
data(sample_flight_results)
print(sample_flight_results)
#> Flight Results
#> ==============
#> 
#> Total flights: 95
#> Origins: BOM, DEL, VNS, PAT, GAY
#> Destinations: JFK
#> 
#> Individual queries: BOM, DEL, VNS, PAT, GAY

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
