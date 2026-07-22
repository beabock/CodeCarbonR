test_that("list_carbon_tracker_countries returns known codes", {
  skip_if_no_codecarbon()
  countries <- list_carbon_tracker_countries()
  expect_true("USA" %in% countries$iso_code)
  expect_true(all(c("iso_code", "country_name") %in% names(countries)))
})
