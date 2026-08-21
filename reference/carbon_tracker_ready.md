# Check whether codecarbon is installed and importable

Check whether codecarbon is installed and importable

## Usage

``` r
carbon_tracker_ready()
```

## Value

`TRUE` if codecarbon can be imported, `FALSE` otherwise (including when
no Python interpreter can be found at all).

## Examples

``` r
# \donttest{
# Not \dontrun{} -- this genuinely works, it's just slow: on a machine
# with no Python configured (e.g. a fresh CRAN check environment),
# reticulate's interpreter discovery alone can take >10s before this
# returns FALSE. \donttest{} keeps it out of the default check timing
# while still letting CRAN's extended checks and interactive users
# verify it actually runs.
carbon_tracker_ready()
#> [1] FALSE
# }
```
