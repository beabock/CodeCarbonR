#' @importFrom R6 R6Class
CarbonTracker <- R6::R6Class(
  "CarbonTracker",
  public = list(
    emissions = NULL,

    initialize = function(country_iso_code = NULL, project_name = "CodeCarbonR", ...) {
      ensure_codecarbon_available()
      validate_country_iso_code(country_iso_code)
      codecarbon <- reticulate::import("codecarbon")
      private$py_tracker <- codecarbon$OfflineEmissionsTracker(
        project_name = project_name,
        country_iso_code = country_iso_code,
        ...
      )
    },

    start = function() {
      private$py_tracker$start()
      invisible(self)
    },

    stop = function() {
      private$py_tracker$stop()
      self$emissions <- new_carbon_emissions(private$py_tracker)
      invisible(self$emissions)
    },

    flush = function() {
      private$py_tracker$flush()
      new_carbon_emissions(private$py_tracker)
    }
  ),
  private = list(
    py_tracker = NULL
  )
)

#' Create a carbon emissions tracker
#'
#' Wraps a codecarbon `OfflineEmissionsTracker`. Call `$start()` before the
#' code you want to measure and `$stop()` after, or use
#' [with_emissions_tracked()] to measure a single block in one call.
#'
#' @param country_iso_code 3-letter ISO code used to look up grid carbon
#'   intensity, e.g. `"USA"`. Call [list_carbon_tracker_countries()] for the
#'   supported codes.
#' @param project_name Label attached to the tracked run.
#' @param ... Passed to `codecarbon.OfflineEmissionsTracker`, e.g.
#'   `measure_power_secs`, `output_dir`, `log_level`.
#' @return A `CarbonTracker` R6 object.
#' @export
carbon_tracker <- function(country_iso_code = NULL, project_name = "CodeCarbonR", ...) {
  CarbonTracker$new(country_iso_code = country_iso_code, project_name = project_name, ...)
}
