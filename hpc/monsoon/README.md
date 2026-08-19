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

   If `$HOME`'s quota can't fit these envs (numpy/torch/etc add up to
   several GB -- common on shared HPC systems), point the install
   somewhere with more room instead, e.g. project scratch storage. Set
   this *every session*, before running `01_setup.sh`/`01b_setup_gpu.sh`
   and before every `sbatch` submission (Slurm's default behavior
   propagates your shell's exported environment into the job, so
   exporting it once per session before submitting is enough --
   `02_run_cpu_cases.sbatch`/`03_run_gpu_case.sbatch` both read the same
   variable):
   ```bash
   export CODECARBONR_MINICONDA_DIR=/90daydata/<project>/<you>/miniconda3-codecarbonr
   ```
   Forgetting to set this consistently leaves two divergent installs
   around (one at the default `$HOME` path, one at your chosen location)
   with scripts silently activating whichever one they're hardcoded --
   or not hardcoded -- to find. That's an easy way to end up debugging a
   phantom problem in the wrong environment, so keep it set for the
   whole session rather than only for some of these steps.

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
- Both `.sbatch` scripts force `OMP_NUM_THREADS`/`OPENBLAS_NUM_THREADS`/
  `MKL_NUM_THREADS`/`NUMEXPR_NUM_THREADS=1`. Without this, codecarbon's
  CPU hardware detection (which pulls in numpy/BLAS) can deadlock
  indefinitely on a futex wait during tracker construction -- observed
  on Ceres (USDA SCINet), diagnosed via `pstree`/`strace` showing no
  network activity and no child process, just a stuck futex wait with an
  unusually high R thread count. Root cause: a multi-threaded BLAS
  library's thread-pool init getting confused by Slurm's cgroup CPU
  restriction. Confirmed fixed by capping to single-threaded BLAS/OpenMP
  (reproduced the hang interactively, then confirmed it disappears with
  these env vars set, before baking them into the batch scripts). Costs
  nothing meaningful in wall-clock time for workloads this small; if
  this is ever adapted for a genuinely CPU-heavy case, revisit rather
  than assuming single-threaded is always fine.
- `render_cases.R` loops over multiple cases in *one* R session --
  `rmarkdown::render()` runs each Rmd's chunks in that same process, not
  a fresh one per case, despite what an earlier version of a comment in
  that script implied. Since every case's `test.Rmd` independently calls
  `use_r_codecarbon()` in its own setup chunk, cases after the first were
  each triggering a *second* (or third, fourth, ...) `reticulate::
  use_condaenv()` call in the same session. reticulate documents that
  config can't change after Python's initialized, so a repeat call is a
  no-op by design -- but observed on Ceres, that redundant call doesn't
  fail, it just sometimes takes far longer than it should (seconds to
  tens of minutes, worse under heavy node load) rather than returning
  immediately, which is exactly what turned a 45-minute
  `02_run_cpu_cases.sbatch` run into a `TIMEOUT` that never got past case
  01. Fixed in `comparison/_harness/use_r_codecarbon.R` by skipping the
  call entirely once `reticulate::py_available(initialize = FALSE)` is
  already `TRUE`. Diagnosed via the same `pstree`/`strace` approach as
  the BLAS issue above -- caught R blocked on a `read()` from a pipe tied
  to a `bash -> bash -> bash -> conda` subprocess chain that had already
  exited by the time it could be traced directly. Not yet reconfirmed
  with a clean end-to-end run since this fix landed -- the next hang
  encountered (see below) turned out to be a separate issue, so this
  one's fix is plausible but unverified in isolation.
- Case 01's `ranger()` call hit the same *class* of bug as the BLAS one
  above -- a multi-threaded native library's thread pool stalling under
  Slurm's cgroup CPU restriction, worse on more heavily loaded nodes
  (observed with node load averages of 25 and 68) -- but via a different
  threading backend (RcppParallel/TBB, which `ranger` uses), so the
  `OMP_NUM_THREADS`/etc vars above don't reach it. Pinning
  `num.threads = 1` directly on the `ranger()`/`predict()` calls in
  `test.Rmd` was tried first and was **not sufficient on its own** --
  the hang recurred identically afterward. Current fix:
  `RCPP_PARALLEL_NUM_THREADS=1`, RcppParallel's own env var, set
  alongside the BLAS vars in both `.sbatch` scripts. Suspected reason
  the per-call argument wasn't enough: RcppParallel's thread pool may be
  sized once, at first construction, with a per-call `num.threads`
  argument only capping how many of an already-created pool get used --
  not preventing pool *creation* itself from spinning up more threads
  than that. The env var is read when the pool is first built, so it
  should constrain creation, not just usage -- but this is a plausible
  mechanism, not confirmed against RcppParallel's source, so revisit if
  it recurs a third time. Diagnosed identically to the two issues above:
  `pstree`/`strace -f -tt -p <pid>` showing multiple threads in an
  indefinite (`NULL`-timeout) `futex` wait.
