test_that("carbon_tracker_ready returns a single logical", {
  ready <- carbon_tracker_ready()
  expect_type(ready, "logical")
  expect_length(ready, 1)
})

test_that("setup_carbon_tracker refuses to run non-interactively", {
  expect_error(setup_carbon_tracker(force = TRUE), "interactively")
})
