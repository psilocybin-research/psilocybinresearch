# psilocybinresearch

Access versioned public bibliographic metadata from Psilocybin-Research.com in R.
The package verifies snapshot checksums, retains provenance and supports offline
reuse of completed downloads. It contains no account or personal data.

Install the release source archive with `install.packages("psilocybinresearch_0.1.0.tar.gz", repos = NULL, type = "source")` after installing `jsonlite` and `digest` from CRAN. This package is not on CRAN.

```r
library(psilocybinresearch)
m <- research_manifest()
download_snapshot("snapshot-001", m)
x <- read_snapshot("snapshot-001")
annual_counts(x)
snapshot_citation(x)
```

Keep the download directory, manifest and package version with your analysis.
Existing directories are never overwritten. Reopening a snapshot verifies its
checksum without a network connection. SHA-256 verifies consistency with the
selected manifest; it is not a digital signature.

The catalogue contains indexed records, not a curated collection of independent
studies or effect sizes. Articles, preprints and trial registrations may describe
the same study. Consult the dataset's rights and source metadata before reuse.

[Dataset and citation](https://psilocybin-research.com/research-dataset.php) ·
[Interactive R workspace](https://psilocybin-research.com/webr)

MIT licence applies to package code; dataset/source rights are separate.

A guided browser alternative is available at the [Shinylive research explorer](https://psilocybin-research.com/apps/research-explorer/). It uses a dated public snapshot and remains separate from this data-access package.
