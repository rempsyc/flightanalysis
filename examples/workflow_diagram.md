# Flexible Date Search Workflow

This diagram illustrates the typical workflow when using the flexible date search features.

## Workflow Steps

```
1. Define Routes
   └─> Create data frame with City, Airport, Dest columns
       (optionally include Comment column)

2. Define Date Range
   └─> Use seq(from, to, by="day") or vector of dates

3. Scrape Data
   └─> fa_scrape_best_oneway(routes, dates, ...)
       ├─> Creates all route × date combinations
       ├─> Scrapes each combination
       ├─> Filters placeholder rows
       ├─> Applies rate limiting
       └─> Returns data frame with cheapest prices

4. Analyze Results
   ├─> fa_flex_table(results, ...)
   │   ├─> Creates wide table (City × Date)
   │   ├─> Calculates average prices
   │   └─> Formats with currency symbols
   │
   └─> fa_best_dates(results, n, by)
       ├─> Aggregates by date (mean/median/min)
       ├─> Identifies N cheapest dates
       └─> Returns sorted list
```

## Example Flow

```r
# Step 1: Define routes
routes <- data.frame(
  City = c("Mumbai", "Delhi", "Varanasi"),
  Airport = c("BOM", "DEL", "VNS"),
  Dest = c("JFK", "JFK", "JFK")
)

# Step 2: Define dates
dates <- seq(as.Date("2025-12-18"), as.Date("2025-12-25"), by = "day")
# Creates: 2025-12-18, 2025-12-19, ..., 2025-12-25 (8 dates)

# Step 3: Scrape (3 routes × 8 dates = 24 total queries)
results <- fa_scrape_best_oneway(routes, dates, pause = 2)
# Returns data frame with 24 rows (one per route-date combination)

# Step 4a: Create summary table
table <- fa_flex_table(results)
# Returns 3 rows (one per city) × 8 date columns + Average_Price

# Step 4b: Find best dates
best <- fa_best_dates(results, n = 3, by = "mean")
# Returns 3 rows showing the 3 cheapest dates on average
```

## Data Structure Flow

```
Input Routes:
┌─────────┬─────────┬──────┐
│ City    │ Airport │ Dest │
├─────────┼─────────┼──────┤
│ Mumbai  │ BOM     │ JFK  │
│ Delhi   │ DEL     │ JFK  │
│ Varanasi│ VNS     │ JFK  │
└─────────┴─────────┴──────┘

                ↓

Scraped Results:
┌─────────┬─────────┬──────┬────────────┬───────┐
│ City    │ Airport │ Dest │ Date       │ Price │
├─────────┼─────────┼──────┼────────────┼───────┤
│ Mumbai  │ BOM     │ JFK  │ 2025-12-18 │ 334   │
│ Mumbai  │ BOM     │ JFK  │ 2025-12-19 │ 388   │
│ Delhi   │ DEL     │ JFK  │ 2025-12-18 │ 315   │
│ Delhi   │ DEL     │ JFK  │ 2025-12-19 │ 353   │
│ ...     │ ...     │ ...  │ ...        │ ...   │
└─────────┴─────────┴──────┴────────────┴───────┘

                ↓ fa_flex_table()

Wide Summary Table:
┌─────────┬─────────┬────────────┬────────────┬──────────────┐
│ City    │ Airport │ 2025-12-18 │ 2025-12-19 │ Average_Price│
├─────────┼─────────┼────────────┼────────────┼──────────────┤
│ Mumbai  │ BOM     │ $334       │ $388       │ $361.00      │
│ Delhi   │ DEL     │ $315       │ $353       │ $334.00      │
│ Varanasi│ VNS     │ $350       │ $400       │ $375.00      │
└─────────┴─────────┴────────────┴────────────┴──────────────┘

                ↓ fa_best_dates()

Best Dates:
┌────────────┬───────┬──────────┐
│ Date       │ Price │ N_Routes │
├────────────┼───────┼──────────┤
│ 2025-12-18 │ 333.0 │ 3        │
│ 2025-12-19 │ 380.3 │ 3        │
└────────────┴───────┴──────────┘
```

## Tips

- Use `keep_offers = TRUE` in `fa_scrape_best_oneway()` to store all flight options for later analysis
- Adjust `pause` parameter based on your needs (default 2 seconds is recommended)
- Use `by = "min"` in `fa_best_dates()` to find dates with absolute lowest prices
- Use `by = "mean"` to find dates that are consistently cheap across routes
- Currency formatting in `fa_flex_table()` uses the `scales` package if available
