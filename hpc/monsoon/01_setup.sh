#!/usr/bin/env bash
# One-time CPU-side setup for running comparison cases 01-06 on Monsoon.
# GPU-only additions (torch, for case 07) are in 01b_setup_gpu.sh -- kept
# separate since CUDA-enabled torch alone runs multiple GB, and there's no
# reason to pay that cost until you're actually ready for the GPU case.
#
# Run this on a LOGIN NODE (needs internet for downloads). The batch script
# (02_run_cpu_cases.sbatch) only uses what this installs and doesn't need
# internet itself.
#
# Installs to $HOME/miniconda3-codecarbonr by default. If your account's
# $HOME quota can't fit a conda env with numpy/torch/etc (common on shared
# HPC systems), set CODECARBONR_MINICONDA_DIR to somewhere with more room
# (e.g. project scratch storage) before running this AND before every
# sbatch submission -- 02_run_cpu_cases.sbatch/03_run_gpu_case.sbatch read
# the same variable, and Slurm's default `sbatch` behavior does propagate
# your exported environment into the job, so `export`ing it in your shell
# is enough:
#   export CODECARBONR_MINICONDA_DIR=/90daydata/<project>/<you>/miniconda3-codecarbonr
#
# Usage, from the repo root after cloning:
#   bash hpc/monsoon/01_setup.sh

set -euo pipefail

MINICONDA_DIR="${CODECARBONR_MINICONDA_DIR:-$HOME/miniconda3-codecarbonr}"

show_quota() {
  # $MINICONDA_DIR itself may not exist yet on the "before install" call --
  # df needs a path that's actually there, so fall back to its parent.
  local quota_check_path="$MINICONDA_DIR"
  [ -d "$quota_check_path" ] || quota_check_path="$(dirname "$MINICONDA_DIR")"
  echo "--- disk usage on $quota_check_path ---"
  quota -s 2>/dev/null || df -h "$quota_check_path"
  echo "----------------------------"
}

echo "=== Quota before install ==="
show_quota

echo "=== Installing Miniconda to $MINICONDA_DIR (skipped if already present) ==="
if [ ! -d "$MINICONDA_DIR" ]; then
  curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda-codecarbonr.sh
  bash /tmp/miniconda-codecarbonr.sh -b -p "$MINICONDA_DIR"
  rm /tmp/miniconda-codecarbonr.sh
fi
# shellcheck disable=SC1091
source "$MINICONDA_DIR/etc/profile.d/conda.sh"

echo "=== Creating r-codecarbon Python env (CPU-side packages only) ==="
# Must be named exactly "r-codecarbon" -- R/zzz.R's .onLoad looks for this
# name specifically via reticulate::use_condaenv().
if ! conda env list | grep -q "^r-codecarbon "; then
  conda create -y -n r-codecarbon python=3.11
fi
conda activate r-codecarbon
pip install --no-cache-dir --upgrade pip
# setuptools>=81 dropped pkg_resources, which codecarbon still imports at
# module load time -- see .github/workflows/R-CMD-check.yaml for the same
# pin and why it's there.
pip install --no-cache-dir "setuptools<81" codecarbon scikit-learn pandas
conda deactivate
conda clean -a -y >/dev/null

echo "=== Creating codecarbonr-r R env ==="
if ! conda env list | grep -q "^codecarbonr-r "; then
  conda create -y -n codecarbonr-r -c conda-forge \
    r-base r-rmarkdown r-knitr r-reticulate r-ranger r-dplyr r-tidyr \
    r-readr r-testthat r-roxygen2 r-remotes pandoc
fi
conda activate codecarbonr-r
conda clean -a -y >/dev/null

echo "=== Installing CodeCarbonR itself from this clone ==="
Rscript -e 'install.packages(".", repos = NULL, type = "source")'

echo
echo "=== Quota after install ==="
show_quota

echo
echo "=== CPU setup complete ==="
echo "Python env:  r-codecarbon   ($MINICONDA_DIR/envs/r-codecarbon)"
echo "R env:       codecarbonr-r  ($MINICONDA_DIR/envs/codecarbonr-r)"
echo
echo "Next steps:"
echo "  - sbatch hpc/monsoon/02_run_cpu_cases.sbatch     (cases 01-06, ready now)"
echo "  - bash hpc/monsoon/01b_setup_gpu.sh              (only when ready for case 07 --"
echo "    check the quota output above first; CUDA torch alone runs several GB)"
