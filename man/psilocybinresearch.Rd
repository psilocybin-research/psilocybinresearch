\name{psilocybinresearch}
\alias{research_manifest}\alias{download_snapshot}\alias{read_snapshot}\alias{annual_counts}\alias{snapshot_citation}
\title{Verified public research catalogue snapshots}
\description{Access rights-safe public bibliographic metadata with explicit snapshot provenance. No account is required.}
\usage{
research_manifest(url = "https://psilocybin-research.com/dataset-manifest.json")
download_snapshot(directory, manifest = research_manifest())
read_snapshot(directory)
annual_counts(data)
snapshot_citation(data)
}
\arguments{\item{url}{Public HTTPS manifest URL.}\item{directory}{Snapshot directory. Downloads require a new directory with an existing parent.}\item{manifest}{A completed manifest returned by research_manifest().}\item{data}{Verified snapshot list returned by read_snapshot(), or (annual_counts only) a publications data frame.}}
\value{research_manifest returns a list; download_snapshot returns the saved path invisibly; read_snapshot returns the RDS list with a snapshot_manifest attribute; annual_counts returns year and records columns, including an explicit missing-year category; snapshot_citation returns citation text.}
\details{Artifacts are checked against manifest byte counts and SHA-256 digests before reading. Checksums establish consistency with the selected manifest, not independent authenticity. RDS is downloaded only from the manifest's HTTPS origin and pinned snapshot URL. Save completed directories for reproducibility and offline R use. Existing downloads are never overwritten. Catalogue records can include preprints, registrations and articles describing the same study. Counts are not effect sizes, participants or independent studies. Source rights and limitations remain in the dataset metadata.}
\examples{
annual_counts(data.frame(publication_year = c(2025L, 2025L, NA_integer_)))
\dontrun{
m <- research_manifest()
download_snapshot("snapshot-001", m)
x <- read_snapshot("snapshot-001")
annual_counts(x)
snapshot_citation(x)
}}
