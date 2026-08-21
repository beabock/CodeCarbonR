# Install codecarbon into a dedicated conda environment

Installs Miniconda if it isn't already present, then creates the
"r-codecarbon" conda environment and installs codecarbon into it. Run
this once per machine before using
[`carbon_tracker()`](https://beabock.github.io/CodeCarbonR/reference/carbon_tracker.md)
or
[`with_emissions_tracked()`](https://beabock.github.io/CodeCarbonR/reference/with_emissions_tracked.md).
Nothing is installed without confirmation, and the function refuses to
run outside an interactive session.

## Usage

``` r
setup_carbon_tracker(force = FALSE)
```

## Arguments

- force:

  Reinstall codecarbon even if it's already available.

## Value

Invisibly, `TRUE` if codecarbon is ready to use after the call, `FALSE`
if setup was cancelled.

## Details

Installs codecarbon `>= 2.2.2` – a floor, not an exact pin. That's the
oldest version this package has actually been validated against (see
`comparison/coverage_matrix.md` and `NEWS.md` for exactly which versions
were validated, and where); newer codecarbon releases are expected and
welcome, since they bring updated carbon-intensity data along with
whatever bug fixes landed upstream. codecarbon's behavior has changed
between versions before (see
[`carbon_tracker()`](https://beabock.github.io/CodeCarbonR/reference/carbon_tracker.md)'s
docs on tracker restart), so if something about CodeCarbonR's output
looks different after a codecarbon upgrade, that's the first thing to
check. Keep the floor here in sync with DESCRIPTION's
`SystemRequirements` field if it changes.

## Examples

``` r
if (FALSE) { # \dontrun{
# Installs software and prompts for confirmation, so this never runs
# under R CMD check (or any other non-interactive session) -- call it
# once, by hand, from an interactive R console.
setup_carbon_tracker()
} # }
```
