skip_if_no_codecarbon <- function() {
  if (!carbon_tracker_ready()) {
    skip("codecarbon is not installed")
  }
}
