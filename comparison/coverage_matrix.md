# Test case coverage matrix

| # | Case | Duration | Compute | Data | R analysis type | Status |
|---|------|----------|---------|------|------------------|--------|
| 01 | random_forest_classification | short | CPU | small, in-memory | ML classification | validated (Windows) |
| 02 | dplyr_wrangling | short | CPU | small, in-memory | data wrangling | validated (Windows) |
| 03 | linear_model | short | CPU | small, in-memory | statistical modeling | validated (Windows) |
| 04 | monte_carlo_simulation | long | CPU | small, in-memory | simulation | validated (Windows) |
| 05 | large_csv_io | short-medium, I/O-bound | CPU | large, on-disk | file I/O | validated (Windows) |
| 06 | multi_step_tracking | short | CPU | small, in-memory | tracker API (start/stop x3) | validated (Windows) |
| 07 | gpu_neural_net | medium-long | GPU | small-medium, in-memory | ML training | built, **not yet run** -- needs GPU hardware |

"Validated" means: rendered end to end, R and Python sides both produced
`emissions.csv` output, and `compare_emissions()`/`compare_emissions_multi()`
printed a comparison table without erroring. It does not mean every metric
landed inside the 20% tolerance on every run -- see each case's own
"Comparison" section output and the Tolerance note in `README.md` for what
a flagged metric does and doesn't imply.

01-06 above have only actually been rendered on Windows so far (this
round of work). CI (`.github/workflows/`) runs `R CMD check` and
`testthat` -- the package-level unit tests, not these comparison
notebooks -- across Windows, Linux, and Mac runners; it's a signal that
the *package* installs and passes its unit tests cross-platform, not that
every comparison case has been rendered on every OS. Extending this table
with real Linux/Mac renders of the comparison suite itself is separate,
follow-up work.

## Rationale

**01 random_forest_classification** is the direct analog of CodeCarbon's
own scikit-learn documentation example (`RandomForestClassifier` on
`make_classification` data). It's the primary accuracy calibration case:
same algorithm, same data shape, same hyperparameters on both sides, so any
divergence in reported numbers is attributable to CodeCarbonR's wrapper
rather than to the workload differing.

**02 dplyr_wrangling** and **03 linear_model** cover the R analysis types
CodeCarbon has no examples for, since its own example set is ML-focused.
Paired against pandas and `sklearn.linear_model` respectively (case 03
uses `sklearn` rather than `statsmodels` since `sklearn` is already a
dependency elsewhere in this suite).

**04 monte_carlo_simulation** is the long-running case, a loop-heavy
stochastic simulation (8,000,000 iterations, explicit `for` loop rather
than vectorized) with negligible memory footprint, to distinguish
CPU-time-driven emissions from anything data-size-driven. It's also the
only case that runs long enough (~1 minute on the reference machine) to
exercise codecarbon's periodic background sampling (default
`measure_power_secs = 15`) more than once; every other case's numbers come
entirely from the start/stop bookend measurement.

**05 large_csv_io** is the large-file case: generate, write, read back, and
aggregate a large CSV (~730 MB in validation runs, against a ~1 GB target)
to exercise disk I/O and rule out platform-specific file path or I/O
handling bugs. The file is generated fresh into the gitignored
`r_output`/`py_output` directories on every render and deleted at the end
of the chunk -- never checked into the repo.

**06 multi_step_tracking** exercises `carbon_tracker()$start()/$stop()`
across three phases in one script (data generation, training, prediction),
mirroring the "Multiple Trackers" pattern from CodeCarbon's own docs.
Originally built to reuse *one* tracker instance across all three
start/stop cycles; that turned out not to work -- codecarbon's
`OfflineEmissionsTracker.stop()` never resets its internal start time, so
a second `start()` on the same instance is a no-op and the following
`stop()` returns the first cycle's emissions/energy figures again,
frozen (confirmed identically on both the R and raw Python side, so it's
a codecarbon limitation, not a CodeCarbonR bug -- see
`R/tracker.R`'s `carbon_tracker()` docs and
`tests/testthat/test-tracker.R` for the regression tests that pin this).
The case now creates one tracker per phase instead, which does produce
independent per-phase numbers, and still exercises the repeated-append
path of `emissions.csv` since each `stop()` appends its own row.

**07 gpu_neural_net** is the GPU case, meant to run on a cloud GPU instance
rather than local hardware. Framework: R `torch` vs Python `PyTorch` (both
bind directly to libtorch, keeping the two sides independent rather than
routing one through the other the way `keras3` would via reticulate). The
code is complete but has not been run on GPU hardware -- neither the dev
environment nor CI for this repo has a GPU. It needs one validation run on
real GPU hardware, and its status here updated to `validated`, before the
paper leans on it for a cross-platform claim.

## Gaps not yet covered

- **Mac / Apple Silicon is untested**, not merely deferred: nothing in
  this suite has been run on macOS, on any chip. If cross-platform
  reproducibility claims in the paper need to cover Mac, that requires an
  actual run on Mac hardware (or a Mac CI runner) before submission --
  don't extrapolate Windows+Linux parity to Mac without evidence.
- **07 gpu_neural_net has not been run at all** (see table above and its
  own rationale entry) -- built but unvalidated, distinct from the Mac gap
  above.
- A high-memory, low-CPU case (e.g. large in-memory matrix operations
  without heavy disk I/O) is not represented; 05 covers disk I/O but not
  memory pressure specifically. Worth adding if memory-driven RAM power
  tracking needs its own validation.
- Nothing exercises `setup_carbon_tracker()` itself (the conda environment
  bootstrap) as part of the comparison suite. That's more of an
  installation test than a per-workload one, but should have its own
  coverage somewhere (e.g. a Windows/Linux CI step that runs setup on a
  clean environment).
