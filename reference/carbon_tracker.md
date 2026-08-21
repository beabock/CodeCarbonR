# Create a carbon emissions tracker

Wraps a codecarbon `OfflineEmissionsTracker`. Call `$start()` before the
code you want to measure and `$stop()` after, or use
[`with_emissions_tracked()`](https://beabock.github.io/CodeCarbonR/reference/with_emissions_tracked.md)
to measure a single block in one call.

## Usage

``` r
carbon_tracker(country_iso_code = NULL, project_name = "CodeCarbonR", ...)
```

## Arguments

- country_iso_code:

  3-letter ISO code used to look up grid carbon intensity, e.g. `"USA"`.
  Call
  [`list_carbon_tracker_countries()`](https://beabock.github.io/CodeCarbonR/reference/list_carbon_tracker_countries.md)
  for the supported codes.

- project_name:

  Label attached to the tracked run.

- ...:

  Passed to `codecarbon.OfflineEmissionsTracker`, e.g.
  `measure_power_secs`, `output_dir`, `log_level`.

## Value

A `CarbonTracker` R6 object.

## Details

Each tracker instance supports one `$start()`/`$stop()` cycle. Calling
`$start()` again after `$stop()` on the same instance does not restart
measurement, because codecarbon's underlying tracker never resets its
internal clock – but exactly what the next `$stop()` returns depends on
the installed codecarbon version: codecarbon 2.x returns the first
cycle's emissions/energy figures again, frozen; codecarbon 3.x instead
keeps accumulating energy from the original start, so the second reading
comes back inflated rather than frozen. Either way it is not an isolated
measurement of the second cycle's own work, and `duration` keeps
climbing from the original start rather than resetting. To measure
several phases separately, create a new `carbon_tracker()` per phase;
each `$stop()` still appends its own row to the same `output_dir`'s
`emissions.csv`.

## Examples

``` r
# \donttest{
# Requires codecarbon to be installed (setup_carbon_tracker()); not run
# on CRAN's check machines, which don't have it.
if (carbon_tracker_ready()) {
  tracker <- carbon_tracker(country_iso_code = "USA", output_dir = tempdir())
  tracker$start()
  Sys.sleep(1)
  emissions <- tracker$stop()
  print(emissions)
}
#> Downloading uv...
#> Done!
# }
```
