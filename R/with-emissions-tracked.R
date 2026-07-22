#' Track emissions for a single block of code
#'
#' @param expr Code to run and measure.
#' @param country_iso_code 3-letter ISO code used to look up grid carbon
#'   intensity, e.g. `"USA"`. Call [list_carbon_tracker_countries()] for the
#'   supported codes.
#' @param ... Passed to [carbon_tracker()].
#' @return A `carbon_emissions_result`: `$result` holds the value of `expr`,
#'   `$emissions` holds the `carbon_emissions` object.
#' @export
with_emissions_tracked <- function(expr, country_iso_code = NULL, ...) {
  tracker <- carbon_tracker(country_iso_code = country_iso_code, ...)
  tracker$start()
  on.exit(tracker$stop())
  result <- expr
  on.exit()
  new_carbon_emissions_result(result, tracker$stop())
}

new_carbon_emissions_result <- function(result, emissions) {
  structure(list(result = result, emissions = emissions), class = "carbon_emissions_result")
}

#' @export
print.carbon_emissions_result <- function(x, ...) {
  print(x$emissions)
  invisible(x)
}
