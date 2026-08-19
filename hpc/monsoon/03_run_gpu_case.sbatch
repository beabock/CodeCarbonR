#!/usr/bin/env bash
#SBATCH --job-name=codecarbonr-gpu
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=00:30:00
#SBATCH --output=hpc/monsoon/logs/gpu_%j.out
#SBATCH --error=hpc/monsoon/logs/gpu_%j.err
# --gpus=1 requests any GPU model. To pin a specific model (Monsoon docs
# give k80/a100 as examples): --gpus=a100 or --gpus=k80:1. See Monsoon's
# GPU job docs / `sinfo` for what's actually available to your account.

set -euo pipefail

# See 02_run_cpu_cases.sbatch for why: without this, codecarbon's CPU
# hardware detection (numpy/BLAS-backed) can deadlock on a futex wait
# during tracker construction, from a multi-threaded BLAS library's
# thread-pool init getting confused by Slurm's cgroup CPU restriction.
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

module load cuda

# Same install location as 01_setup.sh -- see 02_run_cpu_cases.sbatch for
# why CODECARBONR_MINICONDA_DIR needs to be `export`ed before submission,
# not just set here.
MINICONDA_DIR="${CODECARBONR_MINICONDA_DIR:-$HOME/miniconda3-codecarbonr}"
# shellcheck disable=SC1091
source "$MINICONDA_DIR/etc/profile.d/conda.sh"
conda activate codecarbonr-r

cd "$SLURM_SUBMIT_DIR"
mkdir -p hpc/monsoon/logs

echo "=== nvidia-smi ==="
nvidia-smi || echo "nvidia-smi not found -- GPU may not be visible to this job"

Rscript hpc/monsoon/render_cases.R 07_gpu_neural_net
