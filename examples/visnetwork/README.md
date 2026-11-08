# Authors, papers and observed citations

The [Shinylive explorer](https://psilocybin-research.com/shinyapp-live) loads visNetwork only when **Build network** is requested. Its `network-example.R` editor tab contains the implementation. This standalone copy also runs in local R:

```r
install.packages(c("visNetwork", "jsonlite"))
library(psilocybinresearch)
m <- research_manifest()
download_snapshot("network-snapshot-001", m)
papers <- read_snapshot("network-snapshot-001")$publications
source("paper-network.R")
load_network_package()
seed <- papers[papers$doi == "10.1016/s2215-0366(16)30065-7" & !is.na(papers$doi), ][1, ]
graph <- paper_network(seed, papers, max_links = 8, authors_per_paper = 2)
network_widget(graph)
write.csv(graph$nodes, "nodes.csv", row.names = FALSE)
write.csv(graph$edges, "edges.csv", row.names = FALSE)
writeLines(jsonlite::toJSON(graph$provenance, auto_unbox = TRUE, pretty = TRUE), "provenance.json")
```

Arrows run from citing to cited records; dashed lines show listed authors. Names are grouped by exact display label and are not disambiguated person identities. The public API returns incomplete, capped bibliographic links. Missing edges do not imply no citation; citation does not imply agreement or evidence quality. Snapshot selection and live citation retrieval have separate provenance. Keep the exported graph and manifest because future live metadata may differ. Requires internet for package installation and live citation retrieval.

Code: MIT. visNetwork and its dependencies retain their own licences; public metadata rights remain with their sources.
