# Running the comparison suite on Monsoon (NAU HPC)

Two things this is for: real Linux validation of cases 01-06 (everything
so far has only run on Windows), and finally running case 07 (GPU), which
has been built but unvalidated since there's no GPU in the dev
environment. Whether the Linux run is also a *stronger* validation than
Windows -- not just a different platform -- depends on whether Monsoon's
CPU nodes expose real hardware power measurement (RAPL) or fall back to
the same CPU-load x TDP estimate Windows uses. Check that first (step 1)
before investing time in the rest.

## Steps

1. **Clone and check RAPL access**, from a login node:
   ```bash
   git clone https://github.com/beabock/CodeCarbonR.git
   cd CodeCarbonR
   srun --pty bash          # get an interactive compute-node session
   bash hpc/monsoon/00_check_rapl.sh
   exit                     # back to the login node
   ```
   If RAPL isn't readable, the run below still validates Linux
   compatibility (worth doing), just don't expect the emissions numbers
   to be more informative than what's already validated on Windows.

2. **One-time setup** (login node, needs internet):
   ```bash
   bash hpc/monsoon/01_setup.sh
   ```
   Bootstraps its own Miniconda into `$HOME/miniconda3-codecarbonr` with
   two environments: `r-codecarbon` (Python side -- codecarbon, sklearn,
   pandas, torch) and `codecarbonr-r` (R side -- R itself plus every
   package the comparison suite needs, including R `torch` for case 07).
   Doesn't touch any pre-existing R/Python modules, so it doesn't matter
   what is or isn't already on the cluster.

3. **Run the CPU cases** (01-06):
   ```bash
   sbatch hpc/monsoon/02_run_cpu_cases.sbatch
   ```
   Check progress with `squeue --me`; output lands in
   `hpc/monsoon/logs/cpu_<jobid>.out` and a results CSV in
   `hpc/monsoon/logs/results_<timestamp>.csv`.

4. **Run the GPU case** (07):
   ```bash
   sbatch hpc/monsoon/03_run_gpu_case.sbatch
   ```
   `--gpus=1` requests any available GPU model; edit the script to pin a
   specific one (e.g. `--gpus=a100`) if needed. If this is the first time
   this case has actually executed anywhere, expect it to need real
   debugging -- the R `torch`/Python `PyTorch` code in
   `comparison/07_gpu_neural_net/test.Rmd` was written without being able
   to run it, so treat this as the first real test of it, not a rerun.

5. **Update `comparison/coverage_matrix.md`** with whatever actually
   happened -- pass, fail, or partial -- once you have results. Don't
   silently leave it saying "Windows only" if Linux runs succeeded, and
   don't mark case 07 "validated" unless it actually completed cleanly.

## Notes

- Steps 3 and 4 don't need internet -- everything they use was installed
  in step 2. If a compute node genuinely has no outbound internet at all
  (common on HPC clusters), this matters: don't try to install anything
  from within the sbatch scripts themselves.
- `render_cases.R` (called by both batch scripts) prints and saves a
  `r_cpu_power`/`py_cpu_power` column specifically so you can tell at a
  glance whether this run got real RAPL measurement or the constant
  estimate -- a single repeated value across every row means the
  estimate, varying values mean real measurement.
- GPU usage while a job runs can be watched live via
  `nvidia-smi dmon` (SSH'd into the GPU node) or
  [Monsoon Metrics](https://metrics.hpc.nau.edu/) (NAU network/VPN
  required).
