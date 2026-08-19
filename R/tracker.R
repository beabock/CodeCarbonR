#' @importFrom R6 R6Class
CarbonTracker <- R6::R6Class(
  "CarbonTracker",
  public = list(
    emissions = NULL,

    initialize = function(country_iso_code = NULL, project_name = "CodeCarbonR", ...) {
      ensure_codecarbon_available()
      validate_country_iso_code(country_iso_code)
      extra_args <- list(...)
      if (!is.null(extra_args$output_dir) && !dir.exists(extra_args$output_dir)) {
        dir.create(extra_args$output_dir, recursive = TRUE)
      }
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
#' Each tracker instance supports one `$start()`/`$stop()` cycle. Calling
#' `$start()` again after `$stop()` on the same instance does not restart
#' measurement, because codecarbon's underlying tracker never resets its
#' internal clock -- but exactly what the next `$stop()` returns depends on
#' the installed codecarbon version: codecarbon 2.x returns the first
#' cycle's emissions/energy figures again, frozen; codecarbon 3.x instead
#' keeps accumulating energy from the original start, so the second
#' reading comes back inflated rather than frozen. Either way it is not an
#' isolated measurement of the second cycle's own work, and `duration`
#' keeps climbing from the original start rather than resetting. To
#' measure several phases separately, create a new `carbon_tracker()` per
#' phase; each `$stop()` still appends its own row to the same
#' `output_dir`'s `emissions.csv`.
#'
#' @param country_iso_code 3-letter ISO code used to look up grid carbon
#'   intensity, e.g. `"USA"`. Call [list_carbon_tracker_countries()] for the
#'   supported codes.
#' @param project_name Label attached to the tracked run.
#' @param ... Passed to `codecarbon.OfflineEmissionsTracker`, e.g.
#'   `measure_power_secs`, `output_dir`, `log_level`.
#' @return A `CarbonTracker` R6 object.
#' @examples
#' \donttest{
#' # Requires codecarbon to be installed (setup_carbon_tracker()); not run
#' # on CRAN's check machines, which don't have it.
#' if (carbon_tracker_ready()) {
#'   tracker <- carbon_tracker(country_iso_code = "USA", output_dir = tempdir())
#'   tracker$start()
#'   Sys.sleep(1)
#'   emissions <- tracker$stop()
#'   print(emissions)
#' }
#' }
#' @export
carbon_tracker <- function(country_iso_code = NULL, project_name = "CodeCarbonR", ...) {
  CarbonTracker$new(country_iso_code = country_iso_code, project_name = project_name, ...)
}
