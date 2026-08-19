#!/usr/bin/env bash
#SBATCH --job-name=codecarbonr-cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:45:00
#SBATCH --output=hpc/monsoon/logs/cpu_%j.out
#SBATCH --error=hpc/monsoon/logs/cpu_%j.err
# No --partition set -- Monsoon's default should be fine for a CPU-only
# job. Add one (see `sinfo`) if your account needs it specified explicitly.

set -euo pipefail

# Without this, codecarbon's CPU hardware detection (which pulls in
# numpy/BLAS) can deadlock indefinitely on a futex wait during tracker
# construction -- observed on Ceres (USDA SCINet): a multi-threaded BLAS
# library's thread-pool init getting confused by Slurm's cgroup CPU
# restriction. Forcing single-threaded BLAS/OpenMP sidesteps it. The
# comparison suite's workloads are small enough that this costs nothing
# meaningful in wall-clock time.
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

# shellcheck disable=SC1091
source "$HOME/miniconda3-codecarbonr/etc/profile.d/conda.sh"
conda activate codecarbonr-r

cd "$SLURM_SUBMIT_DIR"
mkdir -p hpc/monsoon/logs

Rscript hpc/monsoon/render_cases.R
