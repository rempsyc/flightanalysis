#!/usr/bin/env Rscript

# Basic Usage Examples for flightanalysis Package
# This script demonstrates the main features of the package

cat("=== Flight Analysis R Package - Examples ===\n\n")

# Load the package functions
source('R/flight.R')
source('R/query.R')

# Example 1: One-Way Trip
cat("Example 1: One-Way Trip\n")
cat("------------------------\n")
query_oneway <- define_query("JFK", "IST", "2026-07-20")
print(query_oneway)
cat("\n")

# Example 2: Round-Trip
cat("Example 2: Round-Trip\n")
cat("---------------------\n")
query_roundtrip <- define_query("JFK", "IST", "2026-07-20", "2026-08-20")
print(query_roundtrip)
cat("\nTrip type:", query_roundtrip$type, "\n")
cat("Origins:", paste(unlist(query_roundtrip$origin), collapse = ", "), "\n")
cat(
  "Destinations:",
  paste(unlist(query_roundtrip$dest), collapse = ", "),
  "\n"
)
cat("\n")

# Example 3: Chain-Trip
cat("Example 3: Chain-Trip (Multiple unrelated flights)\n")
cat("---------------------------------------------------\n")
query_chain <- define_query(
  "JFK",
  "IST",
  "2026-08-20",
  "RDU",
  "LGA",
  "2026-12-25",
  "EWR",
  "SFO",
  "2027-01-20"
)
print(query_chain)
cat("\n")

# Example 4: Perfect-Chain
cat("Example 4: Perfect-Chain (Circular trip)\n")
cat("-----------------------------------------\n")
query_perfect <- define_query(
  "JFK",
  "2026-09-20",
  "IST",
  "2026-09-25",
  "CDG",
  "2026-10-10",
  "LHR",
  "2026-11-01",
  "JFK"
)
print(query_perfect)
cat("\n")

# Example 5: Working with Flight Objects
cat("Example 5: Creating Flight Objects\n")
cat("-----------------------------------\n")
flight1 <- Flight(
  "2026-07-20",
  "JFKIST",
  "9:00AM",
  "5:00PM",
  "8 hr 0 min",
  "Nonstop",
  "150 kg CO2",
  "10% emissions",
  "$450"
)
print(flight1)
cat("Price: $", flight1$price, "\n", sep = "")
cat("Number of stops:", flight1$num_stops, "\n")
cat("Flight time:", flight1$flight_time, "\n")
cat("\n")

# Example 6: Converting Flights to DataFrame
cat("Example 6: Converting Multiple Flights to DataFrame\n")
cat("----------------------------------------------------\n")
flight2 <- Flight(
  "2025-12-21",
  "ISTCDG",
  "10:30AM",
  "2:15PM",
  "3 hr 45 min",
  "1 stop",
  "120 kg CO2",
  "5% emissions",
  "$280"
)
flight3 <- Flight(
  "2025-12-22",
  "CDGLHR",
  "8:00AM",
  "9:30AM",
  "1 hr 30 min",
  "Nonstop",
  "80 kg CO2",
  "-10% emissions",
  "$150"
)

flights_list <- list(flight1, flight2, flight3)
df <- flights_to_dataframe(flights_list)

cat("Created data frame with", nrow(df), "flights\n")
cat("Columns:", paste(names(df), collapse = ", "), "\n")
cat("\nFirst few rows:\n")
print(utils::head(df, 3))
cat("\n")

# Example 7: URL Generation
cat("Example 7: Generated URLs for Google Flights\n")
cat("---------------------------------------------\n")
cat("One-way trip URL:\n")
cat(query_oneway$url[[1]], "\n\n")
cat("Round-trip URLs:\n")
cat("  Outbound:", query_roundtrip$url[[1]], "\n")
cat("  Return:  ", query_roundtrip$url[[2]], "\n\n")

cat("=== Examples completed successfully! ===\n")
