# Example: Flexible Date Search and Summary Table
# 
# This example demonstrates how to use the new flexible date search features
# to find the cheapest flights across multiple dates and airports.

library(flightanalysis)

# If tibble is available, use it for better display
if (requireNamespace("tibble", quietly = TRUE)) {
  library(tibble)
  
  # Define routes to search
  routes <- tribble(
    ~City,      ~Airport, ~Dest, ~Comment,
    "Mumbai",   "BOM",    "JFK", "Original flight",
    "Delhi",    "DEL",    "JFK", "",
    "Varanasi", "VNS",    "JFK", "",
    "Patna",    "PAT",    "JFK", "",
    "Gaya",     "GAY",    "JFK", ""
  )
} else {
  # Use base R data frame
  routes <- data.frame(
    City = c("Mumbai", "Delhi", "Varanasi", "Patna", "Gaya"),
    Airport = c("BOM", "DEL", "VNS", "PAT", "GAY"),
    Dest = rep("JFK", 5),
    Comment = c("Original flight", "", "", "", ""),
    stringsAsFactors = FALSE
  )
}

# Define date range
dates <- seq(as.Date("2025-12-18"), as.Date("2026-01-05"), by = "day")

# Example 1: Scrape flights across multiple routes and dates
# Note: This will take time to run as it scrapes live data
# Uncomment the following lines to run the actual scraping

# Step 1: Create Scrape objects (one per origin)
# scrapes <- create_date_range(
#   origin = routes$Airport,
#   dest = "JFK",
#   date_min = min(dates),
#   date_max = max(dates)
# )
# 
# # Step 2: Scrape each origin
# for (code in names(scrapes)) {
#   scrapes[[code]] <- fetch_flights(scrapes[[code]], verbose = TRUE)
# }
# 
# # Step 3: Analyze directly - fa_flex_table and fa_best_dates accept lists of Scrape objects!
# summary_table <- fa_flex_table(scrapes)
# best_dates <- fa_best_dates(scrapes, n = 10, by = "mean")

# For demonstration purposes, create mock results
set.seed(123)
results <- data.frame(
  City = rep(routes$City, each = length(dates)),
  Airport = rep(routes$Airport, each = length(dates)),
  Dest = rep("JFK", nrow(routes) * length(dates)),
  Date = rep(as.character(dates), nrow(routes)),
  Price = round(runif(nrow(routes) * length(dates), 300, 800)),
  Comment = rep(routes$Comment, each = length(dates)),
  stringsAsFactors = FALSE
)

# Example 2: Create wide summary table
summary_table <- fa_flex_table(
  results,
  include_comment = TRUE,
  currency_symbol = "$",
  round_prices = TRUE
)

print("=== FLIGHT PRICE SUMMARY TABLE ===")
print(summary_table)

# Example 3: Find best dates to fly
best_dates <- fa_best_dates(results, n = 10, by = "mean")

print("\n=== TOP 10 CHEAPEST DATES (Average across all routes) ===")
print(best_dates)

# Example 4: Find best dates by minimum price
best_dates_min <- fa_best_dates(results, n = 5, by = "min")

print("\n=== TOP 5 DATES WITH LOWEST PRICE (Best deal found) ===")
print(best_dates_min)

# Example 5: Alternative workflow - separate scraping per origin
# (commented out - uncomment to run actual scraping)
# query_single <- create_date_range(
#   origin = "BOM",
#   dest = "JFK",
#   date_min = "2025-12-18",
#   date_max = "2025-12-20"
# )
# 
# # Scrape the data
# query_single <- fetch_flights(query_single, verbose = TRUE)
# 
# # Analyze single origin
# best_dates_single <- fa_best_dates(query_single, n = 5, by = "min")
# print(best_dates_single)

cat("\n=== Usage Tips ===\n")
cat("1. Use create_date_range() to create Scrape objects for date ranges\n")
cat("2. Use fetch_flights() to fetch actual flight data from Google Flights\n")
cat("3. Use fa_flex_table() to create a wide summary table for easy comparison\n")
cat("4. Use fa_best_dates() to quickly identify the cheapest travel dates\n")
cat("5. Both fa_flex_table() and fa_best_dates() accept Scrape objects or data frames\n")
