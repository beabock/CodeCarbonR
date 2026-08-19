#' List supported country codes for carbon intensity lookup
#'
#' Reads the country energy mix data bundled with the installed codecarbon
#' package. The `country_iso_code` argument to [carbon_tracker()] and
#' [with_emissions_tracked()] must be one of the codes returned here.
#'
#' @return A data frame with `iso_code` and `country_name` columns.
#' @examples
#' \donttest{
#' # Requires codecarbon to be installed (setup_carbon_tracker()); not run
#' # on CRAN's check machines, which don't have it.
#' if (carbon_tracker_ready()) {
#'   countries <- list_carbon_tracker_countries()
#'   head(countries)
#' }
#' }
#' @export
list_carbon_tracker_countries <- function() {
  ensure_codecarbon_available()
  data_source <- reticulate::import("codecarbon.input")$DataSource()
  energy_mix <- reticulate::py_to_r(data_source$get_global_energy_mix_data())
  data.frame(
    iso_code = names(energy_mix),
    country_name = vapply(energy_mix, function(x) x$country_name, character(1)),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

# codecarbon silently falls back to a world-average carbon intensity when
# country_iso_code is missing or unrecognized, rather than raising an error,
# which would give a beginner a plausible-looking but meaningless number with
# no indication anything was off. Catching it here means it fails loudly in R
# before a Python call is ever made.
validate_country_iso_code <- function(country_iso_code) {
  if (is.null(country_iso_code)) {
    stop(
      "country_iso_code is required. Carbon intensity varies enormously by ",
      "country, and codecarbon silently falls back to a world average if ",
      "it's left unset. Call list_carbon_tracker_countries() for the ",
      "supported 3-letter ISO codes.",
      call. = FALSE
    )
  }
  valid_codes <- list_carbon_tracker_countries()$iso_code
  if (!country_iso_code %in% valid_codes) {
    stop(
      "\"", country_iso_code, "\" is not a supported country code. Call ",
      "list_carbon_tracker_countries() for the supported 3-letter ISO codes.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}
