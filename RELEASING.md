# Releasing CodeCarbonR

Checklist for cutting a tagged release, archiving it on Zenodo for a DOI,
and (optional/stretch) getting it CRAN-ready. Steps that need your own
login/account action are marked **(you)** -- I can prepare everything else,
but account creation, OAuth grants, and clicking "publish" on an external
service are outside what I can do for you.

## 1. Pre-release checklist

- [ ] `DESCRIPTION`: bump `Version:` from `0.0.0.9000` to a real release
      version, e.g. `0.1.0` (semantic versioning; this is a first public
      release, so `0.1.0` rather than `1.0.0` is reasonable unless you
      consider the API stable).
- [ ] Review/expand `NEWS.md` (a starter draft exists) and retitle its
      `# CodeCarbonR (development version)` heading to the real release
      version once you bump `DESCRIPTION`.
- [ ] Run the full check locally one more time:
      `R CMD build .` then `R CMD check --no-manual <tarball>` -- should
      be 0 errors, 0 warnings, ideally 0 notes.
- [ ] Confirm CI is green on `main` for all three OSes
      (`.github/workflows/R-CMD-check.yaml`).
- [ ] Update `CITATION.cff`'s `version:` and `date-released:` to match.
- [ ] Update `comparison/coverage_matrix.md` if case 07 (GPU) has been
      validated by then -- don't ship a release implying GPU coverage
      that hasn't actually been run.

## 2. Tag and create the GitHub release **(you, or ask me to run `gh` for you)**

```bash
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0
```

Then create a GitHub Release from that tag (via the GitHub UI, or
`gh release create v0.1.0 --title "v0.1.0" --notes "..."`). The release
notes are what Zenodo will show alongside the archived version, so it's
worth writing a real paragraph, not just "release", e.g.:

> Initial public release of CodeCarbonR. Wraps codecarbon's
> `OfflineEmissionsTracker` via reticulate for tracking R code's energy
> consumption and estimated CO2 emissions. Validated against equivalent
> Python/codecarbon workloads across 6 test cases (ML training, data
> wrangling, statistical modeling, long-running simulation, large-file
> I/O, multi-phase tracking) on Windows; see `comparison/coverage_matrix.md`
> for exact status per case and platform.

## 3. Archive on Zenodo for a DOI **(you -- Zenodo account + GitHub link)**

1. Log into [zenodo.org](https://zenodo.org) with your GitHub account
   (or link an existing Zenodo account to GitHub under
   Account Settings -> GitHub).
2. Find `beabock/CodeCarbonR` in the repository list and toggle it **on**
   *before* creating the GitHub release -- Zenodo only archives releases
   made after the toggle is flipped, it won't retroactively pick up a
   release you already published. If you already created the v0.1.0
   release before flipping the toggle, either delete and recreate the
   release, or cut a v0.1.1 tag after enabling Zenodo.
3. Publish the GitHub release (or re-trigger it) -- Zenodo picks it up
   automatically via its GitHub webhook and mints a DOI within a few
   minutes.
4. On the Zenodo record page, copy:
   - the **version DOI** (specific to `v0.1.0`)
   - the **concept DOI** (stable across all versions -- this is the one
     to put in a paper's citation, since it'll keep resolving to the
     latest version if you cut v0.1.1, v0.2.0, etc. later)
5. Fill in `CITATION.cff`'s commented-out `doi:`/`identifiers:` fields
   with those, commit, and this becomes the canonical citation metadata
   GitHub shows in the "Cite this repository" sidebar button too.
6. Add the Zenodo DOI badge to `README.md` (Zenodo gives you the markdown
   snippet directly on the record page, looks like
   `[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)`).

This is what gets you the EDS Open Practice Badge and a citable DOI for
the code, independent of whether you ever publish to CRAN.

## 4. CRAN (optional / stretch)

Not required for the Zenodo DOI or the paper's reproducibility claims --
only pursue this if you specifically want CRAN's discoverability/CI
guarantees on top. Frictions specific to this package:

- **`R CMD check --as-cran` must stay clean.** Validated 2026-08-05 with
  `--as-cran` specifically (which is what actually caught the issues
  below -- a plain `R CMD check` misses some of these). `CITATION.cff` and
  `RELEASING.md` are `.Rbuildignore`d, so they stay at the repo root for
  GitHub's "Cite this repository" button and Zenodo to find (Zenodo/GitHub
  read them from the git repo directly, not from the built R package
  tarball, so excluding them from the tarball costs nothing there), while
  `inst/CITATION` is what makes `citation("CodeCarbonR")` work from R. The
  `LICENSE` file is the short DCF stub R expects for `License: MIT + file
  LICENSE` (`YEAR:`/`COPYRIGHT HOLDER:`); the full MIT text lives in
  `LICENSE.md` instead (also `.Rbuildignore`d), which is what GitHub's
  license detector reads.
- **`setup_carbon_tracker()` installs software and touches the network.**
  CRAN's policy forbids examples/tests/vignettes that install software,
  write outside `tempdir()`, or require network access during
  `R CMD check`, and forbids interactive prompts entirely (`utils::menu()`
  inside `setup_carbon_tracker()` would need to not run at all under
  `R CMD check`). Concretely:
  - Any `@examples` block calling `setup_carbon_tracker()`,
    `carbon_tracker()`, or `with_emissions_tracked()` needs
    `\donttest{}` (or `\dontrun{}` if it truly can't run under any CI) so
    CRAN's check machines don't execute it.
  - `tests/testthat/*.R`'s live-tracker tests already use
    `skip_if_no_codecarbon()` (see `tests/testthat/helper.R`), which is
    the right idea, but CRAN's check machines will have codecarbon
    unavailable, so add `testthat::skip_on_cran()` alongside it (or
    replace it) so these don't even attempt to check for codecarbon on
    CRAN's infrastructure -- `skip_if_no_codecarbon()` alone should
    already result in a skip there since codecarbon won't be importable,
    but `skip_on_cran()` makes the intent explicit and doesn't depend on
    that assumption holding.
  - The `vignettes/quickstart.Rmd` walkthrough already uses
    `eval = FALSE` on every chunk for this reason -- it shows realistic
    example output as literal text rather than executing against a live
    tracker, so building it never touches Python/network.
  - `setup_carbon_tracker()` itself already refuses to run
    non-interactively (see `R/setup.R`), which is the correct behavior
    for CRAN but means nothing exercises it in automated checks; that's
    an intentional gap, not something to "fix" for CRAN's sake.
- **A CRAN maintainer will ask why this needs a whole Python install.**
  Worth a line in the CRAN submission comments (`cran-comments.md`)
  explaining that `codecarbon` has no R equivalent and that setup is
  opt-in, confirmed, and isolated to its own conda environment rather
  than touching the user's system Python.

### 4a. Step-by-step, once you decide to go for it

Pre-submission (in addition to the package-specific fixes above):

- [ ] Every exported function (`setup_carbon_tracker()`, `carbon_tracker()`,
      `with_emissions_tracked()`, `list_carbon_tracker_countries()`,
      `carbon_tracker_ready()`) needs an `@examples` block in its roxygen
      comment. None currently exist. Wrap any example that would call
      `setup_carbon_tracker()`, start a tracker, or otherwise touch
      Python/network in `\donttest{}` (runs on your machine, skipped on
      CRAN's checks) -- e.g. show `list_carbon_tracker_countries()` or
      `carbon_tracker_ready()` unwrapped since those don't touch Python,
      but wrap a `with_emissions_tracked()` example in `\donttest{}`.
- [ ] Confirm `Authors@R` includes a copyright holder role -- add `"cph"`
      to Beatrice Bock's `role = c(...)` in `DESCRIPTION` if it's only
      `c("aut", "cre")` currently (CRAN wants an explicit copyright holder,
      not just author/maintainer).
- [ ] Write `cran-comments.md` at the repo root (`.Rbuildignore` it if you
      don't want it in the built tarball, though CRAN's web form also asks
      for these comments directly). Cover: this is a first submission;
      what the package does in one line; and the Python/conda point noted
      above -- `codecarbon` has no R equivalent, `setup_carbon_tracker()`
      is opt-in/interactive/confirmed and installs into its own isolated
      conda environment, never touches the user's system Python, and
      never runs during `R CMD check` (it errors intentionally in
      non-interactive contexts, which is what the test suite checks for).
- [ ] From R, in the package directory:
      ```r
      usethis::use_version("minor")   # bumps 0.0.0.9000 -> 0.1.0, tags NEWS.md
      devtools::check(remote = TRUE, manual = TRUE)   # full local check
      devtools::check_win_devel()      # builds on R's Windows dev servers, emails you the log
      urlchecker::url_check()          # catches dead links in docs/README/vignette
      ```
      All three should come back clean (0 errors, 0 warnings, ideally 0
      notes) before submitting. `check_win_devel()` in particular catches
      things your local machine's R version won't.
- [ ] Update `NEWS.md`'s heading from `# CodeCarbonR (development version)`
      (or `0.0.0.9000`) to the real version, and `CITATION.cff`'s
      `version:`/`date-released:` to match.

Submission:

- [ ] `devtools::submit_cran()` -- builds the source tarball, uploads it
      to CRAN's submission form, and pulls maintainer info + your
      `cran-comments.md` content into the form automatically. (Manual
      alternative: build with `R CMD build .`, then upload the resulting
      `.tar.gz` yourself at
      [cran.r-project.org/submit.html](https://cran.r-project.org/submit.html).)
- [ ] **(you)** CRAN emails a confirmation link to the maintainer address
      in `DESCRIPTION` -- click it. The submission doesn't enter the queue
      until confirmed.
- [ ] Wait. CRAN's automated checks (multiple OSes/R versions) typically
      report back within a day or two; a human CRAN team member reviews
      after that. Total time is unpredictable -- same-day acceptances and
      multi-week back-and-forth both happen, and a package installing
      external software during setup (even opt-in) is exactly the kind of
      thing that can prompt a question rather than an immediate accept.
- [ ] If CRAN comes back with required changes: fix them, bump the patch
      version again (e.g. `0.1.0` -> `0.1.1`), add a line to
      `cran-comments.md` under a "Resubmission" heading explaining what
      changed, and resubmit the same way.
- [ ] On acceptance: tag/release on GitHub if you haven't already (Section
      2 above), then bump `DESCRIPTION`'s version to a new `.9000`
      development suffix (e.g. `0.1.0.9000`) so it's clear `main` is past
      the released version.
