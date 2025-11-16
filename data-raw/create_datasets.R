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

# Sample 4: Rich sample_flight_results for impressive visualizations
# 5 airports from Dec 18 to Jan 5 with Christmas price spike
set.seed(123)
dates <- seq(as.Date("2025-12-18"), as.Date("2026-01-05"), by = "day")
origins <- c("BOM", "DEL", "VNS", "PAT", "GAY")
destination <- "JFK"

# Generate realistic flight data with Christmas price spike
flights_data <- data.frame()
for (origin in origins) {
  # Base travel time varies by origin (Mumbai shortest, Gaya longest)
  base_travel_time <- switch(origin,
    "BOM" = 15.5,
    "DEL" = 16.0,
    "VNS" = 17.5,
    "PAT" = 18.0,
    "GAY" = 18.5
  )
  
  # Base price varies by origin
  base_price <- switch(origin,
    "BOM" = 600,
    "DEL" = 580,
    "VNS" = 650,
    "PAT" = 680,
    "GAY" = 700
  )
  
  for (date in as.character(dates)) {
    date_obj <- as.Date(date)
    
    # Add some randomness to travel time
    travel_time_hrs <- base_travel_time + runif(1, -0.5, 1.0)
    travel_time_min <- floor((travel_time_hrs %% 1) * 60)
    travel_time_str <- sprintf("%d hr %d min", floor(travel_time_hrs), travel_time_min)
    
    # Create Christmas price spike pattern (Dec 23 - Jan 3)
    # Price gradually increases towards Christmas/New Year, peaks around Jan 1-2, then drops
    christmas_start <- as.Date("2025-12-23")
    peak_date <- as.Date("2026-01-02")
    christmas_end <- as.Date("2026-01-03")
    
    if (date_obj >= christmas_start && date_obj <= christmas_end) {
      # Calculate position in the Christmas period (0 to 1)
      days_since_start <- as.numeric(date_obj - christmas_start)
      total_days <- as.numeric(christmas_end - christmas_start)
      position <- days_since_start / total_days
      
      # Create spike: price increases to peak, then drops
      # Use a smooth curve that peaks around position 0.75 (Jan 1-2)
      spike_factor <- 1 + 2.5 * (1 - abs(position - 0.75) * 1.5)
      spike_factor <- max(1.3, min(4.5, spike_factor))  # Cap between 1.3x and 4.5x
    } else {
      spike_factor <- 1.0
    }
    
    # Weekend adjustment
    is_weekend <- weekdays(date_obj) %in% c("Saturday", "Sunday")
    weekend_factor <- ifelse(is_weekend, 1.1, 1.0)
    
    # Final price with spike, weekend adjustment, and randomness
    price <- round(base_price * spike_factor * weekend_factor + rnorm(1, 0, 30))
    
    # Randomize other fields
    num_stops <- sample(0:2, 1, prob = c(0.5, 0.4, 0.1))
    
    flights_data <- rbind(flights_data, data.frame(
      departure_date = date,
      departure_time = sprintf("%02d:%02d", sample(6:22, 1), sample(c(0, 15, 30, 45), 1)),
      arrival_date = date,
      arrival_time = sprintf("%02d:%02d", sample(6:22, 1), sample(c(0, 15, 30, 45), 1)),
      origin = origin,
      destination = destination,
      airlines = sample(c("Air India", "United", "Lufthansa", "Emirates", "Turkish Airlines"), 1),
      travel_time = travel_time_str,
      price = price,
      num_stops = num_stops,
      layover = ifelse(num_stops > 0, 
                      sprintf("%d hr %d min %s", 
                              sample(2:5, 1), 
                              sample(c(0, 15, 30, 45), 1),
                              sample(c("FRA", "LHR", "DXB", "IST"), 1)),
                      NA),
      access_date = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      co2_emission_kg = round(400 + travel_time_hrs * 30 + rnorm(1, 0, 20)),
      emission_diff_pct = round(runif(1, -5, 15), 1),
      stringsAsFactors = FALSE
    ))
  }
}

# Create proper flight_results object with query structure
# We need to create mock query objects for each origin
sample_flight_results <- list(data = flights_data)

# Add mock query objects for each origin (required by extract_data_from_scrapes)
for (origin in origins) {
  origin_data <- flights_data[flights_data$origin == origin, ]
  sample_flight_results[[origin]] <- list(
    data = origin_data,
    origin = origin,
    dest = destination
  )
  class(sample_flight_results[[origin]]) <- "flight_query"
}

class(sample_flight_results) <- "flight_results"
usethis::use_data(sample_flight_results, overwrite = TRUE)

cat("✓ All sample datasets created successfully!\n")
cat("  - sample_query: Simple round-trip query\n")
cat("  - sample_flights: Sample flight data (6 flights)\n")
cat("  - sample_multi_origin: Multiple origin queries\n")
cat("  - sample_flight_results: Rich dataset (5 origins, 10 days, 50 flights)\n")
