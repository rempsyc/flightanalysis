# Plot Price Summary

Creates a modern line plot showing price trends across dates for
different origins or destinations. The function automatically detects
whether to group by origin or destination based on the data structure:

- When there are multiple origins and a single destination, groups by
  origin

- When there is a single origin and multiple destinations, groups by
  destination

- When there are multiple origins AND multiple destinations, you must
  specify the `plot_by` parameter to choose which dimension to use for
  grouping

The legend title automatically updates to "Origin" or "Destination"
accordingly.

Requires flight_results objects from
[`fa_fetch_flights`](https://rempsyc.github.io/flightanalysis/reference/fa_fetch_flights.md).
This function no longer accepts pre-summarized data or data frames.

Uses ggplot2 for a polished, publication-ready aesthetic with
colorblind-friendly colors and clear typography.

## Usage

``` r
fa_plot_prices(
  flight_results,
  plot_by = NULL,
  title = NULL,
  subtitle = NULL,
  size_by = "travel_time",
  annotate_col = NULL,
  use_ggrepel = TRUE,
  show_max_annotation = TRUE,
  show_min_annotation = FALSE,
  x_axis_angle = 0,
  drop_empty_dates = TRUE,
  highlight_extremes = TRUE,
  ...
)
```

## Arguments

- flight_results:

  A flight_results object from \[fa_fetch_flights()\].

- plot_by:

  Character. Specifies how to group the data: "origin" or "destination".
  When NULL (default), automatically detected based on data structure.
  Required when there are multiple origins AND multiple destinations.

- title:

  Character. Plot title. Default is NULL (auto-generated with flight
  context).

- subtitle:

  Character. Plot subtitle. Default is NULL (auto-generated with lowest
  price info).

- size_by:

  Character. Name of column from raw flight data to use for point
  sizing. Can be "price", a column name like "travel_time", or NULL for
  uniform sizing (default). When using a column name, only works when
  passing raw flight data, not summary tables. Default is NULL.

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

- x_axis_angle:

  Numeric. Angle in degrees to rotate x-axis labels for better
  readability in wide figures with many dates. Common values are 45
  (diagonal) or 90 (vertical). Default is 0 (horizontal labels).

- drop_empty_dates:

  Logical. If TRUE, removes dates that have no flight data (all NA
  prices) from the plot. This is useful when querying multiple airports
  where some may not have data for certain dates. Default is TRUE.

- highlight_extremes:

  Logical. If TRUE, highlights the lowest and highest price points by
  filling them with distinct colorblind-friendly colors (bluish green
  for lowest, vermillion for highest). Default is TRUE.

- ...:

  Additional arguments passed to
  [`fa_summarize_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md),
  including `excluded_airports` to filter out specific airport codes.

## Value

A ggplot2 plot object that can be further customized or saved.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic plot with auto-generated title and subtitle
fa_plot_prices(sample_flight_results)

# With point size based on travel time and annotations
fa_plot_prices(sample_flight_results,
               size_by = "travel_time",
               annotate_col = "num_stops")

# Size by number of stops
fa_plot_prices(sample_flight_results,
               size_by = "num_stops")

# With annotations centered on points (no ggrepel)
fa_plot_prices(sample_flight_results,
               size_by = "travel_time",
               annotate_col = "travel_time",
               use_ggrepel = FALSE)

# Custom title and both price annotations
fa_plot_prices(sample_flight_results,
               title = "Custom Title",
               show_max_annotation = TRUE,
               show_min_annotation = TRUE)

# Tilt x-axis labels diagonally for wide figures
fa_plot_prices(sample_flight_results, x_axis_angle = 45)

# Default behavior: filter out dates with no flight data
# Set drop_empty_dates = FALSE to keep all dates including empty ones
fa_plot_prices(sample_flight_results, drop_empty_dates = FALSE)

# Disable highlighting of lowest/highest price points
fa_plot_prices(sample_flight_results, highlight_extremes = FALSE)
} # }
```
