test_that("carbon_tracker requires country_iso_code", {
  skip_if_no_codecarbon()
  expect_error(carbon_tracker(), "country_iso_code is required")
})

test_that("carbon_tracker validates country_iso_code before touching python", {
  skip_if_no_codecarbon()
  expect_error(carbon_tracker(country_iso_code = "ZZZ"), "not a supported country code")
})

test_that("with_emissions_tracked returns both result and emissions", {
  skip_if_no_codecarbon()
  out <- with_emissions_tracked(
    {
      Sys.sleep(1)
      2 + 2
    },
    country_iso_code = "USA",
    measure_power_secs = 1,
    log_level = "error"
  )
  expect_s3_class(out, "carbon_emissions_result")
  expect_equal(out$result, 4)
  expect_s3_class(out$emissions, "carbon_emissions")
})

test_that("carbon_tracker creates output_dir when it doesn't already exist", {
  skip_if_no_codecarbon()
  dir <- file.path(tempdir(), paste0("codecarbonr-test-", as.integer(Sys.time())))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  expect_false(dir.exists(dir))

  tracker <- carbon_tracker(
    country_iso_code = "USA",
    measure_power_secs = 1,
    log_level = "error",
    output_dir = dir
  )
  tracker$start()
  Sys.sleep(1)
  emissions <- tracker$stop()

  expect_s3_class(emissions, "carbon_emissions")
  expect_true(dir.exists(dir))
  expect_true(file.exists(file.path(dir, "emissions.csv")))
})

test_that("carbon_tracker leaves an existing output_dir alone", {
  skip_if_no_codecarbon()
  dir <- file.path(tempdir(), paste0("codecarbonr-test-existing-", as.integer(Sys.time())))
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  marker <- file.path(dir, "marker.txt")
  writeLines("keep me", marker)

  tracker <- carbon_tracker(
    country_iso_code = "USA",
    measure_power_secs = 1,
    log_level = "error",
    output_dir = dir
  )
  tracker$start()
  Sys.sleep(1)
  tracker$stop()

  expect_true(file.exists(marker))
})

test_that("restarting one tracker instance does not isolate per-cycle emissions (codecarbon limitation, not a CodeCarbonR bug)", {
  skip_if_no_codecarbon()
  # codecarbon's OfflineEmissionsTracker never resets its internal
  # `_start_time` in stop(), so start() after stop() on the same instance
  # logs "Already started tracking" and no-ops, and the following stop()
  # returns the *first* cycle's emissions/energy figures again, frozen,
  # while duration keeps climbing from the original start. This test pins
  # that known behavior so a codecarbon upgrade that changes it doesn't go
  # unnoticed: if it starts failing, carbon_tracker()'s docs (R/tracker.R)
  # and the multi-step test case (comparison/06_multi_step_tracking) need
  # to be revisited.
  tracker <- carbon_tracker(country_iso_code = "USA", measure_power_secs = 1, log_level = "error")

  tracker$start()
  Sys.sleep(1)
  first <- tracker$stop()

  tracker$start()
  Sys.sleep(1)
  second <- tracker$stop()

  expect_equal(second$emissions, first$emissions)
  expect_equal(second$energy_consumed, first$energy_consumed)
  expect_true(second$duration > first$duration)
})

test_that("one tracker per phase does isolate per-cycle emissions", {
  skip_if_no_codecarbon()
  tracker1 <- carbon_tracker(country_iso_code = "USA", measure_power_secs = 1, log_level = "error")
  tracker1$start()
  Sys.sleep(1)
  first <- tracker1$stop()

  tracker2 <- carbon_tracker(country_iso_code = "USA", measure_power_secs = 1, log_level = "error")
  tracker2$start()
  Sys.sleep(1)
  second <- tracker2$stop()

  expect_false(isTRUE(all.equal(second$emissions, first$emissions)))
})
