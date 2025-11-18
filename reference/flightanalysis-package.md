# flightanalysis: Find the Best Flights

Tools and models for users to analyze, forecast, and collect data
regarding flights and prices. Features include detailed scraping and
querying tools for Google Flights.

This package provides tools and models for users to analyze, forecast,
and collect data regarding flights and prices. Current features include:

- Detailed scraping and querying tools for Google Flights

- Support for multiple trip types (one-way, round-trip, chain,
  perfect-chain)

- Flexible date search across multiple airports and date ranges

- Summary tables and best date identification for travel planning

- Base analytical tools/methods for price forecasting/summary

## Main Functions

- [`fa_define_query`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query.md):

  Create a flight query object

- [`fa_fetch_flights`](https://rempsyc.github.io/flightanalysis/reference/fa_fetch_flights.md):

  Execute flight queries (requires chromote)

- [`fa_define_query_range`](https://rempsyc.github.io/flightanalysis/reference/fa_define_query_range.md):

  Create queries for flexible date search

- [`fa_summarize_prices`](https://rempsyc.github.io/flightanalysis/reference/fa_summarize_prices.md):

  Create wide summary table for price comparison

- [`fa_find_best_dates`](https://rempsyc.github.io/flightanalysis/reference/fa_find_best_dates.md):

  Identify cheapest travel dates

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

- Kaya Celebi <kayacelebi17@gmail.com>
