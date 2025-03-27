# PK

# Plotting demographic history in R after completing StairwayPlot on SFS:

library(ggplot2)
library(dplyr)
mySouthernCameroonColour <- "#56ddc5"
mySouthAfricaColour <- "red"
myMarouaColour <- "orange"
my_ymax <- 700
my_xmin <- 1000

# -------------------------------------------------------------------------
# Navigate to the folder containing the StairwayPlot results:
setwd("~/stairway_plot_v2.1.1/")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# SOUTH-EAST CAMEROON (THE YAOUNDE POPULATIONS PLUS SOMALOMO):
# 17 randomly-chosen nonrelatives from Yaounde1, Soa, Messa, and Somalomo

# Import the chosen population's StairwayPlot result (filename ends in ".final.summary"):
SE_Cameroon.final <- read.delim("~/stairway_plot_v2.1.1/Results_downloaded_from_running_StairwayPlot_on_BluePebble/stairway_plot_v2.1.1/Cameroon/Cameroon.final.summary", header=TRUE)

SE_Cameroon.Plot <- ggplot(SE_Cameroon.final) + 
  geom_rect(aes(xmin = year, xmax = lead(year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = mySouthernCameroonColour, alpha = .2) + 
  geom_step(aes(x = year, y = Ne_median), color = mySouthernCameroonColour, lwd = 0.8) +
  scale_x_continuous(trans = scales::pseudo_log_trans(0.001, 10), expand=c(0,0),
                     limits=c(0, 1300000),
                     breaks = c(1000,10000,100000,1000000),
                     labels =c("1000","10,000","100,000","1\nmillion")) + 
  scale_y_continuous(
    expand=c(0,0)) +
  theme_classic(base_size = 12) +
  theme(axis.title.x = element_text(size = 12,family = "Helvetica"),
        axis.title.y = element_text(size = 12),
        axis.text.y = element_text(size = 12,color = "black"),
        axis.text = element_text(size = 12,color = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.position = "none") +
  xlab("Years ago") +
  ylab(expression(paste("Effective population size"))) + #can change scaling so 10^4, 10^6 etc, just also modify the scaling factor in geom_step(). psmc plot automatically outputs 10^4
  annotation_logticks(side = "b") + theme(panel.border = element_rect(color = "black",fill = NA,size = 1)) +
  coord_cartesian(xlim=c(my_xmin, 1500000)) 
SE_Cameroon.Plot

SE_Cameroon.Plot_with_annotations <- SE_Cameroon.Plot +
  annotate("rect", xmin = 14500, xmax = 23000, ymin = 0, ymax = Inf, fill = "brown", alpha = .2) +
  geom_vline(xintercept=150000, linetype="dotted") +
  annotate("rect", xmin = 140000,xmax = 160000, ymin = 7500000,ymax = 10500000, fill = "white", alpha = 1) +
  annotate("text", x=150000, y= 9000000, label = "Penultimate\nGlacial\nMaximum", size = 3) +
  annotate("text", x=(14500+23000)/2, y= 1800000, label = "Last Glacial\nAridity Maximum", size = 3)
SE_Cameroon.Plot_with_annotations

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "SE_Cameroon.Plot_with_annotations.svg", 
       plot = SE_Cameroon.Plot_with_annotations, 
       height = 4)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# MAROUA PLOT:

# Import the chosen population's StairwayPlot result (filename ends in ".final.summary"):
# The Maroua StairwayPlot run was on BluePebble, and the results have been download to the local computer here:
Maroua.final <- read.delim("~/stairway_plot_v2.1.1/Results_downloaded_from_running_StairwayPlot_on_BluePebble/stairway_plot_v2.1.1/Maroua/Maroua.final.summary", header=TRUE)

MarouaStairwayPlot <- ggplot(Maroua.final) + 
  geom_rect(aes(xmin = year, xmax = lead(year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = "orange", alpha = .2) + 
  geom_step(aes(x = year, y = Ne_median), color = "orange", lwd = 1.5) +
  scale_x_continuous(trans = scales::pseudo_log_trans(0.001, 10), expand=c(0,0),
                     limits=c(0, 1300000),
                     breaks = c(10000,100000,1000000),
                     labels =c("10,000","100,000","1\nmillion")) + 
  scale_y_continuous(
    expand=c(0,0)) +
  theme_classic(base_size = 12) +
  theme(axis.title.x = element_text(size = 12,family = "Helvetica"),
        axis.title.y = element_text(size = 12),
        axis.text.y = element_text(size = 12,color = "black"),
        axis.text = element_text(size = 12,color = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.position = "none") +
  xlab("Years ago") +
  ylab(expression(paste("Effective population size"))) + #can change scaling so 10^4, 10^6 etc, just also modify the scaling factor in geom_step(). psmc plot automatically outputs 10^4
  annotation_logticks(side = "b") + theme(panel.border = element_rect(color = "black",fill = NA,size = 1)) +
  coord_cartesian(xlim=c(my_xmin, 1300000)) 
MarouaStairwayPlot


MarouaStairwayPlot +
  geom_rect(aes(xmin = 14500, xmax = 23000, ymin = -Inf, ymax = Inf), fill = "brown", alpha = .005) +
  geom_vline(xintercept=150000, linetype="dotted") +
  geom_rect(fill = "white", aes(xmin = 140000,xmax = 160000,ymin = 390,ymax = 520)) +
  geom_text(aes(x=150000, y= 9000000, label = "Penultimate\nGlacial\nMaximum"), colour = "black", vjust = 1, size = 3) +
  geom_text(aes(x=(14500+23000)/2, y= 90, label = "Last Glacial\nAridity Maximum"), colour = "black", vjust = 1, size = 3)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# SOUTH AFRICA PLOT:

# Import the chosen population's StairwayPlot result (filename ends in ".final.summary"):
# The South Africa StairwayPlot run was on BluePebble, and the results have been download to the local computer here:
SouthAfrica.final <- read.delim("~/stairway_plot_v2.1.1/Results_downloaded_from_running_StairwayPlot_on_BluePebble/stairway_plot_v2.1.1/SouthAfrica/SouthAfrica.final.summary", header=TRUE)

SouthAfricaStairwayPlot <- ggplot(SouthAfrica.final) + 
  geom_rect(aes(xmin = year, xmax = lead(year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = mySouthAfricaColour, alpha = .2) + 
  geom_step(aes(x = year, y = Ne_median), color = mySouthAfricaColour, lwd = 1) +
  scale_x_continuous(trans = scales::pseudo_log_trans(0.001, 10), expand=c(0,0),
                     limits=c(0, 1300000),
                     breaks = c(1000,10000,100000,1000000),
                     labels =c("1000","10,000","100,000","1\nmillion")) + 
  scale_y_continuous(
    expand=c(0,0)) +
  theme_classic(base_size = 12) +
  theme(axis.title.x = element_text(size = 12,family = "Helvetica"),
        axis.title.y = element_text(size = 12),
        axis.text.y = element_text(size = 12,color = "black"),
        axis.text = element_text(size = 12,color = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.position = "none") +
  xlab("Years ago") +
  ylab(expression(paste("Effective population size"))) + #can change scaling so 10^4, 10^6 etc, just also modify the scaling factor in geom_step(). psmc plot automatically outputs 10^4
  annotation_logticks(side = "b") + theme(panel.border = element_rect(color = "black",fill = NA,size = 1)) +
  coord_cartesian(xlim=c(my_xmin, 2000000)) 
SouthAfricaStairwayPlot

SouthAfricaStairwayPlot +
  annotate("rect", xmin = 14500, xmax = 23000, ymin = 0, ymax = Inf, fill = "brown", alpha = .2) +
  geom_vline(xintercept=150000, linetype="dotted") +
  annotate("rect", xmin = 140000,xmax = 160000, ymin = 7500000,ymax = 10500000, fill = "white", alpha = 1) +
  annotate("text", x=150000, y= 9000000, label = "Penultimate\nGlacial\nMaximum", size = 3) +
  annotate("text", x=(14500+23000)/2, y= 1800000, label = "Last Glacial\nAridity Maximum", size = 3)


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PLOTTING ALL THREE TOGETHER:

SouthAfricaStairwayPlot +
  geom_rect(data = Maroua.final, aes(xmin = year, xmax = lead(year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = "orange", alpha = .2) + 
  geom_step(data = Maroua.final, aes(x = year, y = Ne_median), color = "orange", lwd = 0.8) +
  geom_rect(data = SE_Cameroon.final, aes(xmin = year, xmax = lead(year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = mySouthernCameroonColour, alpha = .2) + 
  geom_step(data = SE_Cameroon.final, aes(x = year, y = Ne_median), color = mySouthernCameroonColour, lwd = 0.8) 

# As you can see, the plots are misaligned: the dip at about 150,000 years ago in
# the SE_Cameroon data is placed earlier in Marou and earlier still in South Africa.
# This is due to the generations per year estimates we provide during the Stairway_Plot run (in the 
# 'blueprint' file), which were 7 months for Cameroon (based on empirical data
# by Tindo et al.), i.e. 0.583, and 1 year for South Africa (given that they
# are strictly annual in the temperate zone), i.e. 1. However, these values are
# correct for today's wasps, but in the distant past, when these wasps' ancestors
# were a single population, the generation times were different to today (and
# the same value for all ancestors, as the ancestors are the same). If you open the
# PDF figures generated by Stairway_Plot (in the output files produced by a Stairway_Plot
# run), you will see the data presented with year on the lower axes but generation
# on the upper axis. Here, therefore, we convert all the figures back into simple
# numbers of generations:

SouthAfricaStairwayPlot +
  geom_rect(data = Maroua.final, aes(xmin = year, xmax = lead(year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = "orange", alpha = .5) + 
  geom_step(data = Maroua.final, aes(x = year, y = Ne_median), color = "orange", lwd = 1.5) +
  geom_rect(data = SE_Cameroon.final, aes(xmin = (1/0.583)*year, xmax = lead((1/0.583)*year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = mySouthernCameroonColour, alpha = .5) + 
  geom_step(data = SE_Cameroon.final, aes(x = (1/0.583)*year, y = Ne_median), color = mySouthernCameroonColour, lwd = 1.5) +
  annotate("rect", xmin = 14500, xmax = 23000, ymin = 0, ymax = Inf, fill = "brown", alpha = .2) +
  geom_vline(xintercept=150000, linetype="dotted") +
  annotate("rect", xmin = 140000,xmax = 160000, ymin = 7500000,ymax = 10500000, fill = "white", alpha = 1) +
  annotate("text", x=150000, y= 9000000, label = "Penultimate\nGlacial\nMaximum", size = 3) +
  annotate("text", x=(14500+23000)/2, y= 1800000, label = "Last Glacial\nAridity Maximum", size = 3)

SouthAfricaStairwayPlot +
  geom_rect(data = Maroua.final, aes(xmin = year, xmax = lead(year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = "orange", alpha = .5) + 
  geom_step(data = Maroua.final, aes(x = year, y = Ne_median), color = "orange", lwd = 1.5) +
  geom_rect(data = SE_Cameroon.final, aes(xmin = (1/0.583)*year, xmax = lead((1/0.583)*year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = mySouthernCameroonColour, alpha = .5) + 
  geom_step(data = SE_Cameroon.final, aes(x = (1/0.583)*year, y = Ne_median), color = mySouthernCameroonColour, lwd = 1.5) 

SE_Cameroon.Plot +
  geom_rect(data = SouthAfrica.final, aes(xmin = 0.45*year, xmax = lead(0.45*year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = mySouthAfricaColour, alpha = .2) + 
  geom_step(data = SouthAfrica.final, aes(x = 0.45*year, y = Ne_median), color = mySouthAfricaColour, lwd = 0.8) +
  geom_rect(data = Maroua.final, aes(xmin = year, xmax = lead(year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = "orange", alpha = .5) + 
  geom_step(data = Maroua.final, aes(x = year, y = Ne_median), color = "orange", lwd = 1.5) 
  
SE_Cameroon.Plot +
  geom_rect(data = SouthAfrica.final, aes(xmin = 0.45*year, xmax = lead(0.45*year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = mySouthAfricaColour, alpha = .2) + 
  geom_step(data = SouthAfrica.final, aes(x = 0.45*year, y = Ne_median), color = mySouthAfricaColour, lwd = 0.8) +
  geom_rect(data = Maroua.final, aes(xmin = 0.45*year, xmax = lead(0.45*year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = "orange", alpha = .5) + 
  geom_step(data = Maroua.final, aes(x = 0.45*year, y = Ne_median), color = "orange", lwd = 1.5) 

combinedplot_with_hypothetically_aligned_PGP_spike <- SE_Cameroon.Plot +
    geom_rect(data = SouthAfrica.final, aes(xmin = 0.45*year, xmax = lead(0.45*year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = mySouthAfricaColour, alpha = .1) + 
    geom_step(data = SouthAfrica.final, aes(x = 0.45*year, y = Ne_median), color = mySouthAfricaColour, lwd = 0.8) +
    geom_rect(data = Maroua.final, aes(xmin = 0.583*year, xmax = lead(0.583*year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = "orange", alpha = .2) + 
    geom_step(data = Maroua.final, aes(x = 0.583*year, y = Ne_median), color = "orange", lwd = 0.8) 

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "combinedplot_with_hypothetically_aligned_PGP_spike.svg", 
       plot = combinedplot_with_hypothetically_aligned_PGP_spike, 
       height = 4)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.
