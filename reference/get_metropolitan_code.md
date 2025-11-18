# Get Metropolitan Area Code for City Name

Internal function to check if a city name has a corresponding
metropolitan area code (e.g., "New York" -\> "NYC", "London" -\> "LON").
These codes are used by airlines and Google Flights to represent all
airports in a metropolitan area.

## Usage

``` r
get_metropolitan_code(city_name)
```

## Arguments

- city_name:

  Character string of a city name

## Value

Metropolitan area code if it exists, NULL otherwise
