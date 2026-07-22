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
