test_that("carbon_tracker_ready returns a single logical", {
  # Not skip_if_no_codecarbon() -- this test is meant to pass either way,
  # verifying graceful behavior whether or not codecarbon is installed.
  # skip_on_cran() alone: carbon_tracker_ready() forces reticulate's
  # interpreter-discovery machinery to run, which can spin up background
  # threads during that search. Confirmed via CRAN's incoming pretest
  # (2026-08-21): flagged a "CPU time 3.4x elapsed time" NOTE on Debian,
  # specific to this test file, with no Python configured on that check
  # machine -- reticulate's own behavior during interpreter search, not
  # anything this test itself does. See cran-comments.md.
  skip_on_cran()
  ready <- carbon_tracker_ready()
  expect_type(ready, "logical")
  expect_length(ready, 1)
})

test_that("setup_carbon_tracker refuses to run non-interactively", {
  expect_error(setup_carbon_tracker(force = TRUE), "interactively")
})
