#' Compare R and Python emissions output for one test case
#'
#' Reads `r_output/emissions.csv` and `py_output/emissions.csv` from
#' `case_dir`, compares the last row of each (the most recent run) on
#' duration, emissions, and energy_consumed, and prints the percent
#' difference for each metric.
#'
#' @param case_dir Path to a test case directory containing r_output/ and
#'   py_output/ subdirectories.
#' @param tolerance Fraction difference above which a metric is flagged.
#' @return Invisibly, a data frame with one row per compared metric.
compare_emissions <- function(case_dir, tolerance = 0.20) {
  r_csv <- file.path(case_dir, "r_output", "emissions.csv")
  py_csv <- file.path(case_dir, "py_output", "emissions.csv")

  if (!file.exists(r_csv)) stop("missing R output: ", r_csv, call. = FALSE)
  if (!file.exists(py_csv)) stop("missing Python output: ", py_csv, call. = FALSE)

  r_row <- utils.tail_row(r_csv)
  py_row <- utils.tail_row(py_csv)

  metrics <- c("duration", "emissions", "energy_consumed")
  missing <- setdiff(metrics, intersect(names(r_row), names(py_row)))
  if (length(missing) > 0) {
    stop("columns missing from one of the CSVs: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  r_vals <- as.numeric(r_row[metrics])
  py_vals <- as.numeric(py_row[metrics])
  pct_diff <- pct_diff_safe(r_vals, py_vals)
  flagged <- !is.na(pct_diff) & pct_diff > tolerance

  result <- data.frame(
    metric = metrics,
    r_value = r_vals,
    py_value = py_vals,
    pct_diff = pct_diff,
    flagged = flagged
  )

  print(result, row.names = FALSE)
  if (any(flagged)) {
    cat("\nflagged metrics exceed", scales_pct(tolerance), "tolerance:",
        paste(metrics[flagged], collapse = ", "), "\n")
  }
  if (any(is.na(pct_diff))) {
    cat("\npct_diff undefined (python value was 0) for:",
        paste(metrics[is.na(pct_diff)], collapse = ", "), "\n")
  }

  invisible(result)
}

#' Compare R and Python emissions output across multiple phases
#'
#' Like [compare_emissions()], but compares every row of `emissions.csv`
#' instead of just the last one. Use this for test cases that call
#' `start()`/`stop()` more than once, where each phase appends its own row
#' on both the R and Python side.
#'
#' @param case_dir Path to a test case directory containing r_output/ and
#'   py_output/ subdirectories.
#' @param phase_labels Optional character vector naming each phase, in the
#'   order the start/stop calls were made. Defaults to phase_1, phase_2, ...
#' @param tolerance Fraction difference above which a metric is flagged.
#' @return Invisibly, a data frame with one row per phase per metric.
compare_emissions_multi <- function(case_dir, phase_labels = NULL, tolerance = 0.20) {
  r_csv <- file.path(case_dir, "r_output", "emissions.csv")
  py_csv <- file.path(case_dir, "py_output", "emissions.csv")

  if (!file.exists(r_csv)) stop("missing R output: ", r_csv, call. = FALSE)
  if (!file.exists(py_csv)) stop("missing Python output: ", py_csv, call. = FALSE)

  r_data <- utils::read.csv(r_csv, stringsAsFactors = FALSE)
  py_data <- utils::read.csv(py_csv, stringsAsFactors = FALSE)

  n_phases <- min(nrow(r_data), nrow(py_data))
  if (nrow(r_data) != nrow(py_data)) {
    warning(
      "R produced ", nrow(r_data), " rows, Python produced ", nrow(py_data),
      " rows. Comparing the first ", n_phases, " only.",
      call. = FALSE
    )
  }

  if (is.null(phase_labels)) {
    phase_labels <- paste0("phase_", seq_len(n_phases))
  } else if (length(phase_labels) != n_phases) {
    stop("phase_labels must have length ", n_phases, call. = FALSE)
  }

  metrics <- c("duration", "emissions", "energy_consumed")
  missing <- setdiff(metrics, intersect(names(r_data), names(py_data)))
  if (length(missing) > 0) {
    stop("columns missing from one of the CSVs: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  result <- do.call(rbind, lapply(seq_len(n_phases), function(i) {
    r_vals <- as.numeric(r_data[i, metrics])
    py_vals <- as.numeric(py_data[i, metrics])
    pct_diff <- pct_diff_safe(r_vals, py_vals)
    data.frame(
      phase = phase_labels[i],
      metric = metrics,
      r_value = r_vals,
      py_value = py_vals,
      pct_diff = pct_diff,
      flagged = !is.na(pct_diff) & pct_diff > tolerance
    )
  }))

  print(result, row.names = FALSE)
  if (any(result$flagged)) {
    cat("\nflagged metrics exceed", scales_pct(tolerance), "tolerance:\n")
    print(result[result$flagged, c("phase", "metric")], row.names = FALSE)
  }
  if (any(is.na(result$pct_diff))) {
    cat("\npct_diff undefined (python value was 0) for:\n")
    print(result[is.na(result$pct_diff), c("phase", "metric")], row.names = FALSE)
  }

  invisible(result)
}

utils.tail_row <- function(csv_path) {
  data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  if (nrow(data) == 0) stop("empty CSV: ", csv_path, call. = FALSE)
  data[nrow(data), ]
}

# Percent difference of r vs. py, elementwise. NA where py is 0 (percent
# difference is undefined, not infinite) rather than Inf/NaN.
pct_diff_safe <- function(r_vals, py_vals) {
  ifelse(py_vals == 0, NA_real_, abs(r_vals - py_vals) / py_vals)
}

scales_pct <- function(x) paste0(round(x * 100), "%")
