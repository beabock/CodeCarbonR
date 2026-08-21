# Track emissions for a single block of code

Track emissions for a single block of code

## Usage

``` r
with_emissions_tracked(expr, country_iso_code = NULL, ...)
```

## Arguments

- expr:

  Code to run and measure.

- country_iso_code:

  3-letter ISO code used to look up grid carbon intensity, e.g. `"USA"`.
  Call
  [`list_carbon_tracker_countries()`](https://beabock.github.io/CodeCarbonR/reference/list_carbon_tracker_countries.md)
  for the supported codes.

- ...:

  Passed to
  [`carbon_tracker()`](https://beabock.github.io/CodeCarbonR/reference/carbon_tracker.md).

## Value

A `carbon_emissions_result`: `$result` holds the value of `expr`,
`$emissions` holds the `carbon_emissions` object.

## Examples

``` r
# \donttest{
# Requires codecarbon to be installed (setup_carbon_tracker()); not run
# on CRAN's check machines, which don't have it.
if (carbon_tracker_ready()) {
  out <- with_emissions_tracked(
    Sys.sleep(1),
    country_iso_code = "USA",
    output_dir = tempdir()
  )
  print(out)
}
# }
```
