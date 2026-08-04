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
module load cuda

# shellcheck disable=SC1091
source "$HOME/miniconda3-codecarbonr/etc/profile.d/conda.sh"
conda activate codecarbonr-r

cd "$SLURM_SUBMIT_DIR"
mkdir -p hpc/monsoon/logs

echo "=== nvidia-smi ==="
nvidia-smi || echo "nvidia-smi not found -- GPU may not be visible to this job"

Rscript hpc/monsoon/render_cases.R 07_gpu_neural_net
