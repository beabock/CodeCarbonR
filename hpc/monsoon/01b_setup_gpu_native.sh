#!/usr/bin/env bash
# Native (module + venv) equivalent of 01b_setup_gpu.sh -- see
# 01_setup_native.sh for why this path exists instead of the conda-based
# one. Run this AFTER 01_setup_native.sh, and only once you're actually
# ready to work on the GPU case.
#
# Run on a LOGIN NODE (needs internet). Usage, from the repo root:
#   bash hpc/monsoon/01b_setup_gpu_native.sh

set -euo pipefail

R_MODULE="${CODECARBONR_R_MODULE:-R/4.5.3}"
RLIBS_DIR="${CODECARBONR_RLIBS_DIR:-$HOME/R-codecarbonr-libs}"
VENV_DIR="${CODECARBONR_VENV_DIR:-$HOME/venv-codecarbonr}"

if [ ! -d "$VENV_DIR" ]; then
  echo "Python venv not found at $VENV_DIR -- run 01_setup_native.sh first." >&2
  exit 1
fi

module load "$R_MODULE"
export R_LIBS_USER="$RLIBS_DIR"

echo "=== Adding CUDA-enabled torch to the Python venv ==="
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
# The Python module version this venv was built from (see
# CODECARBONR_PYTHON_MODULE / 01_setup_native.sh -- anaconda3/2025.06's
# 3.13.13 by default, chosen for reticulate compatibility, not GPU
# reasons) should have a published torch wheel, but if this fails, check
# https://pytorch.org/get-started/locally/ for what's actually supported
# and consider rebuilding the venv against a different Python module.
pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cu121
deactivate

echo "=== Adding R torch ==="
Rscript -e 'if (!requireNamespace("torch", quietly = TRUE)) install.packages("torch", repos = "https://cloud.r-project.org")'
Rscript -e 'torch::install_torch()'

echo
echo "=== GPU setup complete ==="
echo "Next: sbatch hpc/monsoon/03_run_gpu_case_native.sbatch"
