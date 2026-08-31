# NA

## Contributing

Contributions are welcome! To get started:

1.  Fork the repo and clone your fork.
2.  Install development dependencies:

``` r

   devtools::install_deps(dependencies = TRUE)
```

3.  Make your changes in `R/`. If you add or modify exported functions,
    update the roxygen2 documentation and run:

``` r

   devtools::document()
```

4.  Add tests in `tests/testthat/` for any new behavior. Tests that
    require the `r-codecarbon` conda environment should use
    `skip_if_not()` so they don’t fail in environments without it set
    up.
5.  Before opening a PR, run:

``` r

   devtools::test()
   devtools::check()
```

6.  Add a bullet to `NEWS.md` describing your change.
7.  Open a pull request against `main` describing the change and, if
    relevant, any validation against `codecarbon` (see
    `comparison/coverage_matrix.md`).

Bug reports and feature requests are welcome via [GitHub
Issues](https://github.com/beabock/CodeCarbonR/issues).
