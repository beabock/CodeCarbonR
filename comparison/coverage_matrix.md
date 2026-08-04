# Test case coverage matrix

| # | Case | Duration | Compute | Data | R analysis type | Status |
|---|------|----------|---------|------|------------------|--------|
| 01 | random_forest_classification | short | CPU | small, in-memory | ML classification | built |
| 02 | dplyr_wrangling | short | CPU | small, in-memory | data wrangling | placeholder |
| 03 | linear_model | short | CPU | small, in-memory | statistical modeling | placeholder |
| 04 | monte_carlo_simulation | long | CPU | small, in-memory | simulation | placeholder |
| 05 | large_csv_io | short-medium, I/O-bound | CPU | large, on-disk | file I/O | placeholder |
| 06 | multi_step_tracking | short | CPU | small, in-memory | tracker API (start/stop x3) | built |
| 07 | gpu_neural_net | medium-long | GPU | small-medium, in-memory | ML training | placeholder |

## Rationale

**01 random_forest_classification** is the direct analog of CodeCarbon's
own scikit-learn documentation example (`RandomForestClassifier` on
`make_classification` data). It's the primary accuracy calibration case:
same algorithm, same data shape, same hyperparameters on both sides, so any
divergence in reported numbers is attributable to CodeCarbonR's wrapper
rather than to the workload differing.

**02 dplyr_wrangling** and **03 linear_model** cover the R analysis types
CodeCarbon has no examples for, since its own example set is ML-focused.
Paired against pandas and statsmodels/sklearn respectively.

**04 monte_carlo_simulation** is the long-running case, a loop-heavy
stochastic simulation (thousands of iterations) with negligible memory
footprint, to distinguish CPU-time-driven emissions from anything
data-size-driven.

**05 large_csv_io** is the large-file case: generate, write, read back, and
aggregate a large CSV (target ~1 GB) to exercise disk I/O and rule out
platform-specific file path or I/O handling bugs.

**06 multi_step_tracking** exercises `carbon_tracker()$start()/$stop()`
directly across three phases in one script, mirroring the "Multiple
Trackers" pattern from CodeCarbon's own docs. `with_emissions_tracked()`
only covers the single-block path; none of the other cases touch the
multi-step API.

**07 gpu_neural_net** is the GPU case, run on a cloud GPU instance rather
than local hardware. Needs a decision on framework (R `torch` package vs.
Python PyTorch, or R `keras3` vs. Python TensorFlow/Keras) before it can be
built out.

## Gaps not yet covered

- Apple Silicon / Mac execution entirely (deferred to a later version per
  current scope).
- A high-memory, low-CPU case (e.g. large in-memory matrix operations
  without heavy disk I/O) is not represented; 05 covers disk I/O but not
  memory pressure specifically. Worth adding if memory-driven RAM power
  tracking needs its own validation.
- Nothing exercises `setup_carbon_tracker()` itself (the conda environment
  bootstrap) as part of the comparison suite. That's more of an
  installation test than a per-workload one, but should have its own
  coverage somewhere (e.g. a Windows/Linux CI step that runs setup on a
  clean environment).
