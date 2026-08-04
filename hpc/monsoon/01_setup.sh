#!/usr/bin/env bash
# One-time setup for running the CodeCarbonR comparison suite on Monsoon.
#
# Run this on a LOGIN NODE (needs internet for downloads). The batch scripts
# (02_run_cpu_cases.sbatch, 03_run_gpu_case.sbatch) only use what this
# installs into $HOME and don't need internet themselves.
#
# Usage, from the repo root after cloning:
#   bash hpc/monsoon/01_setup.sh

set -euo pipefail

MINICONDA_DIR="$HOME/miniconda3-codecarbonr"

echo "=== Installing Miniconda to $MINICONDA_DIR (skipped if already present) ==="
if [ ! -d "$MINICONDA_DIR" ]; then
  curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda-codecarbonr.sh
  bash /tmp/miniconda-codecarbonr.sh -b -p "$MINICONDA_DIR"
  rm /tmp/miniconda-codecarbonr.sh
fi
# shellcheck disable=SC1091
source "$MINICONDA_DIR/etc/profile.d/conda.sh"

echo "=== Creating r-codecarbon Python env ==="
# Must be named exactly "r-codecarbon" -- R/zzz.R's .onLoad looks for this
# name specifically via reticulate::use_condaenv().
if ! conda env list | grep -q "^r-codecarbon "; then
  conda create -y -n r-codecarbon python=3.11
fi
conda activate r-codecarbon
pip install --upgrade pip
# setuptools>=81 dropped pkg_resources, which codecarbon still imports at
# module load time -- see .github/workflows/R-CMD-check.yaml for the same
# pin and why it's there.
pip install "setuptools<81" codecarbon scikit-learn pandas
# CUDA-enabled torch for case 07 (falls back to working fine on CPU nodes
# too, just without GPU support -- codecarbon's GPU tracking simply won't
# report anything on those, which is expected).
pip install torch --index-url https://download.pytorch.org/whl/cu121
conda deactivate

echo "=== Creating codecarbonr-r R env ==="
if ! conda env list | grep -q "^codecarbonr-r "; then
  conda create -y -n codecarbonr-r -c conda-forge \
    r-base r-rmarkdown r-knitr r-reticulate r-ranger r-dplyr r-tidyr \
    r-readr r-testthat r-roxygen2 r-remotes pandoc
fi
conda activate codecarbonr-r

echo "=== Installing R torch (for case 07) ==="
Rscript -e 'if (!requireNamespace("torch", quietly = TRUE)) install.packages("torch", repos = "https://cloud.r-project.org")'
Rscript -e 'torch::install_torch()'

echo "=== Installing CodeCarbonR itself from this clone ==="
Rscript -e 'install.packages(".", repos = NULL, type = "source")'

echo
echo "=== Setup complete ==="
echo "Python env:  r-codecarbon   ($MINICONDA_DIR/envs/r-codecarbon)"
echo "R env:       codecarbonr-r  ($MINICONDA_DIR/envs/codecarbonr-r)"
echo
echo "Next steps:"
echo "  1. bash hpc/monsoon/00_check_rapl.sh   (ideally via 'srun --pty bash' first)"
echo "  2. sbatch hpc/monsoon/02_run_cpu_cases.sbatch"
echo "  3. sbatch hpc/monsoon/03_run_gpu_case.sbatch"
