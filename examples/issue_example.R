# Example matching the exact use case from GitHub issue
# https://github.com/rempsyc/flightanalysis/issues/XXX

library(flightanalysis)

# Optional: Use tibble for better display
if (requireNamespace("tibble", quietly = TRUE)) {
  library(tibble)
  
  # Define routes exactly as in the issue
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

# Define date range as specified in the issue
dates <- seq(as.Date("2025-12-18"), as.Date("2026-01-05"), by = "day")

cat("=== Flexible Date Search Example ===\n\n")
cat(sprintf("Routes: %d airports\n", nrow(routes)))
cat(sprintf("Dates: %d days (from %s to %s)\n", 
            length(dates), min(dates), max(dates)))
cat(sprintf("Total queries: %d\n\n", nrow(routes) * length(dates)))

# ==============================================================================
# IMPORTANT: Actual scraping is commented out to avoid making live requests
# Uncomment the following section to perform real scraping
# ==============================================================================

# cat("Starting scraping... (this will take a while)\n")
# 
# # Step 1: Create Scrape objects for all routes and dates
# scrapes <- fa_create_date_range(
#   origin = routes$Airport,
#   dest = "JFK",
#   date_min = min(dates),
#   date_max = max(dates)
# )
# 
# # Step 2: Scrape each origin
# for (code in names(scrapes)) {
#   cat(sprintf("Scraping %s...\n", code))
#   scrapes[[code]] <- fa_fetch_flights(scrapes[[code]], verbose = TRUE)
#   Sys.sleep(3)  # Pause between origins to be polite
# }
# 
# # Step 3: Extract results (fa_summarize_prices/fa_find_best_dates handle Scrape objects)
# summary_table <- fa_summarize_prices(scrapes)
# best_dates <- fa_find_best_dates(scrapes, n = 10, by = "min")
# 
# # Save results for later use
# saveRDS(list(scrapes = scrapes, summary = summary_table, best = best_dates), 
#         "flight_results.rds")

# ==============================================================================
# For demonstration, use mock data
# ==============================================================================

set.seed(42)
results <- data.frame(
  City = rep(routes$City, each = length(dates)),
  Airport = rep(routes$Airport, each = length(dates)),
  Dest = rep("JFK", nrow(routes) * length(dates)),
  Date = rep(as.character(dates), nrow(routes)),
  Price = round(runif(nrow(routes) * length(dates), 250, 850)),
  Comment = rep(routes$Comment, each = length(dates)),
  stringsAsFactors = FALSE
)

# ==============================================================================
# Create summary table (wide format: City × Date)
# ==============================================================================

cat("\n=== Creating Summary Table ===\n")
summary_table <- fa_summarize_prices(
  results,
  include_comment = TRUE,
  currency_symbol = "$",
  round_prices = TRUE
)

cat("\nSummary Table Preview (first 5 date columns):\n")
# Show first few columns
date_cols <- grep("^[0-9]{4}", names(summary_table), value = TRUE)
preview_cols <- c("City", "Airport", "Comment", date_cols[1:5], "Average_Price")
if (requireNamespace("tibble", quietly = TRUE)) {
  print(tibble::as_tibble(summary_table[, preview_cols]))
} else {
  print(summary_table[, preview_cols])
}

# ==============================================================================
# Find best dates to fly
# ==============================================================================

cat("\n=== Best Dates (by average price) ===\n")
best_dates_avg <- fa_find_best_dates(results, n = 10, by = "mean")
print(best_dates_avg)

cat("\n=== Best Dates (by minimum price) ===\n")
best_dates_min <- fa_find_best_dates(results, n = 5, by = "min")
print(best_dates_min)

# ==============================================================================
# Additional analysis
# ==============================================================================

cat("\n=== Price Statistics ===\n")
cat(sprintf("Overall cheapest flight: $%d\n", min(results$Price, na.rm = TRUE)))
cat(sprintf("Overall most expensive: $%d\n", max(results$Price, na.rm = TRUE)))
cat(sprintf("Average price: $%.2f\n", mean(results$Price, na.rm = TRUE)))

# Find cheapest route on average
route_avg <- aggregate(Price ~ City + Airport, data = results, FUN = mean)
route_avg <- route_avg[order(route_avg$Price), ]
cat(sprintf("\nCheapest route on average: %s (%s) - $%.2f\n",
            route_avg$City[1], route_avg$Airport[1], route_avg$Price[1]))

# ==============================================================================
# Tips for actual usage
# ==============================================================================

cat("\n=== Tips for Real Usage ===\n")
cat("1. Use fa_create_date_range() to create query objects\n")
cat("2. Use fa_fetch_flights() to fetch data for each route\n")
cat("3. Pass query objects directly to fa_summarize_prices() and fa_find_best_dates()\n")
cat("4. Save results with saveRDS() for later analysis\n")
cat("5. Run during off-peak hours to be considerate of Google's servers\n")
cat("6. Add Sys.sleep() pauses between scraping different origins\n")
