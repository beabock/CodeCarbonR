#!/usr/bin/env Rscript
# Render one or more comparison/ test cases and print an R-vs-Python summary.
#
# Usage (run from the repo root):
#   Rscript hpc/monsoon/render_cases.R                          # all CPU cases
#   Rscript hpc/monsoon/render_cases.R 07_gpu_neural_net         # just the GPU case
#   Rscript hpc/monsoon/render_cases.R 01_random_forest_classification 03_linear_model
#
# Each case renders in its own fresh Rscript subprocess (not in-process),
# with a timeout and a few retries. This is deliberate, not just caution:
# a suspected reticulate cross-thread race (an R/Python interrupt-
# notification deadlock, not a ranger/BLAS/RcppParallel thread-count issue
# -- see hpc/monsoon/README.md's Notes) has been observed to hang a render
# indefinitely, worse under heavy node CPU contention. An R-level timeout
# (setTimeLimit()/withTimeout()) wouldn't recover from this, since the hang
# is in native code that never reaches an R interrupt check -- only
# killing the OS process from outside actually works. A fresh subprocess
# per case also sidesteps the earlier redundant-use_condaenv()-call issue
# for free, since every case now genuinely gets its own fresh R/Python
# session (which used to be this script's -- incorrect -- assumption).

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

PER_CASE_TIMEOUT_SECS <- 300
MAX_ATTEMPTS <- 3

# Renders one case's test.Rmd in a brand-new Rscript process, with a hard
# timeout. Returns a list(ok, status, output); output is the subprocess's
# captured stdout+stderr, printed by the caller only on failure so a
# successful run's log stays uncluttered.
render_case_once <- function(rmd_path) {
  # A temp script file, rather than passing R code via -e directly, sidesteps
  # a Windows-specific system2() bug where embedded double-quotes in a -e
  # argument get mangled by Windows' CreateProcess-style command-line
  # reconstruction (POSIX systems pass argv directly with no shell involved,
  # so this wouldn't necessarily hit on Linux/Ceres either way, but a plain
  # file path argument has no quoting concerns to get wrong on any platform).
  script_file <- tempfile(fileext = ".R")
  on.exit(unlink(script_file), add = TRUE)
  writeLines(sprintf("rmarkdown::render(%s, quiet = TRUE)", deparse(rmd_path)), script_file)
  output <- tryCatch(
    system2("Rscript", shQuote(script_file),
            timeout = PER_CASE_TIMEOUT_SECS, stdout = TRUE, stderr = TRUE),
    error = function(e) structure(conditionMessage(e), status = 1L)
  )
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  list(ok = identical(status, 0L), status = status, output = output)
}

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

  rmd_path <- file.path(dir, "test.Rmd")
  ok <- FALSE
  for (attempt in seq_len(MAX_ATTEMPTS)) {
    t0 <- Sys.time()
    res <- render_case_once(rmd_path)
    elapsed <- round(as.numeric(Sys.time() - t0, units = "secs"), 1)

    if (res$ok) {
      cat("  render succeeded in", elapsed, "s (attempt", attempt, "of", MAX_ATTEMPTS, ")\n")
      ok <- TRUE
      break
    }

    timed_out <- identical(res$status, 124L)
    cat("  render", if (timed_out) "TIMED OUT" else "FAILED",
        "after", elapsed, "s (attempt", attempt, "of", MAX_ATTEMPTS, ")\n")
    cat("  --- subprocess output (last 20 lines) ---\n")
    cat(paste0("  ", utils::tail(res$output, 20)), sep = "\n")
    cat("  ------------------------------------------\n")

    if (attempt < MAX_ATTEMPTS) {
      unlink(file.path(dir, "r_output"), recursive = TRUE)
      unlink(file.path(dir, "py_output"), recursive = TRUE)
      Sys.sleep(5)
    }
  }

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
