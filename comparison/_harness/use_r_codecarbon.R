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
use_r_codecarbon <- function() {
  conda_exe <- Sys.getenv("CONDA_EXE", unset = NA)
  if (!is.na(conda_exe) && nzchar(conda_exe)) {
    reticulate::use_condaenv("r-codecarbon", conda = conda_exe, required = TRUE)
  } else {
    reticulate::use_condaenv("r-codecarbon", required = TRUE)
  }
}
