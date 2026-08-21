# List supported country codes for carbon intensity lookup

Reads the country energy mix data bundled with the installed codecarbon
package. The `country_iso_code` argument to
[`carbon_tracker()`](https://beabock.github.io/CodeCarbonR/reference/carbon_tracker.md)
and
[`with_emissions_tracked()`](https://beabock.github.io/CodeCarbonR/reference/with_emissions_tracked.md)
must be one of the codes returned here.

## Usage

``` r
list_carbon_tracker_countries()
```

## Value

A data frame with `iso_code` and `country_name` columns.

## Examples

``` r
# \donttest{
# Requires codecarbon to be installed (setup_carbon_tracker()); not run
# on CRAN's check machines, which don't have it.
if (carbon_tracker_ready()) {
  countries <- list_carbon_tracker_countries()
  head(countries)
}
# }
```
