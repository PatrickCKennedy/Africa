# The main script ('Processing_relatedness_output') is for the Belonogaster juncea samples.
# This script plots the smaller sample of B. petiolata:

PetiolataLouwsFarm <- read.delim("/Users/pk14885/Desktop/WaspCLIM_Publication_Datasets/Relatedness_datasets/petiolata_newres")
View(PetiolataLouwsFarm)

# Extract the tagging nest for each wasp (for B. petiolata, the nest ID is the 
# name before the first underscore in the wasp name):
PetiolataLouwsFarm$ida_Nest <- sub("\\_.*", "", PetiolataLouwsFarm$ida)
PetiolataLouwsFarm$idb_Nest <- sub("\\_.*", "", PetiolataLouwsFarm$idb)

# Add a new column, containing a '1' if two wasps are foundresses tagged on the same nest:
PetiolataLouwsFarm$Same_nest <- as.numeric(PetiolataLouwsFarm$ida_Nest == PetiolataLouwsFarm$idb_Nest)

# If you don't screen out comparisons with low numbers of sites in common, you get a biased estimate (i.e., they look less related 
# than they really are). Therefore, focus only on relatedness comparisons that have at least this threshold number of sites in common:
PetiolataLouwsFarm <- subset(PetiolataLouwsFarm, PetiolataLouwsFarm$nSites > 250000)

Petiolata_cofoundresses <- subset(PetiolataLouwsFarm, Same_nest == 1)
hist(Petiolata_cofoundresses$rab)

library(ggplot2)
mySouthAfricaColour <- "red"
Petiolata_plot <- ggplot(Petiolata_cofoundresses, aes(x=as.numeric(rab), fill="red")) + 
  geom_histogram(aes(y = ..density..),
                 fill = mySouthAfricaColour, 
                 alpha = 0.8, bins = 20) +
  geom_density(alpha = 0.2, adjust = 1) +
  theme_classic() + 
  labs(y= "Density", 
       x = "Co-foundress relatedness") + 
  scale_fill_manual( values = c(mySouthAfricaColour)) + 
  scale_x_continuous(limits = c(-0.07,0.9), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) + 
  geom_vline(xintercept = mean(as.numeric(Petiolata_cofoundresses$rab)), 
             linetype="dashed") + theme(legend.position = "none")
Petiolata_plot
