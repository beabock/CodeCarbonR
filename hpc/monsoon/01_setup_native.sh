#!/usr/bin/env bash
# Alternative to 01_setup.sh, for clusters where `conda create`/`mamba
# create` itself is broken -- observed on Monsoon (NAU HPC): `/dev/shm`
# isn't mounted on login or compute nodes, which hangs any tool using
# Python's `multiprocessing` module for its shared-memory synchronization
# primitives. Confirmed identically with both `conda create` and `mamba
# create` (mambaforge 24.3.0's `mamba` still routes package *linking*
# through the same underlying conda Python code, so it doesn't sidestep
# this either) -- both hung indefinitely at the package-linking step, with
# an idle `multiprocessing.resource_tracker` child process as the tell.
# Neither pointing the package cache at the same filesystem as the target
# env (CONDA_PKGS_DIRS) nor using a different node (login vs. compute, both
# lack /dev/shm identically) fixed it. This isn't something a regular user
# can fix -- mounting/enabling /dev/shm needs root -- so this script avoids
# `conda create` entirely instead of working around it.
#
# Uses Monsoon's own pre-built `R` module directly (R package compilation
# via install.packages() goes through gcc/make, not Python multiprocessing,
# so it's unaffected) plus a plain `python -m venv` + `pip install` for the
# Python side (pip doesn't use conda's transaction-execution machinery
# either). Trade-off vs. 01_setup.sh: this relies on Monsoon providing an R
# module and a reasonably compatible Python module, rather than being
# fully self-contained -- check `module avail R` / `module avail python`
# first if adapting this for a different cluster.
#
# Run this on a LOGIN NODE (needs internet for downloads). Usage, from the
# repo root after cloning:
#   bash hpc/monsoon/01_setup_native.sh

set -euo pipefail

# python/3.14.3 (the standalone Python module) is too new for reticulate's
# CPython-internals-dependent R/Python cross-thread coordination as of
# reticulate 1.46.0 -- confirmed by direct comparison: with
# python/3.14.3, carbon_tracker()$start() hung deterministically (3/3
# tries) at the exact same point ("[setup] CPU Tracking...") on a
# completely idle node (load average 0.00, ruling out contention); with
# anaconda3/2025.06's bundled Python 3.13.13 instead, the identical code
# completed in under a second. anaconda3 is flagged deprecated in favor
# of miniforge3 in `module avail` output here, but its bundled Python
# works and hasn't been swapped for miniforge3's -- revisit if anaconda3
# is ever actually removed. Loading this module auto-activates its
# `base` conda env, but nothing here calls `conda create` (the actual
# broken thing, see below), so that's harmless -- CODECARBONR_VENV_PYTHON
# takes priority over any conda env in use_r_codecarbon() regardless.
R_MODULE="${CODECARBONR_R_MODULE:-R/4.5.3}"
PYTHON_MODULE="${CODECARBONR_PYTHON_MODULE:-anaconda3/2025.06}"
RLIBS_DIR="${CODECARBONR_RLIBS_DIR:-$HOME/R-codecarbonr-libs}"
VENV_DIR="${CODECARBONR_VENV_DIR:-$HOME/venv-codecarbonr}"

echo "=== Modules ==="
module load "$R_MODULE"
module load "$PYTHON_MODULE"
echo "R module:      $R_MODULE ($(command -v R))"
echo "Python module:  $PYTHON_MODULE ($(command -v python3))"

echo
echo "=== R packages -> $RLIBS_DIR ==="
mkdir -p "$RLIBS_DIR"
export R_LIBS_USER="$RLIBS_DIR"
# install.packages() failing for one package doesn't make Rscript exit
# non-zero -- it just warns and moves on -- so `set -euo pipefail` alone
# won't catch a partial failure here. Verify explicitly and stop() (which
# does exit non-zero) if anything's still missing after the install
# attempt. A package needing real memory to compile (RcppEigen
# especially -- observed OOM-killed under a low default `srun --pty bash`
# allocation with no explicit --mem) is exactly the kind of failure this
# guards against silently sailing past.
Rscript -e '
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  needed <- c("rmarkdown", "knitr", "reticulate", "ranger", "dplyr",
              "tidyr", "readr", "testthat", "roxygen2", "remotes")
  have <- rownames(installed.packages())
  missing <- setdiff(needed, have)
  if (length(missing) > 0) install.packages(missing)
  still_missing <- setdiff(needed, rownames(installed.packages()))
  if (length(still_missing) > 0) {
    stop(
      "Failed to install: ", paste(still_missing, collapse = ", "),
      ". Common cause: not enough memory to compile a package (RcppEigen ",
      "especially) -- rerun with more memory, e.g. `srun --mem=8G ",
      "--cpus-per-task=4 --pty bash` instead of a bare `srun --pty bash`.",
      call. = FALSE
    )
  }
  # Pandoc via a plain download, not conda -- rmarkdown needs it, and this
  # sidesteps the same conda issue this whole script exists to avoid.
  if (!rmarkdown::pandoc_available()) rmarkdown::install_pandoc()
  if (!rmarkdown::pandoc_available()) stop("pandoc install failed.", call. = FALSE)
  cat("pandoc: OK\n")
'

echo
echo "=== Installing CodeCarbonR itself from this clone ==="
Rscript -e '
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  install.packages(".", repos = NULL, type = "source")
  if (!requireNamespace("CodeCarbonR", quietly = TRUE)) {
    stop("CodeCarbonR install failed -- see the install.packages() output above.", call. = FALSE)
  }
'

echo
echo "=== Python venv -> $VENV_DIR ==="
if [ -d "$VENV_DIR" ]; then
  echo "Already exists, reusing it -- delete $VENV_DIR first if you've"
  echo "changed CODECARBONR_PYTHON_MODULE and need it rebuilt from a"
  echo "different Python (this script won't do that for you)."
else
  python3 -m venv "$VENV_DIR"
fi
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
echo "venv Python: $(python3 --version)"
pip install --no-cache-dir --upgrade pip
# setuptools>=81 dropped pkg_resources, which codecarbon still imports at
# module load time -- see .github/workflows/R-CMD-check.yaml for the same
# pin and why it's there.
pip install --no-cache-dir "setuptools<81" codecarbon scikit-learn pandas
deactivate

echo
echo "=== Setup complete ==="
echo "R packages:      $RLIBS_DIR"
echo "Python venv:     $VENV_DIR"
echo "CodeCarbonR is installed into R's own library alongside the other"
echo "packages above (no separate location to note)."
echo
echo "Every session/job that uses this install needs, before anything else:"
echo "  module load $R_MODULE"
echo "  export R_LIBS_USER=$RLIBS_DIR"
echo "  export CODECARBONR_VENV_PYTHON=$VENV_DIR/bin/python"
echo "(02_run_cpu_cases_native.sbatch/03_run_gpu_case_native.sbatch already do this.)"
echo
echo "Next steps:"
echo "  - sbatch hpc/monsoon/02_run_cpu_cases_native.sbatch     (cases 01-06, ready now)"
echo "  - bash hpc/monsoon/01b_setup_gpu_native.sh               (only when ready for case 07)"
