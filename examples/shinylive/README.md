# Alternative Shinylive explorer

This standalone browser app uses Shiny and a frozen public snapshot. It is not a dependency of the R data-access package. To reproduce:

1. Install `psilocybinresearch`, `shiny` and `shinylive`.
2. Use `download_snapshot()` to create a new snapshot directory.
3. Copy `app.R` into that directory alongside `publications.rds` and `dataset-manifest.json`.
4. Run `shinylive::export(snapshot_directory, output_directory)` then run `python3 prepare-export.py output_directory` and serve the exported static files over HTTPS or localhost. The post-export step preserves other applications’ offline caches and supports Apache directory indexes and restricted certificate extensions.

The app counts indexed bibliographic records, not independent studies or treatment effects. Snapshot timestamp and checksum are visible in the interface. Source rights remain separate from the package code licence.
