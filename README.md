# psilocybinresearch

Access versioned public bibliographic metadata from Psilocybin-Research.com in R.
The package verifies snapshot checksums, retains provenance and supports offline
reuse of completed downloads. It contains no account or personal data.

Requires R 4.1 or later. Install from the project’s source-package repository (not CRAN); required dependencies are retrieved automatically from CRAN:

```r
install.packages(
  "psilocybinresearch",
  repos = c("https://psilocybin-research.com/r-repo", "https://cloud.r-project.org"),
  type = "source"
)
library(psilocybinresearch)

m <- research_manifest()
download_snapshot("snapshot-001", m)
x <- read_snapshot("snapshot-001")
annual_counts(x)
snapshot_citation(x)
```

Source installation of missing dependencies requires suitable build tools (Rtools on Windows; command-line developer tools on macOS). The package itself contains no compiled code. The [version-pinned GitHub archive](https://github.com/psilocybin-research/psilocybinresearch/releases/download/v0.1.0/psilocybinresearch_0.1.0.tar.gz) remains available for reproducible installation.

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

A guided browser alternative is available at the [Shinylive research explorer](https://psilocybin-research.com/shinyapp-live). It uses a dated public snapshot and remains separate from this data-access package.

An optional [visNetwork example](examples/visnetwork/) links authors, papers and observed citations, with graph exports and separate snapshot/live-query provenance.

Maintainer: Christopher B. Germann <christopher.germann@uni-wh.de>.
Alternate project contact: <info@psilocybin-research.com>.
