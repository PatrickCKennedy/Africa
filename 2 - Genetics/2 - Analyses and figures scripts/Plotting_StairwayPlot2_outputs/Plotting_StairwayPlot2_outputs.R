# PK
# PLOTTING THE OUTPUT OF STAIRWAYPLOT2 TO SHOW DEMOGRAPHIC HISTORY

# You should already have used StairwayPlot2 to generate the 
# POPULATION-NAME-HERE.final.summary file within its own folder inside
# the 'stairway_plot_v2.1.1' folder on the local computer.

# ----------------------------------------------------------------------------
# IMPORT DATA TO R:

# First, import that final file into R:
Soa.final <- read.delim("~/stairway_plot_v2.1.1/Soa/Soa.final.summary")

# For all analyses below, the dataframe is called 'data'. Rename the input table 
# as 'data' and make sure it is in dataframe format:
data <- as.data.frame(Soa.final)

# ----------------------------------------------------------------------------
# PLOT CHANGES THROUGH TIME:

# Load libraries:
library(ggplot2)
library(dplyr)

# Plot the last million years:
ggplot(data, aes(year)) + 
  geom_line(aes(y = Ne_median), colour = "turquoise") + 
  geom_line(aes(y = Ne_2.5.), colour = "white") + 
  geom_line(aes(y = Ne_97.5.), colour = "white") +  
  geom_ribbon(data = data, aes(x = year, ymin = Ne_12.5., ymax = Ne_87.5.),
              fill = "turquoise", alpha = 0.2) +
  geom_ribbon(data = data, aes(x = year, ymin = Ne_2.5., ymax = Ne_97.5.),
              fill = "turquoise", alpha = 0.2) +
  theme_classic() +
  scale_x_log10( #set limits, breaks, labels however you please
    limits=c(100, 1000000),
    breaks = c(100, 1000, 10000,100000,1000000),
    labels = c("100", "1,000","10,000","100,000","1 million")) +
  scale_y_continuous(expand = c(0, 0)) +
  theme_classic(base_size = 12) +
  theme(axis.title.x = element_text(size = 12,family = "Helvetica"),
        axis.title.y = element_text(size = 12),
        axis.text.y = element_text(size = 12,color = "black"),
        axis.text = element_text(size = 12,color = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.position = "none") +
  xlab("Years ago") +
  ylab(expression(paste("Effective population size (N"[e], ")",sep=" "))) + #can change scaling so 10^4, 10^6 etc, just also modify the scaling factor in geom_step(). psmc plot automatically outputs 10^4
  annotation_logticks(side = "b") + 
  theme(panel.border = element_rect(color = "black",fill = NA,size = 1)) +
  annotate("rect", xmin = 14500, xmax = 22000, ymin = -10, ymax = 6000000,
           alpha = 0.1) +
  annotate("rect", xmin = 135000, xmax = 194000, ymin = -10, ymax = 6000000,
           alpha = 0.1)



# Plot the last 20,000 years:
ggplot(data, aes(year)) + 
  geom_line(aes(y = Ne_median), colour = "turquoise") + 
  geom_line(aes(y = Ne_2.5.), colour = "white") + 
  geom_line(aes(y = Ne_97.5.), colour = "white") +  
  geom_ribbon(data = data, aes(x = year, ymin = Ne_2.5., ymax = Ne_97.5.),
              fill = "turquoise", alpha = 0.2) +
  theme_classic() +
  scale_x_continuous(trans='log10', limits = c(100,10000)) +
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
  annotation_logticks(side = "b") + theme(panel.border = element_rect(color = "black",fill = NA,size = 1))

# I think it might be worthwhile to plot global temperatures on the graph.
# You can get an excellent dataset here: https://www.temperaturerecord.org/#sources






