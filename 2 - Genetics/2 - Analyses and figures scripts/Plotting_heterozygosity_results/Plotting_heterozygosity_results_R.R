# PK

# Import the heterozygosity results (which can be found in the SUPMAT file):
library(readxl)
Estimated_heterozygosity_table <- read_excel("Desktop/WaspCLIM_Publication_Datasets/Estimated_heterozygosity_table.xlsx")
View(Estimated_heterozygosity_table)

# Exclude samples with very low coverage (fewer than 50 million sites):
mydata <- subset(Estimated_heterozygosity_table,`P:Sum_Sites` > 50000000)

# -----------------------------------------------------------------------------------
# PLOT THE FIGURE:

# Load libraries:
library(ggplot2)
library(cowplot)
library(ggpol)

# Plot the resulting boxplot (following https://github.com/erocoar/ggpol) for inbreeding coefficients:
myColors <- c("#56ddc5","orange","red","gray")
myfontsize <- 10
heterozygosity_plot <- ggplot(mydata) + 
    geom_boxjitter(aes(x = Climate, 
                       y = `P:Heterozygosity`, 
                       fill = Climate),
                   jitter.shape = 21, 
                   jitter.color = NA, 
                   jitter.alpha = 0.5,
                   jitter.size = 0.5,
                   jitter.params = list(height = 0, width = 0.09),
                   outlier.color = 1, outlier.fill = 1, outlier.shape = 21,
                   errorbar.draw = TRUE) + 
    scale_fill_manual(values = myColors) +
    scale_x_discrete(labels=c("Humid\ntropics","Semi-arid","Temperate","B. petiolata")) +
    theme_cowplot(font_size = myfontsize) + 
    labs(y= "Heterozygosity", 
         x = "Climate") + 
    theme(legend.position="none") + 
    theme(axis.line.x.bottom=element_line(size=0.5)) +
    theme(axis.line.y.left=element_line(size=0.5)) +
    theme(axis.text.x = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"),
          axis.text.y = element_text(color = "black", size = myfontsize, angle = 0, hjust = 1, vjust = 0, face = "plain"),  
          axis.title.x = element_text(color = "black", size = myfontsize, angle = 0, hjust = .5, vjust = 0, face = "plain"),
          axis.title.y = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"))
heterozygosity_plot

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "heterozygosity_plot.svg", 
       plot = heterozygosity_plot, 
       height = 5,
       width = 2.5, dpi = 200)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.






