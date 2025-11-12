# Create Flexible Date Summary Table

Creates a wide summary table showing prices by city/airport and date,
with an average price column. When multiple flights exist for the same
date, uses the minimum (cheapest) price. This is useful for visualizing
price patterns across multiple dates and comparing different origin
airports.

## Usage

``` r
fa_flex_table(
  results,
  include_comment = TRUE,
  currency_symbol = "$",
  round_prices = TRUE
)
```

## Arguments

- results:

  Either: - A data frame with columns: City, Airport, Date, Price, and
  optionally Comment - A list of Scrape objects (from
  fa_create_date_range_scrape with multiple origins) - A single Scrape
  object (from fa_create_date_range_scrape with single origin)

- include_comment:

  Logical. If TRUE and Comment column exists, includes it in the output.
  Default is TRUE.

- currency_symbol:

  Character. Currency symbol to use for formatting. Default is "\$".

- round_prices:

  Logical. If TRUE, rounds prices to nearest integer. Default is TRUE.

## Value

A wide data frame with columns: City, Airport, Comment (optional), one
column per date with prices, and an Average_Price column.

## Examples

``` r
if (FALSE) { # \dontrun{
# Option 1: Pass list of Scrape objects directly
scrapes <- fa_create_date_range_scrape(c("BOM", "DEL"), "JFK", "2025-12-18", "2026-01-05")
for (code in names(scrapes)) {
  scrapes[[code]] <- ScrapeObjects(scrapes[[code]])
}
summary_table <- fa_flex_table(scrapes)

# Option 2: Pass processed data frame
summary_table <- fa_flex_table(my_data_frame)
} # }
```
