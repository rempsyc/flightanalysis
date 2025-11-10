# Safe integer conversion that returns NA without warnings

Safely converts a character string to an integer by validating the input
format before conversion. Returns NA_integer\_ for invalid inputs
without generating warnings, unlike the base as.integer() function.

## Usage

``` r
safe_as_integer(x)
```

## Arguments

- x:

  Character string to convert to integer

## Value

An integer value, or NA_integer\_ if the input cannot be safely
converted
