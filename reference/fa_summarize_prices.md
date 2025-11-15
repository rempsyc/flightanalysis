# Create Price Summary Table

Creates a wide summary table showing prices by city/airport and date,
with an average price column. When multiple flights exist for the same
date, uses the minimum (cheapest) price. This is useful for visualizing
price patterns across multiple dates and comparing different origin
airports. Supports filtering by various criteria such as departure time,
airlines, travel time, stops, and emissions.

## Usage

``` r
fa_summarize_prices(
  results,
  include_comment = TRUE,
  currency_symbol = "$",
  round_prices = TRUE,
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

- results:

  Either: - A data frame with columns: City, Airport, Date, Price, and
  optionally Comment (Airport will be renamed to Origin) - A list of
  flight queries (from fa_create_date_range with multiple origins) - A
  single flight query (from fa_create_date_range with single origin)

- include_comment:

  Logical. If TRUE and Comment column exists, includes it in the output.
  Default is TRUE.

- currency_symbol:

  Character. Currency symbol to use for formatting. Default is "\$".

- round_prices:

  Logical. If TRUE, rounds prices to nearest integer. Default is TRUE.

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

A wide data frame with columns: City, Origin, Comment (optional), one
column per date with prices, and an Average_Price column.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage
queries <- fa_create_date_range(c("BOM", "DEL"), "JFK", "2025-12-28", "2026-01-02")
flights <- fa_fetch_flights(queries)
fa_summarize_prices(flights)

# With filters
summary_table <- fa_summarize_prices(
  queries,
  time_min = "08:00",
  time_max = "20:00",
  max_stops = 1
)
} # }
```
