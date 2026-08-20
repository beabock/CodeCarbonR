#!/usr/bin/env bash
#SBATCH --job-name=codecarbonr-cpu-native
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=hpc/monsoon/logs/cpu_native_%j.out
#SBATCH --error=hpc/monsoon/logs/cpu_native_%j.err
# No --account set -- add one (#SBATCH --account=<your_account>, or
# `sbatch --account=<your_account> ...`) if `sbatch` rejects this with
# "You must specify an account!" (some clusters, e.g. Ceres/USDA SCINet,
# require it; Monsoon didn't as of this writing).
# --exclusive: reserves the whole node. See 02_run_cpu_cases.sbatch (the
# conda-based version of this script) and hpc/monsoon/README.md's Notes --
# a suspected reticulate cross-thread race was observed to correlate
# strongly with node load average on Ceres. Not yet confirmed as relevant
# on Monsoon specifically (this script exists because conda itself is
# broken here, a separate issue), but kept as a reasonable default. Drop
# it if `sbatch` rejects the resource shape (happened for Ceres's GPU
# job) or if it's not worth the allocation-hour cost for your account.

set -euo pipefail

# Same reasoning as 02_run_cpu_cases.sbatch (the conda-based version):
# without this, a multi-threaded native library's thread pool (BLAS,
# RcppParallel/TBB) can auto-detect and spin up a thread per core, which
# under Slurm's cgroup CPU restriction is exactly the kind of
# oversubscription that produces indefinite futex-wait hangs. Missing
# from this script until now -- observed on Monsoon as a hang at
# "[setup] CPU Tracking..." with 15+ threads in gdb's `thread apply all
# bt` (vs. the 5-thread signature of the reticulate cross-thread race
# these vars don't address), reproduced even after fixing the separate
# missing-Python-module issue below, which was a real but insufficient
# fix on its own.
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
# The venv's python binary still needs its base Python installation's
# module environment loaded (shared libraries etc.) to run correctly --
# omitting this reproduced the exact hang 01_setup_native.sh's Notes
# entry describes for python/3.14.3, even after switching the venv to
# anaconda3/2025.06's Python, because the module supplying that Python
# was never actually loaded in this job's environment.
module load "$PYTHON_MODULE"
export R_LIBS_USER="$RLIBS_DIR"
export CODECARBONR_VENV_PYTHON="$VENV_DIR/bin/python"

cd "$SLURM_SUBMIT_DIR"
mkdir -p hpc/monsoon/logs

Rscript hpc/monsoon/render_cases.R
