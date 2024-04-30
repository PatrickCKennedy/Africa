# PK

# Plotting demographic history in R after completing StairwayPlot on SFS:

library(ggplot2)
mySouthernCameroonColour <- "#56ddc5"
mySouthAfricaColour <- "red"
myMarouaColour <- "orange"
my_ymax <- 700

# -------------------------------------------------------------------------
# Navigate to the folder containing the StairwayPlot results:
setwd("~/stairway_plot_v2.1.1/")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# SOA PLOT:

# Import the chosen population's StairwayPlot result (filename ends in ".final.summary"):
Soa.final <- read.delim("~/stairway_plot_v2.1.1/Soa/Soa.final.summary", header=TRUE)

SoaStairwayPlot <- ggplot(Soa.final) + 
    geom_rect(aes(xmin = year, xmax = lead(year), ymin = Ne_2.5., ymax = Ne_97.5.), fill = mySouthernCameroonColour, alpha = .2) + 
    geom_step(aes(x = year, y = Ne_median), color = mySouthernCameroonColour, lwd = 1.5) +
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
  coord_cartesian(xlim=c(2000, 1300000)) 
SoaStairwayPlot


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# MAROUA PLOT:

# Import the chosen population's StairwayPlot result (filename ends in ".final.summary"):
Maroua.final <- read.delim("~/stairway_plot_v2.1.1/Maroua/Maroua.final.summary", header=TRUE)





SoaStairwayPlot +
  geom_rect(aes(xmin = 14500, xmax = 23000, ymin = -Inf, ymax = Inf), fill = "brown", alpha = .2) +
  geom_vline(xintercept=150000, linetype="dotted") +
  geom_rect(fill = "white", aes(xmin = 140000,xmax = 160000,ymin = 390,ymax = 520)) +
  geom_text(aes(x=150000, y= 500, label = "Penultimate\nGlacial\nMaximum"), colour = "black", vjust = 1, size = 3) +
  geom_text(aes(x=(14500+23000)/2, y= 90, label = "Last Glacial\nAridity Maximum"), colour = "black", vjust = 1, size = 3)




