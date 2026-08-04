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

## Known limitations

- Restarting a single `carbon_tracker()` instance (`$start()` after a
  prior `$stop()`) does not produce an independent measurement for the
  new phase -- codecarbon's underlying tracker never resets its internal
  clock on `stop()`. Use a separate `carbon_tracker()` per phase instead.
  See `?carbon_tracker`.
- GPU tracking (`comparison/07_gpu_neural_net`) is implemented but not
  yet validated on real GPU hardware.
- Not yet tested on macOS/Apple Silicon.

See `comparison/coverage_matrix.md` for full validation status per test
case and platform.
