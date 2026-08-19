#!/usr/bin/env bash
# GPU add-on setup, for case 07 only. Run this AFTER 01_setup.sh, and only
# once you're actually ready to work on the GPU case -- CUDA-enabled torch
# (both the Python wheel and R's libtorch download) runs several GB combined,
# kept separate from 01_setup.sh so that cost isn't paid until it's needed.
#
# Run on a LOGIN NODE (needs internet). Usage, from the repo root:
#   bash hpc/monsoon/01b_setup_gpu.sh

set -euo pipefail

# Same override as 01_setup.sh -- if you set CODECARBONR_MINICONDA_DIR for
# that script, set it the same way here too.
MINICONDA_DIR="${CODECARBONR_MINICONDA_DIR:-$HOME/miniconda3-codecarbonr}"
if [ ! -d "$MINICONDA_DIR" ]; then
  echo "Miniconda not found at $MINICONDA_DIR -- run 01_setup.sh first." >&2
  exit 1
fi
# shellcheck disable=SC1091
source "$MINICONDA_DIR/etc/profile.d/conda.sh"

show_quota() {
  echo "--- disk usage on $MINICONDA_DIR ---"
  quota -s 2>/dev/null || df -h "$MINICONDA_DIR"
  echo "----------------------------"
}

echo "=== Quota before GPU install ==="
show_quota

echo "=== Adding CUDA-enabled torch to r-codecarbon ==="
conda activate r-codecarbon
pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cu121
conda deactivate
conda clean -a -y >/dev/null

echo "=== Adding R torch to codecarbonr-r ==="
conda activate codecarbonr-r
Rscript -e 'if (!requireNamespace("torch", quietly = TRUE)) install.packages("torch", repos = "https://cloud.r-project.org")'
Rscript -e 'torch::install_torch()'

echo
echo "=== Quota after GPU install ==="
show_quota

echo
echo "=== GPU setup complete ==="
echo "Next: sbatch hpc/monsoon/03_run_gpu_case.sbatch"
