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
# results <- fa_scrape_best_oneway(
#   routes = routes,
#   dates = dates,
#   keep_offers = FALSE,  # Only keep cheapest per day
#   pause = 3,            # Wait 3 seconds between requests (be polite!)
#   headless = TRUE,      # Run browser in background
#   verbose = TRUE        # Show progress
# )
# 
# # Save results for later use
# saveRDS(results, "flight_results.rds")

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
summary_table <- fa_flex_table(
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
best_dates_avg <- fa_best_dates(results, n = 10, by = "mean")
print(best_dates_avg)

cat("\n=== Best Dates (by minimum price) ===\n")
best_dates_min <- fa_best_dates(results, n = 5, by = "min")
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
cat("1. Uncomment the fa_scrape_best_oneway() call above\n")
cat("2. Adjust 'pause' based on your needs (2-5 seconds recommended)\n")
cat("3. Use keep_offers=TRUE to store all flight options\n")
cat("4. Save results with saveRDS() for later analysis\n")
cat("5. Run during off-peak hours to be considerate of Google's servers\n")
cat("6. Consider scraping in smaller batches (e.g., 5 dates at a time)\n")

cat("\n=== Example: Keeping All Offers ===\n")
cat("To keep all flight offers (not just cheapest):\n\n")
cat("results_full <- fa_scrape_best_oneway(\n")
cat("  routes = routes,\n")
cat("  dates = dates[1:3],  # Just first 3 dates for testing\n")
cat("  keep_offers = TRUE,   # Keep all offers!\n")
cat("  pause = 3\n")
cat(")\n\n")
cat("# Access all offers for a specific route-date:\n")
cat("all_flights <- results_full$Offers[[1]]\n")
cat("print(all_flights)\n")
