library(jsonlite)
library(igraph)
library(stringr)
library(stringi)
library(sna)

# reading the json file
#out <- lapply(readLines("/Users/niloofarjebelli/Desktop/Grad/CSS/Spring 2017/Complexity Theory/GT belief propagation/GT_SNA.json"), fromJSON)

base_path = "/Users/niloofarjebelli/Desktop/plot/"
input_filename = "GT_SNA-21.json"
experiment_name = "BP__P21__NPG5__CR0_1__GFT5__T1"

input_path = file.path(base_path, experiment_name,input_filename)

out <- lapply(readLines(input_path), fromJSON)

# making an empty graph for coordination, taking data from every timestep, and adding single nodes
timestep = out[1][[1]]
grf = make_empty_graph(directed = FALSE)
for(i in 1:nrow(timestep$data)){
  v = vertex(i)
  grf = grf + v
}
# creating the graph layout on fixed coordinates
coords <- layout_with_kk(grf)
plot(grf, layout= coords)

# setting colors according to dominant belief (1=red, 2=orange, 3=brown, 4=yellow)
clrs = c("red", "orange", "brown", "yellow")

# create required directories for storing the plots
mainDir = file.path(base_path, experiment_name)
dir.create(file.path(mainDir, 'plots'), showWarnings = FALSE)
dir.create(file.path(mainDir, 'loglog'), showWarnings = FALSE)
dir.create(file.path(mainDir, 'degree'), showWarnings = FALSE)
dir.create(file.path(mainDir, 'graph'), showWarnings = FALSE)
# neighbors loop in id loop in time loop
# change id and dominant from strings to digits and sort id numerically

#sink(file.path(mainDir, 'top_degrees.txt'))
#sink()
#sink(file.path(mainDir, 'top_btw.txt'))
#sink()
#sink(file.path(mainDir, 'top_close.txt'))
#sink()
#sink(file.path(mainDir, 'top_eigen.txt'))
#sink()
#sink(file.path(mainDir, 'clustering_coef.txt'))
#sink()

for(time in 1:length(out)){
  if (time < 0) {next}
  grf = make_empty_graph(directed = FALSE)
  timestep = out[time][[1]]
  timestep$data$dominant = as.numeric(timestep$data$dominant)
  timestep$data$id = as.numeric(timestep$data$id)
  timestep$data = timestep$data[order(timestep$data$id),]
  
  # loop over the data frame to extract the id, corelate id with created nodes, set colors based on dominant belief
  for(i in 1:nrow(timestep$data)){
    row_data_id = timestep$data[i, "id"]
    v = vertex(row_data_id)
    v$color = clrs[timestep$data[i,"dominant"]]
    grf = grf + v
  }
  plot(grf, layout= coords)
  
  # loop over the data fram to extract neighbors
  for(i in 1:nrow(timestep$data)){
    row_data_id = timestep$data[i,"id"]
    row_data_neighbors = timestep$data[i,"neighbors"]
    # extract numbers from the neighbors string
    neighbors_of_id = str_extract_all(row_data_neighbors, boundary("word"), simplify = FALSE)[[1]]
    for(neighbor in neighbors_of_id){
      # add single edge between id and a neighbor
      grf = grf + edge(row_data_id, neighbor)
    }
  }
  plot(grf, layout=coords)
  
  # getting adjacency matrix to run centrality measures
  # getting the degree then degree distribution of nodes, showing results on histogram
  # getting top 5 degree, betweenness, closeness, and eigenvector centrality for every timestep and order them by the highest to the lowest
  
  adj = get.adjacency(grf)
  Degree = igraph::degree(grf)
  
  filename = paste(c(mainDir,'/degree/',stri_pad_left(time, 7, 0),'.jpg'), collapse = "")
  jpeg(filename)
  hist(Degree)
  dev.off()
  
  top_degrees = sort(names(Degree[order(Degree, decreasing=TRUE)[1:5]]))
  sink(file.path(mainDir,'top_degrees.txt'), append=TRUE)
  cat(top_degrees,sep = ",")
  cat("\n")
  sink()
  Betweenness = igraph::betweenness(grf)
  top_btw = sort(names(Betweenness[order(Betweenness, decreasing=TRUE)[1:5]]))
  sink(file.path(mainDir,'top_btw.txt'), append=TRUE)
  cat(top_btw,sep = ",")
  cat("\n")
  sink()
  
  Closeness = igraph::closeness(grf)
  top_close = sort(names(Closeness[order(Closeness, decreasing=TRUE)[1:5]]))
  sink(file.path(mainDir,'top_close.txt'), append=TRUE)
  cat(top_close,sep = ",")
  cat("\n")
  sink()
  
  Eigenvector = igraph::eigen_centrality(grf)$vector
  top_eigen = sort(names(Eigenvector[order(Eigenvector, decreasing=TRUE)[1:5]]))
  sink(file.path(mainDir,'top_eigen.txt'), append=TRUE)
  cat(top_eigen,sep = ",")
  cat("\n")
  sink()
  
  # getting the clustering coefficient
  sink(file.path(mainDir,'clustering_coef.txt'), append=TRUE)
  cat(transitivity(grf))
  cat("\n")
  sink()
  # getting average shortest path
  sink(file.path(mainDir,'avg_shortest.txt'), append=TRUE)
  cat(mean_distance(grf, unconnected = TRUE))
  cat("\n")
  sink()
  # getting a log-log plot for power-law test
  filename = paste(c(mainDir,'/loglog/',stri_pad_left(time, 7, 0),'.jpg'), collapse = "")
  occur = as.vector(table(Degree))
  occur = occur/sum(occur)
  p = occur/sum(occur)
  y = rev(cumsum(rev(p)))
  x = as.numeric(names(table(Degree)))
  jpeg(filename)
  plot(x, y, log="xy", type="l", xlab='Log Degree', ylab="Log Frequency")
  dev.off()
  
  # plotting and exporting the graphs
  filename = paste(c(mainDir,'/graph/',stri_pad_left(time, 7, 0),'.jpg'), collapse = "")
  jpeg(filename)
  plot(grf, layout = coords)
  dev.off()
  
  gc()
}
