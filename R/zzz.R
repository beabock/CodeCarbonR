.onLoad <- function(libname, pkgname) {
  # Plain use_condaenv() asks reticulate to *discover* r-codecarbon by
  # searching for a "conda" binary on PATH -- but `conda activate` (from
  # conda.sh) defines `conda` as a shell function, not a PATH executable,
  # so Sys.which("conda") finds nothing, and reticulate's hardcoded
  # guesses (~/miniconda3, ~/anaconda3, ...) miss any custom install
  # path. CONDA_EXE is a real env var conda.sh exports on source,
  # independent of PATH or install location, so prefer it when set --
  # otherwise a user who has activated their r-codecarbon-containing
  # conda install this way would see carbon_tracker_ready() silently
  # report FALSE despite everything being correctly installed.
  conda_exe <- Sys.getenv("CONDA_EXE", unset = NA)
  if (!is.na(conda_exe) && nzchar(conda_exe)) {
    reticulate::use_condaenv("r-codecarbon", conda = conda_exe, required = FALSE)
  } else {
    reticulate::use_condaenv("r-codecarbon", required = FALSE)
  }
}
