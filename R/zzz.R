.onLoad <- function(libname, pkgname) {
  reticulate::use_condaenv("r-codecarbon", required = FALSE)
}
