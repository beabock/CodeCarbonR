# CodeCarbonR 0.0.0.9000

## New features

- `setup_carbon_tracker()` installs codecarbon into a dedicated
  `r-codecarbon` conda environment, with confirmation.
- `carbon_tracker()` wraps a codecarbon `OfflineEmissionsTracker` with
  `$start()`/`$stop()`/`$flush()` methods.
- `with_emissions_tracked()` measures a single block of code in one call.
- `list_carbon_tracker_countries()` lists supported `country_iso_code`
  values.
- `carbon_tracker_ready()` checks whether codecarbon is installed and
  importable.

## Fixes

- `carbon_tracker()`/`with_emissions_tracked()` now create `output_dir`
  if it doesn't already exist, instead of crashing at `$stop()` after the
  tracked code has already run.

## codecarbon version compatibility

`setup_carbon_tracker()` installs codecarbon `>= 2.2.2` -- a floor, not an
exact pin (see `?setup_carbon_tracker` for why). Versions actually
validated against so far:

- **2.2.2** -- full local validation, Windows (comparison cases 01-06
  rendered end to end; `tests/testthat/test-tracker.R`'s tracker-restart
  regression test confirmed against this version directly).
- **3.3.0** -- validated via GitHub Actions CI (Windows/Mac/Linux,
  `R CMD check` + `testthat`), and directly against the tracker-restart
  behavior in an isolated environment. Tracker-restart behavior differs
  from 2.2.2 (see Known limitations below) but CodeCarbonR's own tests
  pass against both.

If you validate against a different version (e.g. a Monsoon HPC run),
add it to this list rather than replacing what's here -- the point is an
honest record of what's actually been checked, not just the most recent.

## Known limitations

- Restarting a single `carbon_tracker()` instance (`$start()` after a
  prior `$stop()`) does not produce an independent measurement for the
  new phase -- codecarbon's underlying tracker never resets its internal
  clock on `stop()`. What that produces downstream is codecarbon-version-
  dependent (frozen stale reading on 2.2.2, inflated cumulative reading on
  3.3.0 -- see the "codecarbon version compatibility" section above), but
  it's never a clean isolated measurement either way. Use a separate
  `carbon_tracker()` per phase instead. See `?carbon_tracker`.
- GPU tracking (`comparison/07_gpu_neural_net`) is implemented but not
  yet validated on real GPU hardware.
- Not yet tested on macOS/Apple Silicon.

See `comparison/coverage_matrix.md` for full validation status per test
case and platform.
