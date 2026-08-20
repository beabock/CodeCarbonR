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
#'
#' Also supports a plain-venv Python (no conda at all), for clusters where
#' `conda create`/`mamba create` itself is broken -- observed on Monsoon
#' (NAU HPC): `/dev/shm` isn't mounted on login or compute nodes, which
#' hangs any tool using Python's `multiprocessing` module for its
#' shared-memory synchronization primitives (confirmed identically with
#' both `conda create` and `mamba create`, both hanging at the
#' package-linking step with an idle `multiprocessing.resource_tracker`
#' child process). Plain `pip`/`venv` don't hit this, so
#' `hpc/monsoon/01_setup_native.sh` uses a module-provided R/Python plus
#' `python -m venv` instead. If `CODECARBONR_VENV_PYTHON` is set (to that
#' venv's python binary), it takes priority over any conda env -- reticulate
#' can point directly at a venv's interpreter via `use_python()`, no conda
#' involved at all.
use_r_codecarbon <- function() {
  if (reticulate::py_available(initialize = FALSE)) {
    return(invisible(TRUE))
  }
  venv_python <- Sys.getenv("CODECARBONR_VENV_PYTHON", unset = NA)
  if (!is.na(venv_python) && nzchar(venv_python)) {
    reticulate::use_python(venv_python, required = TRUE)
    return(invisible(TRUE))
  }
  conda_exe <- Sys.getenv("CONDA_EXE", unset = NA)
  if (!is.na(conda_exe) && nzchar(conda_exe)) {
    reticulate::use_condaenv("r-codecarbon", conda = conda_exe, required = TRUE)
  } else {
    reticulate::use_condaenv("r-codecarbon", required = TRUE)
  }
}
