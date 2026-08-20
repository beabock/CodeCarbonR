#!/usr/bin/env bash
#SBATCH --job-name=codecarbonr-gpu-native
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=hpc/monsoon/logs/gpu_native_%j.out
#SBATCH --error=hpc/monsoon/logs/gpu_native_%j.err
# No --account set -- see 02_run_cpu_cases_native.sbatch for why.
# No --exclusive here -- see 03_run_gpu_case.sbatch (the conda-based
# version): Ceres rejected --exclusive + --gpus=1 as an unschedulable
# node configuration. Try adding it back if a contention-related hang
# shows up here and Monsoon's GPU nodes turn out to support the
# combination unlike Ceres's.
# --gpus=1 requests any GPU model. Check `sinfo`/Monsoon's GPU docs for
# what's actually available and how to pin a specific model if needed.

set -euo pipefail

# See 02_run_cpu_cases_native.sbatch for why.
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export RCPP_PARALLEL_NUM_THREADS=1

R_MODULE="${CODECARBONR_R_MODULE:-R/4.5.3}"
PYTHON_MODULE="${CODECARBONR_PYTHON_MODULE:-anaconda3/2025.06}"
RLIBS_DIR="${CODECARBONR_RLIBS_DIR:-$HOME/R-codecarbonr-libs}"
VENV_DIR="${CODECARBONR_VENV_DIR:-$HOME/venv-codecarbonr}"

module load "$R_MODULE"
# See 02_run_cpu_cases_native.sbatch -- the venv's python binary needs
# its base Python module's environment loaded to actually run correctly.
module load "$PYTHON_MODULE"
export R_LIBS_USER="$RLIBS_DIR"
export CODECARBONR_VENV_PYTHON="$VENV_DIR/bin/python"

cd "$SLURM_SUBMIT_DIR"
mkdir -p hpc/monsoon/logs

echo "=== nvidia-smi ==="
nvidia-smi || echo "nvidia-smi not found -- GPU may not be visible to this job"

Rscript hpc/monsoon/render_cases.R 07_gpu_neural_net
