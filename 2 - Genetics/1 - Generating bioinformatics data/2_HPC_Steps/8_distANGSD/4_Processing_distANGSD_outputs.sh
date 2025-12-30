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

# Root the tree:
tree_rooted <- root(tree, outgroup = "L10_e_EKDL230052134-1A_22GGMJLT3_L7.no.overlaps.bam", resolve.root = TRUE)
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



