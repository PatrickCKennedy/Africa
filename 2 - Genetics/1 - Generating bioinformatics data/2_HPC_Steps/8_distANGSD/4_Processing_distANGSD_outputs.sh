# PROCESSING THE OUTPUTS OF distANGSD (GENETIC DISTANCES)

# -------------------------------------------------------------------------------------
# DOWNLOADING THE RESULTS FROM BLUEPEBBLE

# Once the array job in script 3 has completed, download the output file from the local computer:
##scp pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/results/distances.all.tsv Downloads/

# Download the run summary table by running this in the terminal:
##scp pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/results/pair_summaries.all.tsv Downloads/

# -------------------------------------------------------------------------------------
# PLOTTING THE TREE IN R

library(ape)
library(tidyverse)
library(ggtree)
library(phytools)

# -------------------------------------------------------------------------------------
# IMPORT THE NECESSARY FILES

# Import the tsv file into R:
setwd("/Users/pk14885")
df <- read.delim("~/Downloads/distances.all.tsv")
View(df)

# Import the sequencing data (this is available as the sheet "SUPMAT - lcWGS_sequences_table" in the Supplementary Material):
library(readxl)
Sequencing_data <- read_excel("Downloads/Sequencing_data.xlsx")
View(Sequencing_data)     

# Import the summary tsv file into R:
summarytable <- read.delim("~/Downloads/pair_summaries.all.tsv")
View(summarytable)

# -------------------------------------------------------------------------------------

# Rename the columns:
colnames(df) <- c("Sample1", "Sample2", "OutPrefix", "Model", "Method", "Distance", "p_inv")

      # Rename the BAM files with the more concise wasp names:
      idx_for_sample1 <- match(df$Sample1, Sequencing_data$`BAM file`)
      df$Sample1[!is.na(idx_for_sample1)] <- Sequencing_data$Sequencing_machine_sample_name[idx_for_sample1[!is.na(idx_for_sample1)]]
      idx_for_sample2 <- match(df$Sample2, Sequencing_data$`BAM file`)
      df$Sample2[!is.na(idx_for_sample2)] <- Sequencing_data$Sequencing_machine_sample_name[idx_for_sample2[!is.na(idx_for_sample2)]]

# Generate a list of all the individual wasps in the tree:
samples <- unique(c(df$Sample1, df$Sample2))

# Set up an empty square matrix to be filled in:
mat <- matrix(0, nrow=length(samples), ncol=length(samples), dimnames=list(samples, samples))

# Fill the distances into the matrix:
for (i in 1:nrow(df)) {
  s1 <- df$Sample1[i]
  s2 <- df$Sample2[i]
  d  <- as.numeric(df$Distance[i])
  mat[s1, s2] <- d
  mat[s2, s1] <- d
}

# View the matrix:
image(1:ncol(mat), 1:nrow(mat), t(mat), col = terrain.colors(60), axes = FALSE)

# ---------------
# DROP POOR QUALITY SAMPLES BASED ON TOTAL SITES SHARED

# Add BAM sample names to the summary table as new columns:
basename(summarytable$A) -> summarytable$A_name
basename(summarytable$B) -> summarytable$B_name


      # Rename the BAM files with the more concise wasp names:
      idx_for_sample1 <- match(summarytable$A_name, Sequencing_data$`BAM file`)
      summarytable$A_name[!is.na(idx_for_sample1)] <- Sequencing_data$Sequencing_machine_sample_name[idx_for_sample1[!is.na(idx_for_sample1)]]
      idx_for_sample2 <- match(summarytable$B_name, Sequencing_data$`BAM file`)
      summarytable$B_name[!is.na(idx_for_sample2)] <- Sequencing_data$Sequencing_machine_sample_name[idx_for_sample2[!is.na(idx_for_sample2)]]


# Set up an empty square matrix to be filled in:
summary_mat <- matrix(0, nrow=length(samples), ncol=length(samples), dimnames=list(samples, samples))

# Fill the distances into the matrix:
for (i in 1:nrow(df)) {
  s1 <- summarytable$A_name[i]
  s2 <- summarytable$B_name[i]
  d  <- as.numeric(summarytable$total_sites[i])
  summary_mat[s1, s2] <- d
  summary_mat[s2, s1] <- d
}

# View the matrix:
image(1:ncol(summary_mat), 1:nrow(summary_mat), t(summary_mat), col = terrain.colors(60), axes = FALSE)

# Calculate average total_sites for each sample:
mean_total_sites_for_each_wasp <- as.data.frame(rowMeans(summary_mat))
View(mean_total_sites_for_each_wasp)

# Rename the columns:
mean_total_sites_for_each_wasp <- cbind(rownames(mean_total_sites_for_each_wasp), 
                                        data.frame(mean_total_sites_for_each_wasp, 
                                        row.names=NULL))
names(mean_total_sites_for_each_wasp)[names(mean_total_sites_for_each_wasp) == 'rownames(mean_total_sites_for_each_wasp)'] <- 'SampleName'
names(mean_total_sites_for_each_wasp)[names(mean_total_sites_for_each_wasp) == 'rowMeans.summary_mat.'] <- 'total_sites'

# To exclude poor quality samples, set the minimum total_sites threshold for wasps to be retained in the tree:
minimum_threshold_for_total_sites = 16000000
mean_total_sites_for_each_wasp$Keep <- ifelse(mean_total_sites_for_each_wasp$total_sites > minimum_threshold_for_total_sites, 1, 0)

# However, we keep the petiolata wasps to serve as an outgroup regardless of their total_sites:
mean_total_sites_for_each_wasp[mean_total_sites_for_each_wasp$SampleName=="L10_e","Keep"]=1
mean_total_sites_for_each_wasp[mean_total_sites_for_each_wasp$SampleName=="L12_c","Keep"]=1
mean_total_sites_for_each_wasp[mean_total_sites_for_each_wasp$SampleName=="L18_c","Keep"]=1
mean_total_sites_for_each_wasp[mean_total_sites_for_each_wasp$SampleName=="L9_g","Keep"]=1
mean_total_sites_for_each_wasp[mean_total_sites_for_each_wasp$SampleName=="L9_h","Keep"]=1

# That will retain the following number of wasps for the tree:
sum(mean_total_sites_for_each_wasp$Keep)

# The higher-quality samples to keep are therefore:
wasps_to_keep <- subset(mean_total_sites_for_each_wasp, Keep == 1, select=c(SampleName))

# Among the retained wasps, the average depth was:

# Keep only those wasps in the matrix:
mat_filtered <- mat[wasps_to_keep$SampleName, wasps_to_keep$SampleName, drop = FALSE]

# View the matrix:
image(1:ncol(mat_filtered), 1:nrow(mat_filtered), t(mat_filtered), col = terrain.colors(60), axes = FALSE)

# -------------------------------------------------------------------------------------
# PREPARE THE DATA FOR INPUTTING TO ggTREE

# Convert the matrix into a 'dist' object:
dist_obj <- as.dist(mat_filtered)

# Plot a simple tree using base R as a quick check before moving to ggTree:
tree <- nj(dist_obj)   # Neighbor-Joining
plot(tree, main="Phylogenetic Tree from distANGSD distances")

# -------------------------------------------------------------------------------------
# PLOTTING THE TREE WITH ggTREE

# Plot the tree using ggtree:

# 4) Plot with ggtree
p <- ggtree(tree) +
  geom_tiplab(size = 3) +
  ggtitle("Phylogenetic tree from distANGSD t-distances") +
  theme_tree2()  # adds x-axis scale

print(p)

 # Rooting the tree between B. juncea and B. petiolata:
 
                            # Define the two species clades:
                            cladeA <- c("L9_g", "L18_c")
                            cladeB <- c("T16_L4","C2_14_1")
                            
                            # Get MRCA nodes
                            nodeA <- getMRCA(tree, cladeA)
                            nodeB <- getMRCA(tree, cladeB)
                            
                            # Midpoint reroot between these nodes
                            midpoint_root <- function(tree, nodeA, nodeB) {
                              path <- nodepath(tree, nodeA, nodeB)
                              edges <- sapply(seq_along(path[-length(path)]), function(i)
                                which(apply(tree$edge, 1, function(e) all(e %in% path[i:(i+1)]))))
                              lengths <- ifelse(is.null(tree$edge.length), rep(1, length(edges)), tree$edge.length[edges])
                              half <- sum(lengths) / 2
                              cum <- 0
                              for (i in seq_along(edges)) {
                                cum <- cum + lengths[i]
                                if (cum >= half) {
                                  child <- tree$edge[edges[i], 2]
                                  pos <- cum - half
                                  return(reroot(tree, node = child, position = pos))
                                }
                              }
                            }
                            
                            tree_rooted <- midpoint_root(tree, nodeA, nodeB)
                            tree_rooted_and_ladderised <- ladderize(tree_rooted)
                        
# Extract tip labels:
tips <- tree_rooted_and_ladderised$tip.label

# Create a clean metadata table with columns: label (matches tip labels), population
metadata <- Sequencing_data %>%
     select(Sequencing_machine_sample_name, Population) %>%
     rename(label = Sequencing_machine_sample_name,
            population = Population) %>%
     mutate(label = as.character(label),
           population = as.character(population))

# Add the climate zone information:
library(dplyr)
metadata <- metadata %>%
  mutate(climate = case_when(
    population %in% c("AfricanLaboratory", "PeterRobertsFarm", "Vusumuzi", "Cowshed", "LoversRock", "TrudiesFarm", "Pumphouse", "ZebraHouse") ~ "South_Africa",
    population %in% c("Soa", "Yaounde1", "Somalomo", "Mbouda", "Douala", "Messa", "Population") ~ "Southern_Cameroon",
    population %in% c("LouwsFarm") ~ "Petiolata_LouwsFarm",
    population == "Maroua" ~ "Northern_Cameroon",
    TRUE ~ NA_character_  # For any populations not listed
  ))

# Take a look at the metadata table:
View(metadata)

# Plot the ggtree:
p <- ggtree(tree_rooted_and_ladderised, layout = "circular", size = 0.2, aes(color = climate)) %<+% metadata +
    geom_tippoint(aes(color = climate), size = 1) 
p + geom_treescale(x = 0, y = 200, width = 0.1) 
myColors <- c("#56ddc5","red")
p <- p + scale_color_manual(values = c(
    "South_Africa" = "red",
    "Southern_Cameroon" = "#56ddc5",
    "Northern_Cameroon" = "orange"
))
p
p <- p + theme(legend.position = "none")
p

# To add tip labels:
p + geom_tiplab2(
    aes(label = label, color = climate),   # color labels by climate if desired
    size = 2,                            # text size
    align = FALSE,                          # draw guide lines from tip to label
    linetype = "dotted"
)

# Since genetic distances can be inflated at low-coverage, plot the same tree without branch lengths:
q <- ggtree(tree_rooted_and_ladderised, branch.length = "none", layout = "circular", size = 0.2, aes(color = climate)) %<+% metadata +
    geom_tippoint(aes(color = climate), size = 1) 
q <- q + geom_tree(size = 0.2, aes(color = NULL), color = "grey70")
myColors <- c("#56ddc5","red")
q <- q + scale_color_manual(values = c(
    "South_Africa" = "red",
    "Southern_Cameroon" = "#56ddc5",
    "Northern_Cameroon" = "orange"
))
q
q <- q + theme(legend.position = "none")
q

# To add tip labels:
q + geom_tiplab2(
    aes(label = label, color = climate),   # color labels by climate if desired
    size = 2.5,                            # text size
    offset = 0.3,                          # radial offset from the tips
    align = TRUE,                          # draw guide lines from tip to label
    linetype = "dotted"
) + xlim(0,50)
