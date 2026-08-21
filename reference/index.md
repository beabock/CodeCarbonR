# Package index

## Setup

Install the Python backend once per machine, and check it’s ready

- [`setup_carbon_tracker()`](https://beabock.github.io/CodeCarbonR/reference/setup_carbon_tracker.md)
  : Install codecarbon into a dedicated conda environment
- [`carbon_tracker_ready()`](https://beabock.github.io/CodeCarbonR/reference/carbon_tracker_ready.md)
  : Check whether codecarbon is installed and importable

## Track emissions

Measure a block of code, or a longer-running/multi-phase session

- [`with_emissions_tracked()`](https://beabock.github.io/CodeCarbonR/reference/with_emissions_tracked.md)
  : Track emissions for a single block of code
- [`carbon_tracker()`](https://beabock.github.io/CodeCarbonR/reference/carbon_tracker.md)
  : Create a carbon emissions tracker

## Reference data

- [`list_carbon_tracker_countries()`](https://beabock.github.io/CodeCarbonR/reference/list_carbon_tracker_countries.md)
  : List supported country codes for carbon intensity lookup
