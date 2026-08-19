#' Activate the r-codecarbon conda environment, robustly
#'
#' Plain `reticulate::use_condaenv("r-codecarbon", required = TRUE)` asks
#' reticulate to *discover* the environment by searching for a "conda"
#' binary on PATH -- but `conda activate` (from conda.sh) defines `conda`
#' as a shell function, not a PATH executable, so `Sys.which("conda")`
#' finds nothing, and reticulate's hardcoded guesses (`~/miniconda3`,
#' `~/anaconda3`, ...) miss any custom install path (e.g. an HPC install
#' under a project's scratch storage rather than $HOME). `CONDA_EXE` is a
#' real env var that conda.sh exports on source, independent of PATH or
#' install location, so use it directly when available.
#'
#' Also guards against calling `use_condaenv()` a second time in the same
#' R session. reticulate documents that once Python has been initialized
#' (e.g. by a prior call to this same function), its configuration can no
#' longer be changed -- so a repeat call is a no-op by design. Observed on
#' Ceres (USDA SCINet): that redundant call doesn't fail, it just sometimes
#' takes far longer than it should (seconds to tens of minutes, apparently
#' due to a slower internal validation path, worse under heavy node load)
#' rather than returning immediately -- enough to blow through an sbatch
#' job's walltime. This matters because `render_cases.R` loops over
#' multiple cases in one R session (`rmarkdown::render()` runs each Rmd's
#' chunks in the *same* process, not a fresh one), and every case's Rmd
#' independently calls this function in its own setup chunk.
use_r_codecarbon <- function() {
  if (reticulate::py_available(initialize = FALSE)) {
    return(invisible(TRUE))
  }
  conda_exe <- Sys.getenv("CONDA_EXE", unset = NA)
  if (!is.na(conda_exe) && nzchar(conda_exe)) {
    reticulate::use_condaenv("r-codecarbon", conda = conda_exe, required = TRUE)
  } else {
    reticulate::use_condaenv("r-codecarbon", required = TRUE)
  }
}
