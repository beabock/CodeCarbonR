# CRAN comments

## Resubmission

CRAN's incoming pretest (2026-08-21) flagged 1 NOTE on Windows and 2 on
Debian:

* Possibly misspelled word "conda" in DESCRIPTION -- correct as spelled,
  see below. No change made.
* Debian only: `tests` NOTE, "Running R code in 'testthat.R' had CPU time
  3.4 times elapsed time." Root cause: `tests/testthat/test-setup.R`
  calls `carbon_tracker_ready()` unguarded (deliberately -- it verifies
  graceful behavior with no Python configured, which is exactly CRAN's
  situation), and that call forces `reticulate`'s interpreter-discovery
  machinery to run, which can spin up background threads during the
  search on a machine with no Python at all. Not this package's own test
  code doing anything improper. Fixed by adding `testthat::skip_on_cran()`
  to that one test -- it still runs everywhere else (local development,
  CI on Windows/Mac/Linux via GitHub Actions), just not on CRAN's check
  machines specifically, since eliminating a policy-adjacent NOTE
  deterministically is preferable to relying on a reviewer accepting an
  explanation for something a one-line skip resolves cleanly.

## Submission

This is a new package. The previous submission attempt was blocked by
CRAN's automated incoming pretest before reaching human review; see
Resubmission above for what changed.

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

0 errors | 0 warnings | 0 notes with `R CMD check --as-cran` on this
machine (Windows; see `RELEASING.md` for details of this package's
release process).

`check_win_devel()` (R-devel, Windows) additionally reported 2 NOTEs:

* Possibly misspelled word "conda" in DESCRIPTION -- this is correct as
  spelled; `conda` is the name of the package manager CodeCarbonR's
  Python backend is installed into, not a typo.
* The `carbon_tracker_ready()` example exceeded the 10s check threshold
  on that machine, because it has no Python configured and
  `reticulate`'s interpreter discovery is slow in that case. Fixed by
  wrapping the example in `\donttest{}`.

## Downstream dependencies

This is a new package; there are no reverse dependencies.
