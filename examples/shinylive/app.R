library(shiny)
# A verified public snapshot is bundled at export time; no account data is used.
research <- readRDS('publications.rds')
papers <- research$publications
manifest <- jsonlite::fromJSON('dataset-manifest.json')
ui <- fluidPage(
 tags$script(HTML("document.addEventListener('click',async function(e){const a=e.target.closest('a#download');if(!a||!a.href||a.classList.contains('disabled'))return;e.preventDefault();e.stopImmediatePropagation();if(a.dataset.busy)return;a.dataset.busy='1';const label=a.textContent;a.setAttribute('aria-busy','true');a.textContent='Preparing CSV\u2026';try{const r=await fetch(a.href);if(!r.ok)throw Error('CSV export failed.');const blob=await r.blob();if((blob.type||'').includes('text/html'))throw Error('CSV export is not ready. Please try again.');const url=URL.createObjectURL(blob),link=document.createElement('a');link.href=url;link.download='psilocybin-research-filtered.csv';document.body.append(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),30000);}catch(error){window.alert(error.message);}finally{delete a.dataset.busy;a.removeAttribute('aria-busy');a.textContent=label;}},true);\n")),
 tags$head(tags$title('Psilocybin Research — R explorer'),tags$style(HTML('body{background:#faf6ef;color:#102139;font-family:Arial,sans-serif}.container-fluid{max-width:1250px;margin:auto;padding:25px}h1{font-weight:300}a{color:#123c31}.well{background:#fff;border:1px solid #d7d7cb;border-radius:12px}.btn{border-radius:8px}.shiny-output-error-validation{color:#626c64}'))),
 tags$p(tags$a(href='https://psilocybin-research.com/','Psilocybin-Research.com'),' · ',tags$a(href='https://psilocybin-research.com/webr','Custom R workspace')),
 titlePanel('Research explorer'),
 p('Explore public bibliographic metadata using R and Shiny in your browser. This alternative uses a bundled, dated snapshot.'),
 sidebarLayout(sidebarPanel(
 textInput('query','Title or author',''),
 selectInput('topic','Topic',choices=c('All',sort(unique(trimws(unlist(strsplit(na.omit(papers$topic_tags),',',fixed=TRUE))))))),
 selectInput('status','Record type',choices=c('All',sort(unique(na.omit(papers$publication_status))))),
 sliderInput('years','Publication year',min=min(papers$publication_year,na.rm=TRUE),max=max(papers$publication_year,na.rm=TRUE),value=range(papers$publication_year,na.rm=TRUE),sep=''),
 checkboxInput('undated','Include records with no year',FALSE),
 downloadButton('download','Download filtered CSV'),
 tags$hr(),tags$p('Indexed records are not independent studies. Registrations, preprints and articles may describe the same study.'),
 tags$p(paste('Snapshot:',manifest$generated_at_utc)),tags$details(tags$summary('Snapshot provenance'),tags$pre(style='white-space:pre-wrap;overflow-wrap:anywhere',manifest$snapshot_id),tags$a(href=manifest$manifest_url,'Source manifest'))
 ),mainPanel(textOutput('count'),plotOutput('trend',height='350px'),tableOutput('records')))
)
server <- function(input,output,session){
 selected <- reactive({
  d<-papers;yr<-d$publication_year;keep<-(!is.na(yr)&yr>=input$years[1]&yr<=input$years[2])|(input$undated&is.na(yr))
  if(input$status!='All')keep<-keep&!is.na(d$publication_status)&d$publication_status==input$status
  if(input$topic!='All')keep<-keep&vapply(strsplit(ifelse(is.na(d$topic_tags),'',d$topic_tags),',',fixed=TRUE),function(tags)input$topic%in%trimws(tags),logical(1))
  q<-trimws(input$query);if(nzchar(q)){field<-paste(d$title,if('authors'%in%names(d))d$authors else '');keep<-keep&grepl(tolower(q),tolower(field),fixed=TRUE)}
  d[which(keep),,drop=FALSE]
 })
 output$count<-renderText(paste(format(nrow(selected()),big.mark=','),'matching records; table shows up to 100.'))
 output$trend<-renderPlot({d<-selected();validate(need(nrow(d)>0,'No matching records.'));x<-table(d$publication_year);validate(need(length(x)>0,'No dated records.'));barplot(x,col='#123c31',border=NA,las=2,ylab='Indexed records',xlab='Publication year')},res=120)
 output$records<-renderTable({d<-selected();cols<-intersect(c('publication_year','title','publication_status','doi'),names(d));head(d[,cols,drop=FALSE],100)},striped=TRUE,spacing='s')
 output$download<-downloadHandler(filename=function()'psilocybin-research-filtered.csv',content=function(file)write.csv(selected(),file,row.names=FALSE,na=''))
}
shinyApp(ui,server)
