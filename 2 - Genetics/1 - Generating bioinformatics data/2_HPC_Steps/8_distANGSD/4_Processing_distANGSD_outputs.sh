# PROCESSING THE OUTPUTS OF distANGSD (GENETIC DISTANCES)

# -------------------------------------------------------------------------------------
# DOWNLOADING THE RESULTS FROM BLUEPEBBLE

# Once the array job in script 3 has completed, download the output file from the local computer:
scp pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/results/distances.all.tsv Downloads/

# -------------------------------------------------------------------------------------
# PLOTTING THE TREE IN R

library(ape)
library(tidyverse)
library(ggtree)
library(phytools)

# Import the tsv file into R:
df <- read.delim("~/Downloads/distances.all.tsv")
View(df)

# Rename the columns:
colnames(df) <- c("Sample1", "Sample2", "OutPrefix", "Model", "Method", "Distance", "p_inv")

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

# Convert the matrix into a 'dist' object:
dist_obj <- as.dist(mat)

# Plot a simple tree using base R:
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
                            cladeA <- c("L18_c_EKDL230052134-1A_22GGMJLT3_L7.no.overlaps.bam",
                                        "L9_g_EKDL230052134-1A_22GGMJLT3_L7.no.overlaps.bam")
                            cladeB <- c("A4_20_3_CKDL230013284-1A_2235HJLT3_L6.no.overlaps.bam",
                                        "PR1_S1_CKDL220030022-1A_HK7J7DSX5.no.overlaps.bam")
                            
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
                        
# Import the sequencing data (this is available as the sheet "SUPMAT - lcWGS_sequences_table" in the Supplementary Material):
library(readxl)
Sequencing_data <- read_excel("Downloads/Sequencing_data.xlsx")
View(Sequencing_data)     

# Extract tip labels:
tips <- tree_rooted_and_ladderised$tip.label

# Create a clean metadata table with columns: label (matches tip labels), population
metadata <- Sequencing_data %>%
  select(`BAM file`, Population) %>%
  rename(label = `BAM file`,
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
)
