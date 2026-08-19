#!/usr/bin/env bash
#SBATCH --job-name=codecarbonr-cpu
#SBATCH --account=weeds_and_bees
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:45:00
#SBATCH --output=hpc/monsoon/logs/cpu_%j.out
#SBATCH --error=hpc/monsoon/logs/cpu_%j.err
# --account set to this project's Ceres (USDA SCINet) account -- `sbatch`
# refuses to submit without one on this cluster. Override on the command
# line (`sbatch --account=<other> ...`) if running under a different
# account; a flag passed at submission takes precedence over this default.
# No --partition set -- the default should be fine for a CPU-only job.
# Add one (see `sinfo`) if your account needs it specified explicitly.

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
# Same class of bug, different threading backend: ranger (case 01) uses
# RcppParallel/TBB, not BLAS, so the vars above don't reach it. Pinning
# num.threads=1 per-call in test.Rmd wasn't sufficient on its own --
# RcppParallel's thread pool appears to be sized at first construction,
# which a per-call argument may only cap usage of rather than prevent
# from being created in the first place. This env var is RcppParallel's
# own session-wide override, read when that pool is first built, so it
# constrains pool *creation* rather than just usage. See
# hpc/monsoon/README.md's Notes section.
export RCPP_PARALLEL_NUM_THREADS=1

# Same install location as 01_setup.sh. If you set CODECARBONR_MINICONDA_DIR
# for that script (e.g. because $HOME's quota can't fit the conda envs),
# `export` it in your shell before `sbatch`-submitting this job too --
# Slurm's default behavior propagates the submitting shell's exported
# environment into the job, so this picks it up automatically.
MINICONDA_DIR="${CODECARBONR_MINICONDA_DIR:-$HOME/miniconda3-codecarbonr}"
# shellcheck disable=SC1091
source "$MINICONDA_DIR/etc/profile.d/conda.sh"
conda activate codecarbonr-r

cd "$SLURM_SUBMIT_DIR"
mkdir -p hpc/monsoon/logs

Rscript hpc/monsoon/render_cases.R
