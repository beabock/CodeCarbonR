#!/usr/bin/env bash
# Quick check: can codecarbon actually read real CPU power on this node, or
# will it fall back to the CPU-load x TDP estimate -- the same limitation
# as the Windows machine this suite was originally validated on?
#
# Run this FIRST, before 01_setup.sh, ideally from an interactive session on
# the actual node type you'll run cases on (not just the login node, which
# may have different hardware/permissions than compute nodes):
#   srun --pty bash
#   bash hpc/monsoon/00_check_rapl.sh
#
# If RAPL isn't readable here, a Monsoon run still validates Linux
# compatibility (still worth doing), but won't be a stronger accuracy
# result than what's already validated on Windows -- worth knowing before
# investing time in the full setup.

set -uo pipefail

echo "Host: $(hostname)"
echo "Checking for Intel RAPL power monitoring interface..."
RAPL_DIR="/sys/class/powercap/intel-rapl"

if [ ! -d "$RAPL_DIR" ]; then
  echo "NOT FOUND: $RAPL_DIR doesn't exist on this node."
  echo "Either not an Intel CPU, or RAPL isn't exposed here at all."
  echo "codecarbon will fall back to the CPU-load x TDP estimate."
  exit 0
fi

echo "Found $RAPL_DIR. Checking read access on each domain..."
found_readable=0
for f in "$RAPL_DIR"/*/energy_uj; do
  [ -e "$f" ] || continue
  if [ -r "$f" ]; then
    echo "  READABLE:     $f"
    found_readable=1
  else
    echo "  NOT READABLE: $f (permission denied)"
  fi
done

echo
if [ "$found_readable" -eq 1 ]; then
  echo "RAPL is readable without root on this node. codecarbon should get"
  echo "real CPU power measurement here -- worth running the full suite for"
  echo "the accuracy validation, not just Linux compatibility."
else
  echo "RAPL exists but isn't readable without root (common on shared HPC"
  echo "nodes for security). codecarbon will fall back to the CPU-load x"
  echo "TDP estimate, same as Windows. Still useful for Linux compatibility,"
  echo "but won't strengthen the accuracy claim beyond what's already done."
fi
