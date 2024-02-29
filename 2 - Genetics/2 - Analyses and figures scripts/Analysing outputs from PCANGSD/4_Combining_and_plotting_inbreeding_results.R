# PK
# This R script plots takes the inbreeding coefficients from the Cameroon results and the South African
# results, and plots them together in ggplot.

# It requires already having completed the following two scripts on BluePebble:
      # 3a_PCANGSD_in_Cameroon_only.sh
      # 4a_PCANGSD_in_South_Africa_only.sh

# You must then have downloaded the resulting folders from BluePebble to the local computer. They are:
      # juncea_PCANGSD_results_for_Cameroon_ONLY
      # juncea_PCANGSD_results_for_SouthAfrica_ONLY

# -----------------------------------------------------------------------------------
# (1) IMPORT THE INBREEDING COEFFICIENTS FOR THE SELECTED CAMEROONIAN NONRELATIVES:

# Set folder to the downloaded Cameroon results:
setwd("/Users/pk14885/Downloads/juncea_PCANGSD_results_for_Cameroon_ONLY")

# Import the inbreeding coefficients:
Cameroon_inbreeding_coefficients <- as.matrix(read.table("Cameroon_ONLY.output.inbreeding_per_individual.pcangsd.inbreed.samples"), header=F)

# Import the wasp ID names for these wasps:
Cameroon_WaspNameList <- as.matrix(read.table("Cameroon_ONLY.WaspNameList"), header=F)

# Import the population labels for these wasps:
Cameroon_PopulationLabels <- as.matrix(read.table("Cameroon_ONLY.PopulationLabels"), header=F)

# Combine the inbreeding coefficients, wasp IDs, and population labels:
Cameroon_inbreeding_dataset <- cbind(Cameroon_inbreeding_coefficients,
                                     Cameroon_WaspNameList,
                                     Cameroon_PopulationLabels)

# -----------------------------------------------------------------------------------
# (2) IMPORT THE INBREEDING COEFFICIENTS FOR THE SELECTED SOUTH AFRICAN NONRELATIVES:

# Set folder to the downloaded Cameroon results:
setwd("/Users/pk14885/Downloads/juncea_PCANGSD_results_for_SouthAfrica_ONLY")

# Import the inbreeding coefficients:
SouthAfrica_inbreeding_coefficients <- as.matrix(read.table("SouthAfrica_ONLY.output.inbreeding_per_individual.pcangsd.inbreed.samples"), header=F)

# Import the wasp ID names for these wasps:
SouthAfrica_WaspNameList <- as.matrix(read.table("SouthAfrica_ONLY.WaspNameList"), header=F)

# Import the population labels for these wasps:
SouthAfrica_PopulationLabels <- as.matrix(read.table("SouthAfrica_ONLY.PopulationLabels"), header=F)

# Combine the inbreeding coefficients, wasp IDs, and population labels:
SouthAfrica_inbreeding_dataset <- cbind(SouthAfrica_inbreeding_coefficients,
                                     SouthAfrica_WaspNameList,
                                     SouthAfrica_PopulationLabels)

# -----------------------------------------------------------------------------------
# (3) COMBINE THE CAMEROONIAN AND SOUTH AFRICAN DATASETS:

Combined_inbreeding_dataset <- rbind(Cameroon_inbreeding_dataset,SouthAfrica_inbreeding_dataset)
colnames(Combined_inbreeding_dataset) <- c("inbreeding_coefficient","WaspID","PopulationLabels")
View(Combined_inbreeding_dataset)

# Add climate zone information to a fourth column:
        Combined_inbreeding_dataset <- as.data.frame(Combined_inbreeding_dataset)
        Combined_inbreeding_dataset$V4 <- NA
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Douala",4] = "Humid tropics"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Maroua",4] = "Semi arid"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Mbouda",4] = "Humid tropics"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Messa",4] = "Humid tropics"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Soa",4] = "Humid tropics"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Douala",4] = "Humid tropics"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Somalomo",4] = "Humid tropics"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Yaounde1",4] = "Humid tropics"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "AfricanLaboratory",4] = "Temperate"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "LoversRock",4] = "Temperate"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Cowshed",4] = "Temperate"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "PeterRobertsFarm",4] = "Temperate"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Pumphouse",4] = "Temperate"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "TrudiesFarm",4] = "Temperate"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "Vusumuzi",4] = "Temperate"
        Combined_inbreeding_dataset[Combined_inbreeding_dataset$PopulationLabels == "ZebraHouse",4] = "Temperate"
        colnames(Combined_inbreeding_dataset)[4] <- "Climate"

# Make sure that the inbreeding coefficients are in numerical format:
Combined_inbreeding_dataset$inbreeding_coefficient <- as.numeric(Combined_inbreeding_dataset$inbreeding_coefficient)

# -----------------------------------------------------------------------------------
# (4) PLOT THE FIGURE:

# Load libraries:
library(ggplot2)
library(cowplot)
library(ggpol)

# Plot the resulting boxplot (following https://github.com/erocoar/ggpol) for inbreeding coefficients:
myColors <- c("#56ddc5","orange","red","gray")
myfontsize <- 10
my_inbreeding_plot <- ggplot(Combined_inbreeding_dataset) + 
    geom_boxjitter(aes(x = Climate, 
                       y = inbreeding_coefficient, 
                       fill = Climate),
                   jitter.shape = 21, 
                   jitter.color = NA, 
                   jitter.alpha = 0.5,
                   jitter.size = 0.5,
                   jitter.params = list(height = 0, width = 0.09),
                   outlier.color = 1, outlier.fill = 1, outlier.shape = 21,
                   errorbar.draw = TRUE) + 
    scale_fill_manual(values = myColors) +
    scale_x_discrete(labels=c("Humid\ntropics","Semi-arid","Temperate")) +
    scale_y_continuous(breaks=c(-0.4, -0.2, 0, 0.2, 0.4, 0.6, 0.8)) + 
    theme_cowplot(font_size = myfontsize) + 
    labs(y= "Inbreeding coefficient", 
         x = "Climate") + 
    theme(legend.position="none") + 
    theme(axis.line.x.bottom=element_line(size=0.5)) +
    theme(axis.line.y.left=element_line(size=0.5)) +
    theme(axis.text.x = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"),
          axis.text.y = element_text(color = "black", size = myfontsize, angle = 0, hjust = 1, vjust = 0, face = "plain"),  
          axis.title.x = element_text(color = "black", size = myfontsize, angle = 0, hjust = .5, vjust = 0, face = "plain"),
          axis.title.y = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"))
my_inbreeding_plot


