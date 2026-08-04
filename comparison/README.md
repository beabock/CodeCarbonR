# Comparison test suite

Each subdirectory pairs an R workload run through CodeCarbonR with the same
workload run through CodeCarbon directly in Python, so the two can be
diffed. This is both the accuracy validation suite (does CodeCarbonR report
the same numbers CodeCarbon does for an equivalent run) and the general
test coverage suite (does CodeCarbonR run without error across a range of
script types and platforms).

See `coverage_matrix.md` for the full list of test cases and what each one
is meant to exercise.

## Layout

```
comparison/
  _harness/compare_emissions.R   diffs r_output/emissions.csv against py_output/emissions.csv
  _template/test.qmd             starting point for a new test case
  01_random_forest_classification/test.qmd
  02_dplyr_wrangling/test.qmd
  ...
```

Each test case is a single `.qmd` with three sections: an R chunk running
the workload under `with_emissions_tracked()`, a Python chunk running the
same workload under `codecarbon.OfflineEmissionsTracker`, and a comparison
chunk that calls `compare_emissions()` on the two outputs.

`r_output/` and `py_output/` are generated on render and are gitignored.
Render a case with:

```
quarto render comparison/01_random_forest_classification/test.qmd
```

## Why OfflineEmissionsTracker on both sides

CodeCarbonR always uses `OfflineEmissionsTracker`, which takes
`country_iso_code` directly instead of resolving location by IP geolocation.
The Python side of every comparison must also use `OfflineEmissionsTracker`
with the same `country_iso_code`. Pairing it against the default
`EmissionsTracker` would pull carbon intensity from a different source
(geolocation lookup vs. the country code table) and the emissions figures
would not be comparable, independent of anything CodeCarbonR does.

## Tolerance

`compare_emissions()` flags a metric when R and Python differ by more than
20% (`tolerance` argument). This is not a precision guarantee, it's a
sanity check: CPU power sampling has run-to-run variance on its own, so
some spread between two separate runs is expected even with identical
code. A case that fails the tolerance check is a prompt to look closer, not
automatically a bug.

## Platform coverage

Tested on Windows and Linux this round. Apple Silicon is deferred to a
later round. The GPU test case is designed to run on a cloud GPU instance
rather than local hardware.
