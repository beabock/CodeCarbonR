test_that("carbon_emissions has a working print method", {
  fake <- structure(
    list(
      emissions = 1e-6, energy_consumed = 2e-5, duration = 5.3,
      cpu_tracking = "estimated (CPU load x TDP)"
    ),
    class = "carbon_emissions"
  )
  expect_output(print(fake), "Carbon emissions")
  expect_output(print(fake), "CPU tracking")
})

test_that("as.data.frame.carbon_emissions returns one row", {
  fake <- structure(
    list(
      emissions = 1e-6, energy_consumed = 2e-5, duration = 5.3,
      region = NA, cpu_tracking = "estimated (CPU load x TDP)"
    ),
    class = "carbon_emissions"
  )
  df <- as.data.frame(fake)
  expect_equal(nrow(df), 1)
  expect_equal(df$duration, 5.3)
})

test_that("emissions_data_to_list rejects non-Python input", {
  expect_error(emissions_data_to_list(list(a = 1)), "must be a Python object")
})

test_that("a live tracker produces a well-formed carbon_emissions object", {
  skip_if_no_codecarbon()
  tracker <- carbon_tracker(
    country_iso_code = "USA", measure_power_secs = 1, log_level = "error",
    output_dir = tempdir()
  )
  tracker$start()
  Sys.sleep(2)
  emissions <- tracker$stop()

  expect_s3_class(emissions, "carbon_emissions")
  expect_true(emissions$duration > 0)
  expect_true(emissions$emissions >= 0)
  expect_true(emissions$energy_consumed >= 0)
  expect_type(emissions$cpu_tracking, "character")
  expect_true(nzchar(emissions$cpu_tracking))
})
