# Flight Analysis - R Package

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This R package provides tools and models for users to analyze, forecast, and collect data regarding flights and prices. This is an R port of the original Python package [google-flight-analysis](https://pypi.org/project/google-flight-analysis/).

## Features

Current features include:

- Detailed scraping and querying tools for Google Flights
- Ability to store data locally or to SQL tables
- Base analytical tools/methods for price forecasting/summary
- Support for multiple trip types: one-way, round-trip, chain-trip, and perfect-chain

## Installation

You can install the development version of flightanalysis from GitHub:

```r
# Install devtools if you haven't already
install.packages("devtools")

# Install flightanalysis
devtools::install_github("rempsyc/flight-analysis")
```

## Usage

### Loading the Package

```r
library(flightanalysis)
```

### Creating Flight Queries

The main scraping function that makes up the backbone of most functionalities is `Scrape()`. It serves as a data object, preserving the flight information as well as meta-data from your query.

#### One-Way Trip

```r
# Create a one-way flight query
scrape <- Scrape("JFK", "IST", "2023-07-20")
print(scrape)
```

#### Round-Trip

```r
# Create a round-trip flight query
scrape <- Scrape("JFK", "IST", "2023-07-20", "2023-08-20")
print(scrape)
```

#### Chain-Trip

Chain-trips are defined as a sequence of one-way flights that have no direct relation to each other, other than being in chronological order.

```r
# Chain-trip format: origin, dest, date, origin, dest, date, ...
scrape <- Scrape("JFK", "IST", "2023-08-20", "RDU", "LGA", "2023-12-25", "EWR", "SFO", "2024-01-20")
print(scrape)
```

#### Perfect-Chain

Perfect-chains are defined as a sequence of one-way flights such that the destination of the previous flight is the origin of the next, and the origin of the chain is the final destination (a cycle).

```r
# Perfect-chain format: origin, date, origin, date, ..., first_origin
scrape <- Scrape("JFK", "2023-09-20", "IST", "2023-09-25", "CDG", "2023-10-10", "LHR", "2023-11-01", "JFK")
print(scrape)
```

### Scraping Data

**Note:** Web scraping functionality requires additional setup with RSelenium and a Chrome/Firefox driver. The basic structure is in place, but full implementation requires:

1. Installing the RSelenium package
2. Setting up a browser driver (ChromeDriver or GeckoDriver)
3. Implementing the detailed web scraping logic

```r
# Placeholder function - requires RSelenium setup
ScrapeObjects(scrape)
```

### Working with Flight Objects

```r
# Create a Flight object
flight <- Flight("2023-07-20", "JFKIST", "9:00AM", "5:00PM", 
                 "8 hr 0 min", "Nonstop", "150 kg CO2", "10% emissions", "$450")

# Convert multiple flights to a data frame
flights <- list(flight1, flight2, flight3)
df <- flights_to_dataframe(flights)
```

### Caching Data

Store flight data locally or in a SQLite database:

```r
# Cache to CSV files
CacheControl("./cache/", scrape, use_db = FALSE)

# Cache to SQLite database
CacheControl("./flights.db", scrape, use_db = TRUE)
```

## Trip Types

The package supports multiple trip types:

- **One-way**: Single flight from origin to destination
- **Round-trip**: Flight to destination and return
- **Chain-trip**: Sequence of unrelated one-way flights in chronological order
- **Perfect-chain**: Sequence where each destination becomes the next origin, forming a cycle

## Package Structure

```
flightanalysis/
├── R/
│   ├── cache.R              # Caching functionality
│   ├── flight.R             # Flight class and methods
│   ├── scrape.R             # Scrape class and methods
│   └── flightanalysis-package.R  # Package documentation
├── tests/
│   └── testthat/            # Test files
│       ├── test-cache.R
│       ├── test-flight.R
│       └── test-scrape.R
├── DESCRIPTION              # Package metadata
├── NAMESPACE               # Package exports
└── README_R.md             # This file
```

## Differences from Python Version

This R package maintains the core functionality of the Python version but with R-specific implementations:

- Uses S3 classes instead of Python classes
- RSelenium instead of Python's selenium
- Base R data frames instead of pandas
- Native R date/time handling instead of Python's datetime

## Development Status

This is an initial R port of the Python package. The core data structures and API are implemented. Web scraping functionality with RSelenium requires additional configuration in the user's environment.

## License

MIT License

## Original Python Package

This is a port of the [google-flight-analysis](https://github.com/kcelebi/flight-analysis) Python package by Kaya Celebi.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
