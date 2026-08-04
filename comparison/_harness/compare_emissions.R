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
  pct_diff <- abs(r_vals - py_vals) / py_vals
  flagged <- pct_diff > tolerance

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

  invisible(result)
}

utils.tail_row <- function(csv_path) {
  data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  if (nrow(data) == 0) stop("empty CSV: ", csv_path, call. = FALSE)
  data[nrow(data), ]
}

scales_pct <- function(x) paste0(round(x * 100), "%")
