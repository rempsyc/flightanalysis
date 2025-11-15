# Generate sample datasets for flightanalysis package

library(flightanalysis)

# Sample 1: Simple query object
sample_query <- fa_define_query("JFK", "IST", "2025-12-20", "2025-12-27")
usethis::use_data(sample_query, overwrite = TRUE)

# Sample 2: Sample flight data
sample_flights <- data.frame(
  departure_date = c(
    "2025-12-20", "2025-12-20", "2025-12-20", "2025-12-21",
    "2025-12-27", "2025-12-27"
  ),
  departure_time = c(
    "09:00", "14:30", "22:00", "10:15", "08:30", "15:45"
  ),
  arrival_date = c(
    "2025-12-20", "2025-12-21", "2025-12-21", "2025-12-21",
    "2025-12-27", "2025-12-28"
  ),
  arrival_time = c(
    "22:00", "03:45", "11:30", "23:30", "21:15", "05:00"
  ),
  origin = c("JFK", "JFK", "JFK", "JFK", "IST", "IST"),
  destination = c("IST", "IST", "IST", "IST", "JFK", "JFK"),
  airlines = c(
    "Turkish Airlines", "Lufthansa", "LOT Polish Airlines",
    "Air France", "Turkish Airlines", "United Airlines"
  ),
  travel_time = c(
    "13 hr 0 min", "13 hr 15 min", "13 hr 30 min",
    "13 hr 15 min", "12 hr 45 min", "13 hr 15 min"
  ),
  price = c(650, 720, 580, 695, 620, 685),
  num_stops = c(0, 1, 1, 1, 0, 1),
  layover = c(NA, "2 hr 30 min FRA", "3 hr 15 min WAW", 
              "2 hr 45 min CDG", NA, "3 hr 10 min EWR"),
  access_date = rep(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), 6),
  co2_emission_kg = c(550, 580, 600, 570, 540, 575),
  emission_diff_pct = c(5, 10, 15, 8, 3, 9),
  stringsAsFactors = FALSE
)
usethis::use_data(sample_flights, overwrite = TRUE)

# Sample 3: Multiple origin queries
sample_multi_origin <- fa_define_query_range(
  origin = c("BOM", "DEL"),
  dest = "JFK",
  date_min = "2025-12-18",
  date_max = "2025-12-22"
)
usethis::use_data(sample_multi_origin, overwrite = TRUE)

cat("✓ All sample datasets created successfully!\n")
cat("  - sample_query: Simple round-trip query\n")
cat("  - sample_flights: Sample flight data (6 flights)\n")
cat("  - sample_multi_origin: Multiple origin queries\n")
