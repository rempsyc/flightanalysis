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
  best_dates,
  title = "Best Travel Dates by Price",
  subtitle = NULL,
  ...
)
```

## Arguments

- best_dates:

  A data frame from
  [`fa_find_best_dates`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md)
  or flight results that can be passed to
  [`fa_find_best_dates`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md).

- title:

  Character. Plot title. Default is "Best Travel Dates by Price".

- subtitle:

  Character. Plot subtitle. Default is NULL (auto-generated).

- ...:

  Additional arguments passed to
  [`fa_find_best_dates`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md)
  if best_dates is not already a result from that function.

## Value

A ggplot2 plot object that can be further customized or saved.

## Examples

``` r
if (FALSE) { # \dontrun{
# Plot best dates
fa_plot_best_dates(sample_flights, n = 5)

# With filters
fa_plot_best_dates(sample_flights, n = 5, max_stops = 0)
} # }
```
