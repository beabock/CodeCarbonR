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
    log_level = "error",
    output_dir = tempdir()
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
  # doesn't begin measuring fresh -- confirmed by inspecting `_start_time`
  # directly across both codecarbon 2.2.2 and 3.3.0, it's identical before
  # and after the second start(). What that produces downstream is
  # version-dependent, though: codecarbon 2.2.2 returned the *first*
  # cycle's emissions/energy figures again, frozen (second == first, only
  # duration climbed). codecarbon 3.3.0 instead accumulates energy since
  # the original start rather than resetting it, so the second reading
  # comes back *inflated* (observed ~2.2x the first for two ~1s cycles,
  # not frozen). Both are still not a clean, isolated measurement of just
  # the second cycle's own work -- that's the invariant this test pins,
  # deliberately as an inequality rather than the exact numeric
  # relationship, so it survives codecarbon changing *how* it's broken
  # (see CI failure on codecarbon 3.3.0, 2026-08, for why the original
  # exact-equality version of this test wasn't robust to that). If this
  # ever fails outright -- second < first, or duration stops climbing --
  # that's the meaningful signal: codecarbon may have actually fixed
  # instance reuse, and carbon_tracker()'s docs (R/tracker.R) and the
  # multi-step test case (comparison/06_multi_step_tracking) should be
  # revisited.
  tracker <- carbon_tracker(
    country_iso_code = "USA", measure_power_secs = 1, log_level = "error",
    output_dir = tempdir()
  )

  tracker$start()
  Sys.sleep(1)
  first <- tracker$stop()

  tracker$start()
  Sys.sleep(1)
  second <- tracker$stop()

  expect_true(second$emissions >= first$emissions)
  expect_true(second$energy_consumed >= first$energy_consumed)
  expect_true(second$duration > first$duration)
})

test_that("one tracker per phase does isolate per-cycle emissions", {
  skip_if_no_codecarbon()
  tracker1 <- carbon_tracker(
    country_iso_code = "USA", measure_power_secs = 1, log_level = "error",
    output_dir = tempdir()
  )
  tracker1$start()
  Sys.sleep(1)
  first <- tracker1$stop()

  tracker2 <- carbon_tracker(
    country_iso_code = "USA", measure_power_secs = 1, log_level = "error",
    output_dir = tempdir()
  )
  tracker2$start()
  Sys.sleep(1)
  second <- tracker2$stop()

  expect_false(isTRUE(all.equal(second$emissions, first$emissions)))
})
