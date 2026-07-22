new_carbon_emissions <- function(py_tracker) {
  data <- emissions_data_to_list(py_tracker$final_emissions_data)
  data$cpu_tracking <- describe_cpu_tracking(py_tracker)
  structure(data, class = "carbon_emissions")
}

emissions_data_to_list <- function(emissions_data) {
  if (!inherits(emissions_data, "python.builtin.object")) {
    stop("emissions_data must be a Python object, not ", class(emissions_data)[1], ".", call. = FALSE)
  }
  values <- reticulate::py_to_r(emissions_data$values)
  lapply(values, function(x) if (is.null(x)) NA else x)
}

# codecarbon doesn't expose which CPU backend was used (rapl, power gadget,
# or the cpu_load estimate) anywhere in its output schema. description() is
# the closest public signal, but it's a human-readable repr(), not a stable
# enum, so this string match is isolated here in case codecarbon reworks it.
describe_cpu_tracking <- function(py_tracker) {
  cpu <- find_hardware(py_tracker, "CPU")
  if (is.null(cpu)) {
    return("not tracked")
  }
  description <- cpu$description()
  if (grepl("Cpu Load", description, fixed = TRUE)) {
    return("estimated (CPU load x TDP)")
  }
  paste("measured -", description)
}

find_hardware <- function(py_tracker, class_suffix) {
  for (item in py_tracker$"_hardware") {
    if (grepl(paste0("\\.", class_suffix, "$"), class(item)[1])) {
      return(item)
    }
  }
  NULL
}

#' @export
print.carbon_emissions <- function(x, ...) {
  cat("Carbon emissions:", format(x$emissions, scientific = TRUE), "kg CO2e\n")
  cat("Energy consumed: ", format(x$energy_consumed, scientific = TRUE), "kWh\n")
  cat("Duration:        ", round(x$duration, 1), "s\n")
  cat("CPU tracking:    ", x$cpu_tracking, "\n")
  invisible(x)
}

#' @export
as.data.frame.carbon_emissions <- function(x, ...) {
  as.data.frame(unclass(x), stringsAsFactors = FALSE)
}
