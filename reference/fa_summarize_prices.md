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
  flight_results,
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

- flight_results:

  A flight_results object from fa_fetch_flights(). This function no
  longer accepts data frames or query objects directly.

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
# Create summary table
fa_summarize_prices(sample_flight_results)
#>       City Origin 2025-12-18 2025-12-19 2025-12-20 2025-12-21 2025-12-22
#> 1   Mumbai    BOM       $624       $587       $658       $609       $625
#> 2    Delhi    DEL       $564       $591       $647       $671       $541
#> 3     Gaya    GAY       $716       $668       $816       $778       $704
#> 4    Patna    PAT       $679       $634       $697       $715       $697
#> 5 Varanasi    VNS       $635       $609       $679       $722       $653
#> 6     Best    Day                                                      X
#>   2025-12-23 2025-12-24 2025-12-25 2025-12-26 2025-12-27 2025-12-28 2025-12-29
#> 1       $679       $778       $961     $1,031     $1,353     $1,539     $1,715
#> 2       $643       $853       $692     $  955     $1,364     $1,464     $1,359
#> 3       $857       $926       $990     $1,218     $1,711     $1,751     $1,846
#> 4       $851       $900       $979     $1,114     $1,467     $1,641     $1,658
#> 5       $811       $901       $910     $  939     $1,393     $1,880     $1,772
#> 6                                                                             
#>   2025-12-30 2025-12-31 2026-01-01 2026-01-02 2026-01-03 2026-01-04 2026-01-05
#> 1     $1,872     $2,011     $1,846     $1,648     $1,640       $615       $618
#> 2     $1,878     $2,195     $1,672     $1,375     $1,606       $694       $567
#> 3     $2,127     $2,438     $2,083     $1,994     $2,098       $767       $674
#> 4     $2,178     $2,480     $2,210     $1,938     $1,983       $784       $668
#> 5     $1,979     $2,006     $2,079     $1,960     $1,947       $754       $664
#> 6                                                                             
#>   Average_Price
#> 1        $1,127
#> 2        $1,070
#> 3        $1,324
#> 4        $1,278
#> 5        $1,226
#> 6              

# With filters
fa_summarize_prices(
  sample_flight_results,
  max_stops = 0
)
#>       City Origin 2025-12-18 2025-12-19 2025-12-20 2025-12-21 2025-12-22
#> 1     Gaya    GAY       $716       $668       <NA>       <NA>       $704
#> 2    Patna    PAT       $679       $634       $697       $715       $697
#> 3   Mumbai    BOM       <NA>       <NA>       $658       <NA>       <NA>
#> 4 Varanasi    VNS       <NA>       <NA>       $679       $722       $653
#> 5    Delhi    DEL       <NA>       <NA>       <NA>       <NA>       <NA>
#> 6     Best    Day                                                       
#>   2025-12-23 2025-12-24 2025-12-25 2025-12-26 2025-12-27 2025-12-28 2025-12-29
#> 1       $857       $926       <NA>     $1,218     $1,711     $1,751     $1,846
#> 2       <NA>       $900       <NA>     $1,114     $1,467       <NA>     $1,658
#> 3       <NA>       $778       $961       <NA>     $1,353       <NA>       <NA>
#> 4       <NA>       <NA>       <NA>       <NA>     $1,393       <NA>       <NA>
#> 5       <NA>       $853       $692     $  955       <NA>       <NA>       <NA>
#> 6                                                                             
#>   2025-12-30 2025-12-31 2026-01-01 2026-01-03 2026-01-04 2026-01-05
#> 1     $2,127     $2,438       <NA>     $2,098       <NA>       $674
#> 2     $2,178     $2,480     $2,210     $1,983       <NA>       $668
#> 3       <NA>       <NA>     $1,846       <NA>       $615       $618
#> 4     $1,979       <NA>       <NA>     $1,947       $754       <NA>
#> 5     $1,878       <NA>     $1,672       <NA>       $694       <NA>
#> 6                                                      X           
#>   Average_Price
#> 1        $1,364
#> 2        $1,291
#> 3        $  976
#> 4        $1,161
#> 5        $1,124
#> 6              
```
