# Plot Best Travel Dates

Creates a modern visualization showing the best (cheapest) travel dates
identified by
[`fa_find_best_dates`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md).
Uses a lollipop chart style that clearly shows the price range and
highlights the best options by origin and date.

Uses ggplot2 for a polished, publication-ready aesthetic with
colorblind-friendly colors and clear typography.

## Usage

``` r
fa_plot_best_dates(
  flight_results,
  title = "Best Travel Dates by Price",
  subtitle = NULL,
  x_axis_angle = 0,
  ...
)
```

## Arguments

- flight_results:

  A flight_results object from \[fa_fetch_flights()\].

- title:

  Character. Plot title. Default is "Best Travel Dates by Price".

- subtitle:

  Character. Plot subtitle. Default is NULL (auto-generated).

- x_axis_angle:

  Numeric. Angle in degrees to rotate x-axis labels for better
  readability in wide figures with many dates. Common values are 45
  (diagonal) or 90 (vertical). Default is 0 (horizontal labels).

- ...:

  Additional arguments passed to
  [`fa_find_best_dates`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md)
  if best_dates is a flight_results object, including
  `excluded_airports` to filter out specific airport codes.

## Value

A ggplot2 plot object that can be further customized or saved.

## Examples

``` r
if (FALSE) { # \dontrun{
# Plot best dates
fa_plot_best_dates(sample_flight_results, n = 5)

# With filters
fa_plot_best_dates(sample_flight_results, n = 5, max_stops = 0)

# Tilt x-axis labels diagonally for wide figures
fa_plot_best_dates(sample_flight_results, n = 10, x_axis_angle = 45)
} # }
```
