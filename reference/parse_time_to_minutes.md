# Parse Time Duration to Minutes

Internal helper function to parse time duration strings or numeric
values to minutes. Handles both numeric (hours) and character ("XX hr XX
min") formats.

## Usage

``` r
parse_time_to_minutes(time_value)
```

## Arguments

- time_value:

  Numeric or character. If numeric, interpreted as hours. If character,
  parsed as "XX hr XX min" format.

## Value

Numeric value in minutes
