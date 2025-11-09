#!/usr/bin/env Rscript

# Basic Usage Examples for flightanalysis Package
# This script demonstrates the main features of the package

cat("=== Flight Analysis R Package - Examples ===\n\n")

# Load the package functions
source('../R/flight.R')
source('../R/scrape.R')
source('../R/cache.R')

# Example 1: One-Way Trip
cat("Example 1: One-Way Trip\n")
cat("------------------------\n")
scrape_oneway <- Scrape("JFK", "IST", "2023-07-20")
print(scrape_oneway)
cat("\n")

# Example 2: Round-Trip
cat("Example 2: Round-Trip\n")
cat("---------------------\n")
scrape_roundtrip <- Scrape("JFK", "IST", "2023-07-20", "2023-08-20")
print(scrape_roundtrip)
cat("\nTrip type:", scrape_roundtrip$type, "\n")
cat("Origins:", paste(unlist(scrape_roundtrip$origin), collapse = ", "), "\n")
cat("Destinations:", paste(unlist(scrape_roundtrip$dest), collapse = ", "), "\n")
cat("\n")

# Example 3: Chain-Trip
cat("Example 3: Chain-Trip (Multiple unrelated flights)\n")
cat("---------------------------------------------------\n")
scrape_chain <- Scrape("JFK", "IST", "2023-08-20", 
                       "RDU", "LGA", "2023-12-25", 
                       "EWR", "SFO", "2024-01-20")
print(scrape_chain)
cat("\n")

# Example 4: Perfect-Chain
cat("Example 4: Perfect-Chain (Circular trip)\n")
cat("-----------------------------------------\n")
scrape_perfect <- Scrape("JFK", "2023-09-20", 
                         "IST", "2023-09-25", 
                         "CDG", "2023-10-10", 
                         "LHR", "2023-11-01", 
                         "JFK")
print(scrape_perfect)
cat("\n")

# Example 5: Working with Flight Objects
cat("Example 5: Creating Flight Objects\n")
cat("-----------------------------------\n")
flight1 <- Flight("2023-07-20", "JFKIST", "9:00AM", "5:00PM", 
                  "8 hr 0 min", "Nonstop", "150 kg CO2", "10% emissions", "$450")
print(flight1)
cat("Price: $", flight1$price, "\n", sep = "")
cat("Number of stops:", flight1$num_stops, "\n")
cat("Flight time:", flight1$flight_time, "\n")
cat("\n")

# Example 6: Converting Flights to DataFrame
cat("Example 6: Converting Multiple Flights to DataFrame\n")
cat("----------------------------------------------------\n")
flight2 <- Flight("2023-07-21", "ISTCDG", "10:30AM", "2:15PM", 
                  "3 hr 45 min", "1 stop", "120 kg CO2", "5% emissions", "$280")
flight3 <- Flight("2023-07-22", "CDGLHR", "8:00AM", "9:30AM", 
                  "1 hr 30 min", "Nonstop", "80 kg CO2", "-10% emissions", "$150")

flights_list <- list(flight1, flight2, flight3)
df <- flights_to_dataframe(flights_list)

cat("Created data frame with", nrow(df), "flights\n")
cat("Columns:", paste(names(df), collapse = ", "), "\n")
cat("\nFirst few rows:\n")
print(head(df, 3))
cat("\n")

# Example 7: URL Generation
cat("Example 7: Generated URLs for Google Flights\n")
cat("---------------------------------------------\n")
cat("One-way trip URL:\n")
cat(scrape_oneway$url[[1]], "\n\n")
cat("Round-trip URLs:\n")
cat("  Outbound:", scrape_roundtrip$url[[1]], "\n")
cat("  Return:  ", scrape_roundtrip$url[[2]], "\n\n")

# Example 8: Caching (demonstration of the API)
cat("Example 8: Caching Data (API demonstration)\n")
cat("--------------------------------------------\n")
cat("To cache flight data to CSV:\n")
cat("  CacheControl('./cache/', scrape_object, use_db = FALSE)\n\n")
cat("To cache flight data to SQLite database:\n")
cat("  CacheControl('./flights.db', scrape_object, use_db = TRUE)\n\n")
cat("Note: Caching requires that the Scrape object has data.\n")
cat("      Use ScrapeObjects() to populate the data field (requires RSelenium).\n\n")

cat("=== Examples completed successfully! ===\n")
