.check_url <- function(url) {
  if (length(url) != 1L || is.na(url) || !grepl("^https://[^/@]+/", url)) stop("Use a public HTTPS URL")
  url
}
.retrieve <- function(url, path) {
  .check_url(url)
  old <- getOption("HTTPUserAgent"); options(HTTPUserAgent = "psilocybinresearch/0.1.1")
  on.exit(options(HTTPUserAgent = old))
  status <- utils::download.file(url, path, method = "libcurl", mode = "wb", quiet = TRUE)
  if (status != 0L || file.info(path)$size > 128 * 1024^2) stop("Download failed or exceeds 128 MiB")
  invisible(path)
}
.validate_manifest <- function(x) {
  if (!isTRUE(x$complete) || !is.character(x$snapshot_id) || length(x$snapshot_id) != 1L ||
      !grepl("^[a-f0-9]{64}$", x$snapshot_id) || !is.numeric(x$record_count) ||
      length(x$record_count) != 1L || x$record_count < 0 || is.null(x$artifacts$rds)) stop("Invalid or incomplete snapshot manifest")
  x
}
research_manifest <- function(url = "https://psilocybin-research.com/dataset-manifest.json") {
  path <- tempfile(fileext = ".json"); on.exit(unlink(path))
  .retrieve(url, path)
  .validate_manifest(jsonlite::fromJSON(path, simplifyVector = FALSE))
}
download_snapshot <- function(directory, manifest = research_manifest()) {
  manifest <- .validate_manifest(manifest)
  if (length(directory) != 1L || dir.exists(directory) || file.exists(directory)) stop("Choose a new directory; existing files are never overwritten")
  parent <- dirname(directory); if (!dir.exists(parent)) stop("Parent directory does not exist")
  stage <- tempfile(".research-snapshot-", tmpdir = parent); dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE))
  a <- manifest$artifacts$rds
  origin <- sub("^(https://[^/]+).*$", "\\1", manifest$manifest_url)
  if (!is.character(a$url) || !startsWith(a$url, paste0(origin, "/dataset-download.php?")) ||
      !grepl(paste0("snapshot=", manifest$snapshot_id), a$url, fixed = TRUE) ||
      !grepl("format=rds", a$url, fixed = TRUE) || !identical(a$record_count, manifest$record_count) ||
      !is.character(a$sha256) || !grepl("^[a-f0-9]{64}$", a$sha256)) stop("Invalid snapshot artifact")
  path <- file.path(stage, "publications.rds"); .retrieve(a$url, path)
  if (file.info(path)$size != a$bytes || digest::digest(file = path, algo = "sha256") != a$sha256) stop("Snapshot checksum or size mismatch")
  jsonlite::write_json(manifest, file.path(stage, "dataset-manifest.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
  read_snapshot(stage)
  if (!file.rename(stage, directory)) stop("Cannot commit complete snapshot directory")
  invisible(normalizePath(directory))
}
read_snapshot <- function(directory) {
  m <- .validate_manifest(jsonlite::fromJSON(file.path(directory, "dataset-manifest.json"), simplifyVector = FALSE))
  path <- file.path(directory, "publications.rds")
  if (digest::digest(file = path, algo = "sha256") != m$artifacts$rds$sha256) stop("Snapshot checksum mismatch")
  data <- readRDS(path)
  if (!is.list(data) || !is.data.frame(data$publications) || !all(c("id", "publication_year", "publication_status") %in% names(data$publications)) ||
      nrow(data$publications) != m$record_count || anyDuplicated(data$publications$id)) stop("Snapshot structure/count mismatch")
  attr(data, "snapshot_manifest") <- m
  data
}
annual_counts <- function(data) {
  papers <- if (is.data.frame(data)) data else data$publications
  if (!is.data.frame(papers) || !"publication_year" %in% names(papers)) stop("Provide catalogue publications")
  years <- sort(unique(papers$publication_year[!is.na(papers$publication_year)]), decreasing = TRUE)
  out <- data.frame(year = c(years, NA_integer_), records = vapply(c(years, NA_integer_), function(y) {
    if (is.na(y)) sum(is.na(papers$publication_year)) else sum(papers$publication_year == y, na.rm = TRUE)
  }, integer(1)))
  rownames(out) <- NULL
  out
}
snapshot_citation <- function(data) {
  m <- attr(data, "snapshot_manifest")
  if (is.null(m)) stop("Use read_snapshot() to retain provenance")
  sprintf("Psilocybin-Research.com public research catalogue. Snapshot %s; generated %s; %s records. %s. Retain the manifest and its artifact checksums. Indexed records are not independent studies.", m$snapshot_id, m$generated_at_utc, m$record_count, m$manifest_url)
}
