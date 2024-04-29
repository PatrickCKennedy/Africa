# PK

# Plotting PSMC results in R:

library(ggplot2)
mySouthernCameroonColour <- "#56ddc5"
mySouthAfricaColour <- "red"
myMarouaColour <- "orange"
my_ymax <- 700

# - - - - - - - - - - - - - - - -
# FUNCTION TO PRODUCE A PSMC PLOT:

my_PSMC_function <- function(my_bootstrap_values, 
                             my_nonbootstrapvalues,
                             my_bootstrap_colour,
                             my_nonboostrap_colour,
                             ymax) { 
  ggplot() +
    geom_step(data=my_bootstrap_values, 
              aes(x=V1, y=V2*10, group=V7), color=my_bootstrap_colour, alpha=1, size = 0.02) +
    geom_step(data=my_nonbootstrapvalues,
              aes(x=V1, y=V2*10, group=V7), color=my_nonboostrap_colour, alpha = 1) +
    scale_x_continuous(trans = scales::pseudo_log_trans(0.001, 10), expand=c(0,0),
                       limits=c(0, 1300000),
                       breaks = c(10000,100000,1000000),
                       labels =c("10,000","100,000","1\nmillion")
                      ) +
   scale_y_continuous(
      expand=c(0,0), limits = c(0,ymax)) +
    theme_classic(base_size = 12) +
    theme(axis.title.x = element_text(size = 12,family = "Helvetica"),
          axis.title.y = element_text(size = 12),
          axis.text.y = element_text(size = 12,color = "black"),
          axis.text = element_text(size = 12,color = "black"),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          legend.position = "none") +
    xlab("Years ago") +
    ylab(expression(paste("Effective population size (N"[e], " x", 10^{3}, ")",sep=" "))) + #can change scaling so 10^4, 10^6 etc, just also modify the scaling factor in geom_step(). psmc plot automatically outputs 10^4
    annotation_logticks(side = "b") + theme(panel.border = element_rect(color = "black",fill = NA,size = 1)) +
  coord_cartesian(xlim=c(10000, 1300000)) 
}

# ------------------------------------------------------------------------
# APPLY THE FUNCTION TO DIFFERNT DATASETS:

# Navigate to the folder containing the outputs of 'PSMC_script.sh' for each wasp:
setwd("/Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments/PSMC/")

# - - - - - - - - - - - - - - - -
# PLOTTING YAOUNDE'S PSMC:
# Import the bootstrap output values:
Yaounde_bootstrap <- read.delim("ForPSMC_A5_7_M1/species_bootstrap.txt", 
                                header=FALSE)
Yaounde_nonbootstrap <- read.delim("ForPSMC_A5_7_M1/species_nonbootstrap.txt", 
                                header=FALSE)
View(Yaounde_bootstrap)
View(Yaounde_nonbootstrap)

YaoundePSMCPlot <- my_PSMC_function(Yaounde_bootstrap,Yaounde_nonbootstrap,mySouthernCameroonColour,mySouthernCameroonColour,my_ymax)
YaoundePSMCPlot

# - - - - - - - - - - - - - - - -
# PLOTTING MAGALIESBERG'S PSMC:
# Import the bootstrap output values:
Magaliesberg_bootstrap <- read.delim("ForPSMC_BRIS_P11_c/species_bootstrap.txt", 
                                header=FALSE)
Magaliesberg_nonbootstrap <- read.delim("ForPSMC_BRIS_P11_c/species_nonbootstrap.txt", 
                                header=FALSE)

my_PSMC_function(Magaliesberg_bootstrap,Magaliesberg_nonbootstrap,mySouthAfricaColour,mySouthAfricaColour,my_ymax)

# - - - - - - - - - - - - - - - -
# PLOTTING MAROUA'S PSMC:
# Import the bootstrap output values:
Maroua_bootstrap <- read.delim("MarouaNewSpeciesWellsMerged/species_bootstrap.txt", 
                                header=FALSE)
Maroua_nonbootstrap <- read.delim("MarouaNewSpeciesWellsMerged/species_nonbootstrap.txt", 
                                header=FALSE)

MarouaPSMCPlot <- my_PSMC_function(Maroua_bootstrap,Maroua_nonbootstrap,myMarouaColour,myMarouaColour,my_ymax)
MarouaPSMCPlot

# - - - - - - - - - - - - - - - -
# PLOTTING THE PSMC WASPS TOGETHER:

junceaPSMCPlot <- MarouaPSMCPlot +
  geom_rect(aes(xmin = 14500, xmax = 23000, ymin = -Inf, ymax = Inf), fill = "brown", alpha = .2) +
  geom_vline(xintercept=150000, linetype="dotted") +
  geom_rect(fill = "white", aes(xmin = 140000,xmax = 160000,ymin = 390,ymax = 520)) +
  geom_text(aes(x=150000, y= 500, label = "Penultimate\nGlacial\nMaximum"), colour = "black", vjust = 1, size = 3) +
  geom_text(aes(x=(14500+23000)/2, y= 90, label = "Last Glacial\nAridity Maximum"), colour = "black", vjust = 1, size = 3) +
    geom_step(data=Magaliesberg_bootstrap, 
              aes(x=V1, y=V2*10, group=V7), color=mySouthAfricaColour, alpha=1, size = 0.02) +
    geom_step(data=Magaliesberg_nonbootstrap,
              aes(x=V1, y=V2*10, group=V7), color=mySouthAfricaColour, alpha = 1) +
    geom_step(data=Yaounde_bootstrap, 
              aes(x=V1, y=V2*10, group=V7), color=mySouthernCameroonColour, alpha=1, size = 0.02) +
    geom_step(data=Yaounde_nonbootstrap,
              aes(x=V1, y=V2*10, group=V7), color=mySouthernCameroonColour, alpha = 1)
 junceaPSMCPlot   


# - - - - - - - - - - - - - - - -
# PLOTTING PETIOLATA'S PSMC:
# Import the bootstrap output values:
Petiolata_bootstrap <- read.delim("LOUW19PETIO/species_bootstrap.txt", 
                                header=FALSE)
Petiolata_nonbootstrap <- read.delim("LOUW19PETIO/species_nonbootstrap.txt", 
                                header=FALSE)

PetiolataPSMCPlot <- my_PSMC_function(Petiolata_bootstrap,Petiolata_nonbootstrap,mySouthAfricaColour,mySouthAfricaColour,1000000)
PetiolataPSMCPlot

combinedPSMCPlot <- junceaPSMCPlot + geom_step(data=Petiolata_bootstrap, 
                           aes(x=V1, y=V2*10, group=V7), color="gray", alpha=1, size = 0.02) +
    geom_step(data=Petiolata_nonbootstrap,
              aes(x=V1, y=V2*10, group=V7), color="gray", alpha = 1) + 
    coord_cartesian(xlim=c(10000, 1300000), ylim=c(0, 600)) +
    theme(aspect.ratio=0.75)
combinedPSMCPlot

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "combinedPSMCPlot.svg", 
       plot = combinedPSMCPlot, 
       height = 4)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.

