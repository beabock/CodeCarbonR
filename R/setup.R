#' Install codecarbon into a dedicated conda environment
#'
#' Installs Miniconda if it isn't already present, then creates the
#' "r-codecarbon" conda environment and installs codecarbon into it. Run this
#' once per machine before using [carbon_tracker()] or
#' [with_emissions_tracked()]. Nothing is installed without confirmation, and
#' the function refuses to run outside an interactive session.
#'
#' @param force Reinstall codecarbon even if it's already available.
#' @return Invisibly, `TRUE` if codecarbon is ready to use after the call,
#'   `FALSE` if setup was cancelled.
#' @export
setup_carbon_tracker <- function(force = FALSE) {
  if (!force && carbon_tracker_ready()) {
    message("codecarbon is already installed.")
    return(invisible(TRUE))
  }

  if (!interactive()) {
    stop(
      "setup_carbon_tracker() must be run interactively so you can confirm ",
      "the install. Call it from the R console.",
      call. = FALSE
    )
  }

  miniconda_needed <- !dir.exists(reticulate::miniconda_path())
  message(
    "This will set up a Python environment for CodeCarbonR:\n",
    if (miniconda_needed) {
      sprintf("  - install Miniconda to %s\n", reticulate::miniconda_path())
    },
    "  - create a conda environment named \"r-codecarbon\"\n",
    "  - install the codecarbon Python package into it"
  )

  if (utils::menu(c("Yes", "No"), title = "Proceed?") != 1) {
    message("Setup cancelled.")
    return(invisible(FALSE))
  }

  if (miniconda_needed) {
    reticulate::install_miniconda()
  }
  reticulate::py_install("codecarbon", envname = "r-codecarbon", method = "conda")

  if (!carbon_tracker_ready()) {
    stop("codecarbon did not install correctly. Run setup_carbon_tracker() again.", call. = FALSE)
  }

  message("codecarbon is installed and ready to use.")
  invisible(TRUE)
}

#' Check whether codecarbon is installed and importable
#'
#' @return `TRUE` if codecarbon can be imported, `FALSE` otherwise (including
#'   when no Python interpreter can be found at all).
#' @export
carbon_tracker_ready <- function() {
  tryCatch(reticulate::py_module_available("codecarbon"), error = function(e) FALSE)
}

ensure_codecarbon_available <- function() {
  if (carbon_tracker_ready()) {
    return(invisible(TRUE))
  }
  stop("codecarbon is not installed. Run setup_carbon_tracker() once to install it.", call. = FALSE)
}
