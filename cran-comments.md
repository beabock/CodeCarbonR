# CRAN comments

## Submission

This is the first submission of CodeCarbonR to CRAN.

CodeCarbonR wraps the Python `codecarbon` package (via `reticulate`) to
measure the energy consumption and estimated carbon emissions of R code.
There is no R-native equivalent of `codecarbon`, which is why this package
depends on a Python backend rather than reimplementing emissions tracking
natively.

## Notes on Python/conda dependency

* `setup_carbon_tracker()` is the only function that installs software. It
  is opt-in (never called automatically), requires explicit user
  confirmation via `utils::menu()`, and installs `codecarbon` into its own
  dedicated conda environment (`r-codecarbon`) rather than touching the
  user's system Python or any existing R/Python installation.
* `setup_carbon_tracker()` refuses to run in a non-interactive session
  (`stop()`s immediately if `!interactive()`), so it never runs during
  `R CMD check`, and this refusal is itself covered by a test
  (`tests/testthat/test-setup.R`).
* No example, test, or vignette installs software, writes outside
  `tempdir()`, or requires network access during `R CMD check`.
  Examples and tests that would otherwise touch Python/codecarbon are
  wrapped in `\donttest{}`/`\dontrun{}` or guarded with
  `testthat::skip_on_cran()` plus a runtime `carbon_tracker_ready()`
  check, so they no-op cleanly on CRAN's check machines (which will not
  have codecarbon installed).
* `vignettes/quickstart.Rmd` uses `eval = FALSE` on every chunk and shows
  realistic example output as literal text, so building it never touches
  Python or the network.

## R CMD check results

0 errors | 0 warnings | 0 notes (checked with `R CMD check --as-cran` on
Windows; see `RELEASING.md` for details of this package's release
process).

## Downstream dependencies

This is a new package; there are no reverse dependencies.
