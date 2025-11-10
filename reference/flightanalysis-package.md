# flightanalysis: Google Flight Analysis and Scraping

Tools and models for users to analyze, forecast, and collect data
regarding flights and prices. Features include detailed scraping and
querying tools for Google Flights, ability to store data locally or to
SQL tables, and base analytical tools/methods for price
forecasting/summary.

This package provides tools and models for users to analyze, forecast,
and collect data regarding flights and prices. Current features include:

- Detailed scraping and querying tools for Google Flights

- Support for multiple trip types (one-way, round-trip, chain,
  perfect-chain)

- Base analytical tools/methods for price forecasting/summary

## Main Functions

- [`Scrape`](https://rempsyc.github.io/flightanalysis/reference/Scrape.md):

  Create a flight query object

- [`ScrapeObjects`](https://rempsyc.github.io/flightanalysis/reference/ScrapeObjects.md):

  Execute flight queries (requires chromote)

- [`Flight`](https://rempsyc.github.io/flightanalysis/reference/Flight.md):

  Create a flight data object

- [`flights_to_dataframe`](https://rempsyc.github.io/flightanalysis/reference/flights_to_dataframe.md):

  Convert Flight objects to data frame

## Trip Types

The package supports multiple trip types:

- **One-way**: Single flight from origin to destination

- **Round-trip**: Flight to destination and return

- **Chain-trip**: Sequence of unrelated one-way flights

- **Perfect-chain**: Sequence where each destination becomes the next
  origin

## See also

Useful links:

- <https://github.com/rempsyc/flightanalysis>

- <https://rempsyc.github.io/flightanalysis/>

- Report bugs at <https://github.com/rempsyc/flightanalysis/issues>

## Author

**Maintainer**: Rémi Thériault <remi.theriault@mail.mcgill.ca>
([ORCID](https://orcid.org/0000-0003-4315-6788))

Authors:

- Kaya Celebi <kayacelebi17@gmail.com> \[funder\]
