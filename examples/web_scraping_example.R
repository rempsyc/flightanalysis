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
source('R/scrape.R')
source('R/cache.R')
cat("✓ Package loaded\n\n")

# Example 1: Simple one-way trip scraping
cat("Example 1: Scraping a One-Way Trip\n")
cat("-----------------------------------\n")
cat("Creating query: JFK -> IST on 2026-07-20\n\n")

scrape_oneway <- Scrape("JFK", "IST", "2026-07-20")

cat("Query details:\n")
print(scrape_oneway)
cat("\n")

cat("Now scraping live data from Google Flights...\n")
cat("(Pre-flight checks and driver initialization will run automatically)\n\n")

tryCatch(
  {
    ScrapeObjects(scrape_oneway, headless = TRUE)

    if (nrow(scrape_oneway$data) > 0) {
      cat("\n✓ Successfully scraped", nrow(scrape_oneway$data), "flights!\n\n")

      cat("Sample of scraped data:\n")
      print(head(scrape_oneway$data, 3))
      cat("\n")

      cat("Summary statistics:\n")
      cat(
        "  - Average price: $",
        round(mean(scrape_oneway$data$price, na.rm = TRUE), 2),
        "\n",
        sep = ""
      )
      cat(
        "  - Min price: $",
        min(scrape_oneway$data$price, na.rm = TRUE),
        "\n",
        sep = ""
      )
      cat(
        "  - Max price: $",
        max(scrape_oneway$data$price, na.rm = TRUE),
        "\n",
        sep = ""
      )
      cat(
        "  - Direct flights:",
        sum(scrape_oneway$data$num_stops == 0, na.rm = TRUE),
        "\n"
      )
      cat(
        "  - Flights with stops:",
        sum(scrape_oneway$data$num_stops > 0, na.rm = TRUE),
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
    cat("  4. Try running with headless = FALSE to see what's happening\n")
  }
)

cat("\n")

# Example 2: Round-trip scraping with caching
cat("Example 2: Round-Trip with Caching\n")
cat("-----------------------------------\n")
cat("Creating query: JFK <-> IST (2026-07-20 to 2026-08-05)\n\n")

scrape_roundtrip <- Scrape("JFK", "IST", "2026-07-20", "2026-08-05")

cat("This example demonstrates:\n")
cat("  1. Scraping multiple flight segments (outbound + return)\n")
cat("  2. Caching results to a CSV file\n\n")

tryCatch(
  {
    cat("Scraping (this may take a moment for 2 segments)...\n")
    ScrapeObjects(scrape_roundtrip, headless = TRUE)

    if (nrow(scrape_roundtrip$data) > 0) {
      cat(
        "\n✓ Successfully scraped",
        nrow(scrape_roundtrip$data),
        "total flights\n"
      )

      # Cache the data
      cache_dir <- "/tmp/flight_cache"
      cat("\nCaching data to:", cache_dir, "\n")

      tryCatch(
        {
          CacheControl(cache_dir, scrape_roundtrip, use_db = FALSE)
          cat("✓ Data cached successfully\n")

          # List cached files
          cached_files <- list.files(
            cache_dir,
            pattern = "\\.csv$",
            full.names = TRUE
          )
          if (length(cached_files) > 0) {
            cat("\nCached files:\n")
            for (f in cached_files) {
              cat("  -", basename(f), "\n")
            }
          }
        },
        error = function(e) {
          cat("⚠ Could not cache data:", conditionMessage(e), "\n")
        }
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
cat("  • Use headless = FALSE if you want to watch the scraping process\n")
cat("  • Cache your results to avoid re-scraping the same data\n")
cat("  • Respect Google's terms of service and rate limits\n")
