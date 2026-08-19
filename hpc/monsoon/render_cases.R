#!/usr/bin/env Rscript
# Render one or more comparison/ test cases and print an R-vs-Python summary.
#
# Usage (run from the repo root):
#   Rscript hpc/monsoon/render_cases.R                          # all CPU cases
#   Rscript hpc/monsoon/render_cases.R 07_gpu_neural_net         # just the GPU case
#   Rscript hpc/monsoon/render_cases.R 01_random_forest_classification 03_linear_model

args <- commandArgs(trailingOnly = TRUE)

default_cases <- c(
  "01_random_forest_classification",
  "02_dplyr_wrangling",
  "03_linear_model",
  "04_monte_carlo_simulation",
  "05_large_csv_io",
  "06_multi_step_tracking"
)

cases <- if (length(args) > 0) args else default_cases

# Same CONDA_EXE-aware lookup every test.Rmd's setup chunk uses -- each
# case renders in its own fresh R session, so this needs to be redone per
# session; see comparison/_harness/use_r_codecarbon.R for why plain
# use_condaenv() isn't reliable here.
source("comparison/_harness/use_r_codecarbon.R")
use_r_codecarbon()

summary_rows <- list()

for (case in cases) {
  dir <- file.path("comparison", case)
  if (!dir.exists(dir)) {
    warning("skipping unknown case: ", case)
    next
  }

  cat("\n=== Rendering", case, "===\n")
  unlink(file.path(dir, "r_output"), recursive = TRUE)
  unlink(file.path(dir, "py_output"), recursive = TRUE)
  unlink(file.path(dir, "shared_data.csv"))
  unlink(file.path(dir, "test.html"))
  unlink(file.path(dir, "test_files"), recursive = TRUE)

  t0 <- Sys.time()
  ok <- tryCatch(
    {
      rmarkdown::render(file.path(dir, "test.Rmd"), quiet = TRUE)
      TRUE
    },
    error = function(e) {
      cat("  RENDER FAILED:", conditionMessage(e), "\n")
      FALSE
    }
  )
  elapsed <- round(as.numeric(Sys.time() - t0, units = "secs"), 1)
  cat("  render", if (ok) "succeeded" else "failed", "in", elapsed, "s\n")

  if (!ok) {
    summary_rows[[case]] <- data.frame(case = case, phase = NA, status = "RENDER FAILED")
    next
  }

  r_csv <- file.path(dir, "r_output", "emissions.csv")
  py_csv <- file.path(dir, "py_output", "emissions.csv")
  if (!file.exists(r_csv) || !file.exists(py_csv)) {
    summary_rows[[case]] <- data.frame(case = case, phase = NA, status = "MISSING OUTPUT")
    next
  }

  r_data <- utils::read.csv(r_csv, stringsAsFactors = FALSE)
  py_data <- utils::read.csv(py_csv, stringsAsFactors = FALSE)
  n <- min(nrow(r_data), nrow(py_data))

  for (i in seq_len(n)) {
    summary_rows[[paste(case, i)]] <- data.frame(
      case = case,
      phase = i,
      r_duration = r_data$duration[i],
      py_duration = py_data$duration[i],
      r_emissions = r_data$emissions[i],
      py_emissions = py_data$emissions[i],
      r_cpu_power = r_data$cpu_power[i],
      py_cpu_power = py_data$cpu_power[i],
      status = "OK"
    )
  }

  unlink(file.path(dir, "test.html"))
  unlink(file.path(dir, "test_files"), recursive = TRUE)
}

result <- do.call(rbind, summary_rows)
cat("\n\n==================== SUMMARY ====================\n")
print(result, row.names = FALSE)

dir.create("hpc/monsoon/logs", showWarnings = FALSE, recursive = TRUE)
out_path <- file.path("hpc", "monsoon", "logs", paste0("results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"))
utils::write.csv(result, out_path, row.names = FALSE)
cat("\nSaved to", out_path, "\n")

cat("\nr_cpu_power / py_cpu_power is the tell for whether this node gave real\n")
cat("hardware measurement: a single constant value (e.g. 42.5) repeated for\n")
cat("every row means codecarbon fell back to the CPU-load x TDP estimate,\n")
cat("same limitation as the Windows dev machine this suite was originally\n")
cat("validated on. Varying values mean RAPL was actually readable here.\n")
