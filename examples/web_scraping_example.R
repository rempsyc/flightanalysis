#!/usr/bin/env Rscript

# Web Scraping Example for flightanalysis Package
# This script demonstrates live web scraping from Google Flights

cat("=== Flight Analysis R Package - Web Scraping Example ===\n\n")

# Check if required packages are installed
required_packages <- c("chromote", "progress")
missing_packages <- required_packages[
  !sapply(required_packages, requireNamespace, quietly = TRUE)
]

if (length(missing_packages) > 0) {
  cat(
    "Missing required packages:",
    paste(missing_packages, collapse = ", "),
    "\n"
  )
  cat(
    "Install them with: install.packages(c('",
    paste(missing_packages, collapse = "', '"),
    "'))\n\n",
    sep = ""
  )
  cat("Note: chromote requires Chrome or Chromium to be installed.\n")
  cat("This example will not run without these packages.\n")
  quit(status = 1)
}

# Load the package functions
cat("Loading flightanalysis package...\n")
source('R/flight.R')
source('R/query.R')
cat("✓ Package loaded\n\n")

# Example 1: Simple one-way trip scraping
cat("Example 1: Scraping a One-Way Trip\n")
cat("-----------------------------------\n")
cat("Creating query: JFK -> IST on 2026-07-20\n\n")

query_oneway <- fa_query("JFK", "IST", "2026-07-20")

cat("Query details:\n")
print(query_oneway)
cat("\n")

cat("Now scraping live data from Google Flights...\n")
cat("(Pre-flight checks and driver initialization will run automatically)\n\n")

tryCatch(
  {
    # IMPORTANT: Must capture the return value!
    query_oneway <- fa_fetch_flights(query_oneway)

    if (nrow(query_oneway$data) > 0) {
      cat("\n✓ Successfully scraped", nrow(query_oneway$data), "flights!\n\n")

      cat("Sample of scraped data:\n")
      print(utils::head(query_oneway$data, 3))
      cat("\n")

      cat("Summary statistics:\n")
      cat(
        "  - Average price: $",
        round(mean(query_oneway$data$price, na.rm = TRUE), 2),
        "\n",
        sep = ""
      )
      cat(
        "  - Min price: $",
        min(query_oneway$data$price, na.rm = TRUE),
        "\n",
        sep = ""
      )
      cat(
        "  - Max price: $",
        max(query_oneway$data$price, na.rm = TRUE),
        "\n",
        sep = ""
      )
      cat(
        "  - Direct flights:",
        sum(query_oneway$data$num_stops == 0, na.rm = TRUE),
        "\n"
      )
      cat(
        "  - Flights with stops:",
        sum(query_oneway$data$num_stops > 0, na.rm = TRUE),
        "\n"
      )
    } else {
      cat("⚠ No flights found. This may be due to:\n")
      cat("  - No available flights for this route/date\n")
      cat("  - Changes in Google Flights page structure\n")
      cat("  - Network connectivity issues\n")
    }
  },
  error = function(e) {
    cat("\n✗ Error during scraping:", conditionMessage(e), "\n\n")
    cat("Troubleshooting tips:\n")
    cat("  1. Make sure Chrome/Chromium is installed\n")
    cat("  2. Check your internet connection\n")
    cat("  3. Verify that Google Flights is accessible\n")
  }
)

cat("\n")

# Example 2: Round-trip scraping
cat("Example 2: Round-Trip Scraping\n")
cat("-------------------------------\n")
cat("Creating query: JFK <-> IST (2026-07-20 to 2026-08-05)\n\n")

query_roundtrip <- fa_query("JFK", "IST", "2026-07-20", "2026-08-05")

cat("This example demonstrates:\n")
cat("  1. Scraping multiple flight segments (outbound + return)\n")
cat("  2. Analyzing the combined results\n\n")

tryCatch(
  {
    cat("Scraping (this may take a moment for 2 segments)...\n")
    # IMPORTANT: Must capture the return value!
    query_roundtrip <- fa_fetch_flights(query_roundtrip)

    if (nrow(query_roundtrip$data) > 0) {
      cat(
        "\n✓ Successfully scraped",
        nrow(query_roundtrip$data),
        "total flights\n"
      )

      # Display summary
      cat("\nFlight summary:\n")
      cat("  - Total flights:", nrow(query_roundtrip$data), "\n")
      cat(
        "  - Average price: $",
        round(mean(query_roundtrip$data$price, na.rm = TRUE), 2),
        "\n",
        sep = ""
      )

      # Save to CSV manually if desired
      cat(
        "\nTo save results, use: write.csv(query_roundtrip$data, 'flights.csv', row.names = FALSE)\n"
      )
    }
  },
  error = function(e) {
    cat("\n✗ Error during scraping:", conditionMessage(e), "\n")
  }
)

cat("\n=== Example completed ===\n\n")

cat("Tips for successful scraping:\n")
cat(
  "  • Use realistic future dates (Google Flights typically shows ~6-12 months ahead)\n"
)
cat("  • Be patient - scraping can take 10-30 seconds per flight segment\n")
cat("  • The browser runs in headless mode (no visible GUI) by default\n")
cat("  • Save your results using write.csv() or other data export methods\n")
cat("  • Respect Google's terms of service and rate limits\n")
