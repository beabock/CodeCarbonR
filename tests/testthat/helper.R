skip_if_no_codecarbon <- function() {
  # Explicit skip_on_cran() alongside the readiness check: CRAN's check
  # machines won't have codecarbon importable either way, so this should
  # already skip there, but making the intent explicit doesn't depend on
  # that assumption continuing to hold. See RELEASING.md.
  skip_on_cran()
  if (!carbon_tracker_ready()) {
    skip("codecarbon is not installed")
  }
}
