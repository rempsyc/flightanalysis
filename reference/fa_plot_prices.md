# Plot Price Summary

Creates a modern line plot showing price trends across dates for
different origins/cities. This visualizes the output from
[`fa_summarize_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md),
making it easy to compare prices across dates and identify the best
travel dates visually. Point sizes vary inversely with price (cheaper
flights = bigger points).

Uses ggplot2 for a polished, publication-ready aesthetic with
colorblind-friendly colors and clear typography.

## Usage

``` r
fa_plot_prices(
  price_summary,
  title = "Flight Prices by Date",
  subtitle = NULL,
  annotate_col = NULL,
  use_ggrepel = TRUE,
  show_max_annotation = TRUE,
  show_min_annotation = FALSE,
  ...
)
```

## Arguments

- price_summary:

  A data frame from
  [`fa_summarize_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md)
  or flight results that can be passed to
  [`fa_summarize_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md).

- title:

  Character. Plot title. Default is "Flight Prices by Date".

- subtitle:

  Character. Plot subtitle. Default is NULL (auto-generated).

- annotate_col:

  Character. Name of column from raw flight data to use for point
  annotations (e.g., "travel_time", "num_stops"). Only works when
  passing raw flight data, not summary tables. Default is NULL (no
  annotations).

- use_ggrepel:

  Logical. If TRUE, uses ggrepel for non-overlapping label positioning
  (requires ggrepel package). If FALSE, labels are centered on points
  and may overlap when there are many data points. Default is TRUE.

- show_max_annotation:

  Logical. If TRUE, adds a data-journalism-style annotation for the
  maximum price with a horizontal bar and formatted price label. The
  annotation is subtle and clean (no arrows or boxes). Default is TRUE.

- show_min_annotation:

  Logical. If TRUE, adds a data-journalism-style annotation for the
  minimum price with a horizontal bar and formatted price label. The
  annotation is subtle and clean (no arrows or boxes). Default is FALSE.

- ...:

  Additional arguments passed to
  [`fa_summarize_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md)
  if price_summary is not already a summary table.

## Value

A ggplot2 plot object that can be further customized or saved.

## Examples

``` r
if (FALSE) { # \dontrun{
# Plot price summary
fa_plot_prices(sample_flights)

# With custom title and annotations (using ggrepel)
fa_plot_prices(sample_flights,
               title = "Flight Prices: BOM/DEL to JFK",
               annotate_col = "travel_time")

# With annotations centered on points (no ggrepel)
fa_plot_prices(sample_flights,
               annotate_col = "travel_time",
               use_ggrepel = FALSE)

# Without maximum price annotation
fa_plot_prices(sample_flights,
               show_max_annotation = FALSE)

# With both max and min price annotations
fa_plot_prices(sample_flights,
               show_max_annotation = TRUE,
               show_min_annotation = TRUE)
} # }
```
