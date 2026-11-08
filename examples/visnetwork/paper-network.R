# Authors, papers and observed citation links.
# Requires visNetwork; installed only when the user builds a network.
# Snapshot metadata and live citation metadata are kept distinct in provenance.
network_lib <- new.env(parent = emptyenv())
load_network_package <- function() {
  package <- 'visNetwork'
  if (!requireNamespace(package, quietly = TRUE)) {
    if (!requireNamespace('webr', quietly = TRUE) || !exists('install', asNamespace('webr'), inherits = FALSE)) {
      stop('Install visNetwork in your local R library first.')
    }
    webr::install(package)
  }
  stopifnot(requireNamespace(package, quietly = TRUE))
  for (name in c('visNetwork', 'visNodes', 'visGroups', 'visEdges', 'visLayout', 'visOptions', 'visInteraction', 'visPhysics', 'visEvents', 'visNetworkOutput', 'renderVisNetwork')) network_lib[[name]] <- getExportedValue(package, name)
}

# Identify the public R client; the browser retains its native user agent.
network_json <- function(url) {
  previous <- getOption('HTTPUserAgent')
  on.exit(options(HTTPUserAgent = previous))
  if (!grepl('emscripten', R.version$platform, ignore.case = TRUE)) options(HTTPUserAgent = 'psilocybinresearch/0.1.0')
  jsonlite::fromJSON(url, simplifyVector = FALSE)
}

# Node IDs preserve publication IDs or DOI identity. Author nodes group exact
# display-name strings; they are NOT verified individual identities.
paper_network <- function(seed, catalogue, max_links = 8L, authors_per_paper = 2L) {
  stopifnot(nrow(seed) == 1L, max_links >= 1L, max_links <= 25L)
  base <- 'https://psilocybin-research.com/'
  endpoint <- paste0(base, 'api.php?resource=')
  id <- as.integer(seed$id[[1]])
  live <- network_json(paste0(endpoint, 'paper&id=', id))$paper
  normal_doi <- function(x) tolower(sub('^https?://(dx\\.)?doi\\.org/', '', if (is.null(x) || is.na(x)) '' else x))
  if (is.null(live) || normal_doi(live$doi) != normal_doi(seed$doi[[1]])) {
    stop('The live record no longer matches this snapshot. Choose another paper.')
  }
  links <- network_json(paste0(endpoint, 'citation_graph&id=', id, '&limit=', max_links))
  nodes <- list(); edges <- list()
  text <- function(x) if (is.null(x) || !length(x) || is.na(x[[1]])) '' else as.character(x[[1]])
  escape <- function(x) as.character(htmltools::htmlEscape(text(x)))
  add_node <- function(key, label, group, title, url, value = 1) {
    if (is.null(nodes[[key]])) nodes[[key]] <<- data.frame(id = key, label = label, group = group, title = title, url = url, value = value)
  }
  add_edge <- function(from, to, relation) {
    key <- paste(from, to, relation, sep = '|')
    edges[[key]] <<- data.frame(
      from = from, to = to, relation = relation,
      title = if (relation == 'cites') 'Cites (recorded bibliographic link)' else 'Listed author',
      arrows = if (relation == 'cites') 'to' else '',
      color = if (relation == 'cites') '#1a6b54' else '#bdb6a5', dashes = relation != 'cites'
    )
  }
  add_paper <- function(p, group) {
    key <- paste0('paper:', as.integer(p$id))
    title <- text(p$title); year <- text(p$publication_year)
    label <- paste(strwrap(substr(title, 1, 92), width = 25), collapse = '\n')
    if (nchar(title) > 92) label <- paste0(label, '…')
    add_node(
      key, paste0(label, if (nzchar(year)) paste0('\n', year) else ''), group,
      paste0('<b>', escape(title), '</b><br>', escape(p$authors), '<br>DOI: ', escape(p$doi)),
      paste0(base, 'publication.php?id=', as.integer(p$id)), if (group == 'Selected paper') 4 else 2
    )
    names <- unique(trimws(strsplit(text(p$authors), ',', fixed = TRUE)[[1]]))
    names <- head(names[nzchar(names) & !grepl('^(et al\\.?|\\.\\.\\.)$', names, ignore.case = TRUE)], authors_per_paper)
    for (name in names) {
      author <- paste0('author:', name)
      add_node(
        author, name, 'Author label', paste0(escape(name), '<br>Display-name label; identity not disambiguated.'),
        paste0(base, 'authors.php?author=', utils::URLencode(name, reserved = TRUE))
      )
      add_edge(author, key, 'authored')
    }
    key
  }
  root <- add_paper(as.list(seed[1, ]), 'Selected paper')
  for (p in links$citing) {
    if (is.null(p$id)) next
    key <- add_paper(p, 'Citing paper')
    add_edge(key, root, 'cites')
  }
  references <- unique(unlist(links$references, use.names = FALSE))
  for (doi in references) {
    match <- which(tolower(catalogue$doi) == normal_doi(doi))
    if (length(match)) {
      p <- as.list(catalogue[match[1], ])
      key <- paste0('paper:', as.integer(p$id))
      if (is.null(nodes[[key]])) key <- add_paper(p, 'Cited paper')
    } else {
      key <- paste0('doi:', normal_doi(doi))
      add_node(
        key, paste(strwrap(doi, width = 24), collapse = '\n'), 'Cited paper',
        paste0('Recorded DOI reference<br>', escape(doi)), paste0('https://doi.org/', utils::URLencode(doi, reserved = TRUE))
      )
    }
    add_edge(root, key, 'cites')
  }
  list(
    nodes = do.call(rbind, unname(nodes)), edges = if (length(edges)) do.call(rbind, unname(edges)) else data.frame(from = character(), to = character(), relation = character(), title = character(), arrows = character(), color = character(), dashes = logical()),
    provenance = list(
      seed_id = id, seed_title = text(seed$title), retrieved_at_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
      endpoint = paste0(endpoint, 'citation_graph&id=', id, '&limit=', max_links),
      max_links_per_direction = max_links, authors_per_paper = authors_per_paper,
      references_returned = length(references), citing_returned = length(links$citing),
      runtime = list(R = R.version.string, visNetwork = as.character(utils::packageVersion('visNetwork')), htmlwidgets = as.character(utils::packageVersion('htmlwidgets'))),
      interpretation = 'Observed partial citation metadata. Arrows run from citing to cited paper. Author nodes are exact display-name labels, not verified person identities. Missing links do not mean no citations.'
    )
  )
}

network_widget <- function(graph) {
  network_lib$visNetwork(graph$nodes, graph$edges, height = '620px', width = '100%', background = '#ffffff') |>
    network_lib$visNodes(shape = 'box', margin = 10, font = list(face = 'Roboto, Arial', size = 16, color = '#24251f'), scaling = list(min = 12, max = 25)) |>
    network_lib$visGroups(groupname = 'Selected paper', color = list(background = '#123c31', border = '#123c31'), font = list(color = '#ffffff')) |>
    network_lib$visGroups(groupname = 'Citing paper', color = list(background = '#e8efe7', border = '#1a6b54')) |>
    network_lib$visGroups(groupname = 'Cited paper', color = list(background = '#f2e1c5', border = '#bdb6a5')) |>
    network_lib$visGroups(groupname = 'Author label', shape = 'dot', color = list(background = '#ffffff', border = '#1a6b54'), size = 10) |>
    network_lib$visEdges(smooth = FALSE, width = 1.2) |>
    network_lib$visLayout(randomSeed = 42) |>
    network_lib$visOptions(highlightNearest = list(enabled = TRUE, degree = 1, hover = FALSE)) |>
    network_lib$visInteraction(hover = TRUE, tooltipDelay = 250, navigationButtons = TRUE, keyboard = TRUE) |>
    network_lib$visPhysics(stabilization = list(enabled = TRUE, iterations = 150), barnesHut = list(springLength = 170, gravitationalConstant = -3500, avoidOverlap = 0.5)) |>
    network_lib$visEvents(
      stabilizationIterationsDone = 'function(){this.setOptions({physics:false});}',
      doubleClick = 'function(p){if(p.nodes.length===1){const n=this.body.data.nodes.get(p.nodes[0]);if(n.url){const u=new URL(n.url);if(u.protocol==="https:"&&["psilocybin-research.com","doi.org"].includes(u.hostname))window.open(u.href,"_blank","noopener,noreferrer");}}}'
    )
}

# Reproduce this example after loading the provided snapshot:
# install.packages("visNetwork") # Standard R only; browser setup is on demand.
# load_network_package()
# papers <- readRDS("publications.rds")$publications
# seed <- papers[papers$id == 2511, , drop = FALSE]
# graph <- paper_network(seed, papers, max_links = 8, authors_per_paper = 2)
# network_widget(graph)
# write.csv(graph$edges, "paper-network-edges.csv", row.names = FALSE)
