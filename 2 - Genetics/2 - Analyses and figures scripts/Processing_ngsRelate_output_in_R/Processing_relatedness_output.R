# Patrick Kennedy
# -----------------------------------------------------------------------------
library(report)

# PROCESSING AND PLOTTING THE RELATEDNESS OUTPUTS FROM ngsRELATE:

# -----------------------------------------------------------------------------
# WHAT THIS SCRIPT DOES:

# This R script (running on the local computer) processes the results of 
# ngsRelate. Before running it, you should have completed the 'Relatedness_on_HPC.sh'
# script for each population of interest (on BluePebble). The result is an
# output file called 'newres' (one for each population), which contains the pairwise
# relatedness values between everyone within that population. In this R script,
# we download these 'newres' files from BluePebble, and plot the results.

# -----------------------------------------------------------------------------
# IMPORT THE DATA TO R:

# Combine all the 'newres' files into one:
setwd("/Users/pk14885/Desktop/WaspCLIM_Publication_Datasets")
SA.2023 <- read.delim("Relatedness_datasets/SA.Dec2023.newres")
Soa.2023 <- read.delim("Relatedness_datasets/Soa.Dec2023.newres")
Messa.2023 <- read.delim("Relatedness_datasets/Messa.Dec2023.newres")
Yaounde1.2023 <- read.delim("Relatedness_datasets/Yaounde1.Dec2023.newres")
Somalomo.2023 <- read.delim("Relatedness_datasets/Somalomo.Dec2023.newres")
Maroua.2023 <- read.delim("Relatedness_datasets/Maroua.Dec2023.newres")
Mbouda.2023 <- read.delim("Relatedness_datasets/Mbouda.Dec2023.newres")
All_newres <- rbind(SA.2023, 
                    Soa.2023, 
                    Messa.2023, 
                    Yaounde1.2023, 
                    Somalomo.2023,
                    Maroua.2023,
                    Mbouda.2023)

# Because 'All_newres' is a concatenation of several 'newres' speadsheets, some of the rows
# contain the headers. Remove these rows:
All_newres <- All_newres[!(All_newres$ida=="ida"),]

# For clarity, keep only the following columns:
All <- cbind(All_newres$ida,
             All_newres$idb,
             All_newres$nSites,
             All_newres$rab,       # RAB pairwise relatedness estimate
             All_newres$Fa,        # Fa: The inbreeding coefficient estimated for individual a (P: estimated separately in each pairwise comparison, presumably because nSites differs)
             All_newres$Fb,        # Fb: The inbreeding coefficient estimated for individual b
             All_newres$KING       # KING-robust relatedness estimate
)        
# The column names vanish when you do cbind. Therefore, add them back in:
colnames(All) <- cbind("ida",
                       "idb",
                       "nSites",
                       "rab",
                       "Fa",
                       "Fb",
                       "KING")

# Make sure that the 'All' data is a dataframe:
All <- as.data.frame(All)

# -----------------------------------------------------------------------------
# KING-ROBUST RELATEDNESS:

# KING-robust relatedness is also provided in the newres outputs. It can be particularly
# useful when there is population structure.

# The scale of KING-robust is -0.5 to +0.5, where clones have +0.5. To convert
# to the same scale as RAB, we just multiply KING-robust by two (e.g., https://www.mv.helsinki.fi/home/mjxpirin/GWAS_course/material/GWAS5.html)

All$KING <- as.numeric(All$KING)
All$KING_multiplied_by_2 <- All$KING*2

# KING also gives negative relatednesses. To put all relatednesses into a 
# scale that matches RAB, we censor the negative values to zero in the column:
All$KING_multiplied_by_2[All$KING_multiplied_by_2<0] <- 0

# -----------------------------------------------------------------------------

# Plot a histogram of how many sites are in common for each pairwise comparison:
All$nSites <- as.numeric(All$nSites)
hist(All$nSites)

# Some pairwise comparisons have very few sites in common, so their estimates are likely to
# be inaccurate. Drop these comparisons from the dataset:
my_nSites_threshold = 250000
All <- subset(All, All$nSites > my_nSites_threshold)

# Calculate the average number of sites used in each pairwise relatedness calculation:
mean(as.numeric(All_newres$nSites))
mean(as.numeric(All$nSites))

# And the standard deviation is:
sd(as.numeric(All_newres$nSites))
sd(as.numeric(All$nSites))

# -----------------------------------------------------------------------------
# PROVIDE THE TAGGING INFORMATION FOR EACH SAMPLE:

# The tagging information for each BAM file is contained in the master spreadsheet for
# tracking the BAM files, which is in the Supplementary Material Excel file, under the
# tab 'SUPMAT - lcWGS_sequences_table'. Manually Copy-paste the contents of that tab
# tab into a new Excel file and import it to R as 'temp_BAM_list':
library(readxl)
temp_BAM_list <- read_excel("lcWGS_sequences_table_temp_to_import_to_R.xlsx")

# - - - - - - - - - - - - - - - - - - - - - - - -

# PREVENTING DUPLICATE SAMPLES:

# Some wasps were sequenced more than once, so they have two (or three) BAM files.
# Here, remove any duplicate samples (by finding the duplicate
# BAM rows in the 'temp_BAM_file' dataframe):
temp_BAM_list <- subset(temp_BAM_list, temp_BAM_list$`Main sample or backup` == "Main sample")

# - - - - - - - - - - - - - - - - - - - - - - - -

# From that file, extract the columns of interest:
WaspIDlist <- cbind(temp_BAM_list$`BAM file`,
                    temp_BAM_list$Country,
                    temp_BAM_list$Population,
                    temp_BAM_list$SpecificAggregation,
                    temp_BAM_list$WaspID,
                    temp_BAM_list$Wasp.type,
                    temp_BAM_list$Stage_if_brood,
                    temp_BAM_list$Tagging_nest_if_foundress,
                    temp_BAM_list$Nest_if_brood)

# Name those three columns:
colnames(WaspIDlist) <- cbind("BAM",
                              "Country",
                              "Population",
                              "SpecificAggregation",
                              "WaspID",
                              "Wasp_type",
                              "Stage_if_brood",
                              "Tagging_nest_if_foundress",
                              "Nest_if_brood")

# -----------------------------------------------------------------------------
# EXTRACT THE RELEVANT INFORMATION ONLY, USING BOTH INPUT FILES ABOVE:

# 'Merge' is R's version of VLOOKUP. The following adds all the information about each sample
# in the temp_BAM_list to the relevant lines in the 'All' dataset.

# Because that VLOOKUP ('merge') was focused on the 'ida' wasp, rename the columns to make this clear:
All <- merge(All, WaspIDlist, by.x="idb", by.y = "BAM")

# And similarly rename the new columns with the "idb_" prefix:
colnames(All)[colnames(All) == 'Country'] <- 'idb_Country'
colnames(All)[colnames(All) == 'Population'] <- 'idb_Population'
colnames(All)[colnames(All) == 'WaspID'] <- 'idb_WaspID'
colnames(All)[colnames(All) == 'Tagging_nest_if_foundress'] <- 'idb_Tagging_nest_if_foundress'

# Now do a VLOOKUP ('merge') for the ida wasp:
All <- merge(All, WaspIDlist, by.x="ida", by.y = "BAM")

colnames(All)[colnames(All) == 'Country'] <- 'ida_Country'
colnames(All)[colnames(All) == 'Population'] <- 'ida_Population'
colnames(All)[colnames(All) == 'WaspID'] <- 'ida_WaspID'
colnames(All)[colnames(All) == 'Tagging_nest_if_foundress'] <- 'ida_Tagging_nest_if_foundress'

# Not really necessary, but reorder columns alphabetically, so that the ida wasp comes
# before the idb wasp visually. Just to make it easier to view:
All <- All[, sort(colnames(All))]

# Make sure that relatednesses are in numeric format:
All$rab <- as.numeric(All$rab)

# -----------------------------------------------------------------------------
# IDENTIFY WHICH PAIRWISE RELATEDNESSES ARE BETWEEN COFOUNDRESSES:

# Add a new column, containing a '1' if two wasps are foundresses tagged on the same nest:
All$Same_nest <- as.numeric(All$ida_Tagging_nest_if_foundress == All$idb_Tagging_nest_if_foundress)

# -----------------------------------------------------------------------------
# FOCUS ON THE COFOUNDRESSES:

# Focus on the cofoundresses only:
Cofoundresses_data <- subset(All, Same_nest == 1 & Wasp_type.x == 'F' & Wasp_type.y == 'F')

# Make sure that the relatedness column is in 'numeric' format (as some entries that are in scientific notation
# will otherwise be missed out):
Cofoundresses_data$rab <- as.numeric(Cofoundresses_data$rab)

# Focus on the South African cofoundresses only:
SouthAfrican_cofoundresses <- subset(Cofoundresses_data, ida_Country == "SouthAfrica")
mean(as.numeric((SouthAfrican_cofoundresses$rab)))
sd(as.numeric((SouthAfrican_cofoundresses$rab)))
hist(as.numeric((SouthAfrican_cofoundresses$rab)))

# Focus on the Cameroonian cofoundresses only:
Cameroon_cofoundresses <- subset(Cofoundresses_data, ida_Country == "Cameroon")
mean(as.numeric((Cameroon_cofoundresses$rab)))
sd(as.numeric((Cameroon_cofoundresses$rab)))
hist(as.numeric((Cameroon_cofoundresses$rab)))

# ----------------------------------------------------------------------
# PLOT BOXPLOT COMPARING SOUTH AFRICA AND CAMEROON:

# Load the libraries:
library(ggplot2)
library(ggthemes)
library(ggpol)
library(cowplot)

my_x_variable <-  as.factor(Cofoundresses_data$ida_Country)
my_y_variable <-  as.numeric(Cofoundresses_data$rab)
my_color_variable <- Cofoundresses_data$ida_Country

myColors <- c("#56ddc5","red")

myfontsize <- 10

# Generate boxplots (following https://github.com/erocoar/ggpol):
my_plot <- ggplot(Cofoundresses_data) + 
  geom_boxjitter(aes(x = my_x_variable, 
                     y = my_y_variable, 
                     fill = my_color_variable),
                 jitter.shape = 21, 
                 jitter.color = NA, 
                 jitter.alpha = 0.5,
                 jitter.size = 0.5,
                 jitter.params = list(height = 0, width = 0.09),
                 outlier.color = 1, outlier.fill = 1, outlier.shape = 21, outlier.size = 0.5,
                 errorbar.draw = TRUE) + 
  scale_fill_manual(values = myColors) +
  scale_x_discrete(labels=c("Humid\ntropics","Temperate")) +
  theme_cowplot(font_size = myfontsize) + 
  labs(y= "Relatedness", 
       x = "Climate") + 
  theme(legend.position="none") + 
  theme(axis.line.x.bottom=element_line(size=0.5)) +
  theme(axis.line.y.left=element_line(size=0.5)) +
  theme(axis.text.x = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"),
        axis.text.y = element_text(color = "black", size = myfontsize, angle = 0, hjust = 1, vjust = 0, face = "plain"),  
        axis.title.x = element_text(color = "black", size = myfontsize, angle = 0, hjust = .5, vjust = 0, face = "plain"),
        axis.title.y = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"))
my_plot

# -----------------------------------------------------------------------------
# DENSITY PLOTS:

myCameroonColour <- "#56ddc5"
mySouthAfricaColour <- "red"

# Cameroon only:
Cameroon_plot <- ggplot(Cameroon_cofoundresses, aes(x=as.numeric(rab), fill=ida_Country)) + 
  geom_histogram(aes(y = ..density..),
                 fill = myCameroonColour, 
                 alpha = 0.8, bins = 20) +
  geom_density(alpha = 0.4, adjust = 0.1) +
  theme_cowplot(font_size = myfontsize) + 
  labs(y= "Density", 
       x = "Co-foundress relatedness (pairwise)") + 
  scale_fill_manual( values = c(myCameroonColour)) + 
  scale_x_continuous(limits = c(-0.03,0.9), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0,10,by = 5),expand = c(0, 0)) + 
  geom_vline(xintercept = mean(as.numeric(Cameroon_cofoundresses$rab)), 
             linetype="dashed") + theme(legend.position = "none")
Cameroon_plot

# South Africa only:
SA_plot <- ggplot(SouthAfrican_cofoundresses, aes(x=as.numeric(rab), fill=ida_Country)) + 
  geom_histogram(aes(y = ..density..),
                 fill = mySouthAfricaColour, 
                 alpha = 0.8, bins =20) +
  geom_density(alpha = 0.2, adjust = 1.5) +
  theme_cowplot(font_size = myfontsize) + 
  labs(y= "Density", 
       x = "Co-foundress relatedness (pairwise)") + 
  scale_fill_manual( values = c(mySouthAfricaColour)) + 
  scale_x_continuous(limits = c(-0.03,0.9), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0,15,by = 5),expand = c(0, 0)) + 
  geom_vline(xintercept = mean(as.numeric(SouthAfrican_cofoundresses$rab)), 
             linetype="dashed") + theme(legend.position = "none")
SA_plot

# Plot both plots as panels:
library(gridExtra)
grid.arrange(SA_plot,Cameroon_plot)

# Mean relatednesses in each country:
mean(as.numeric(SouthAfrican_cofoundresses$rab))
sd(as.numeric(SouthAfrican_cofoundresses$rab))

mean(as.numeric(Cameroon_cofoundresses$rab))
sd(as.numeric(Cameroon_cofoundresses$rab))

# South Africa cofoundresses, showing separate densities for each population:
SA_plot2 <- ggplot(SouthAfrican_cofoundresses, aes(x=as.numeric(rab), fill=ida_Population)) +
  geom_density(alpha = 0.5, adjust = 0.8, lty = "solid") +
  theme_classic() + 
  labs(y= "Density", 
       x = "Co-foundress relatedness") + 
  scale_x_continuous(limits = c(0,0.9), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))
SA_plot2

# Cameroonian cofoundresses, showing separate densities for each population:
Cameroon_plot2 <- ggplot(Cameroon_cofoundresses, aes(x=as.numeric(rab),  fill=ida_Population)) +
  geom_density(alpha = 0.5, adjust = 0.4, lty = "solid") +
  theme_classic() + 
  labs(y= "Density", 
       x = "Co-foundress relatedness") + 
  scale_x_continuous(limits = c(0,0.9), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))
Cameroon_plot2

# Plot both plots as panels:
library(gridExtra)
grid.arrange(SA_plot2,Cameroon_plot2)

# -----------------------------------------------------------------------------
# COMBINE PLOTS FOR PUBLICATION IN PANEL:

# Generate panel:
library("cowplot")
my_output_panel <- ggdraw() +
  draw_plot(my_plot,  x=0, y=0, width= .3, height=1) +
  draw_plot(Cameroon_plot,  x=.3, y=0, width= .7, height=.5) +
  draw_plot(SA_plot,  x=.3, y=.5, width= .7, height=.5)

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "my_output_panel.svg", 
       plot = my_output_panel, 
       height = 2.5,
       width = 5, dpi = 200)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.

# -----------------------------------------------------------------------------
# FOR COMPLETENESS, HERE IS THE SAME PANEL USING THE KING-ROBUST ESTIMATOR INSTEAD OF THE RAB PAIRWISE RELATEDNESS ESTIMATOR:

# Generate boxplots (following https://github.com/erocoar/ggpol):
my_plot_KING <- ggplot(Cofoundresses_data) + 
  geom_boxjitter(aes(x = my_x_variable, 
                     y = KING_multiplied_by_2, 
                     fill = my_color_variable),
                 jitter.shape = 21, 
                 jitter.color = NA, 
                 jitter.alpha = 0.5,
                 jitter.size = 0.5,
                 jitter.params = list(height = 0, width = 0.09),
                 outlier.color = 1, outlier.fill = 1, outlier.shape = 21, outlier.size = 0.5,
                 errorbar.draw = TRUE) + 
  scale_fill_manual(values = myColors) +
  scale_x_discrete(labels=c("Humid\ntropics","Temperate")) +
  theme_cowplot(font_size = myfontsize) + 
  labs(y= "Relatedness", 
       x = "Climate") + 
  theme(legend.position="none") + 
  theme(axis.line.x.bottom=element_line(size=0.5)) +
  theme(axis.line.y.left=element_line(size=0.5)) +
  theme(axis.text.x = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"),
        axis.text.y = element_text(color = "black", size = myfontsize, angle = 0, hjust = 1, vjust = 0, face = "plain"),  
        axis.title.x = element_text(color = "black", size = myfontsize, angle = 0, hjust = .5, vjust = 0, face = "plain"),
        axis.title.y = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"))
my_plot_KING

# Cameroon only:
Cameroon_plot_KING <- ggplot(Cameroon_cofoundresses, aes(x=as.numeric(KING_multiplied_by_2), fill=ida_Country)) + 
  geom_histogram(aes(y = ..density..),
                 fill = myCameroonColour, 
                 alpha = 0.8, bins = 20) +
  geom_density(alpha = 0.4, adjust = 0.3) +
  theme_cowplot(font_size = myfontsize) + 
  labs(y= "Density", 
       x = "Co-foundress relatedness (KING-robust)") + 
  scale_fill_manual( values = c(myCameroonColour)) + 
  scale_x_continuous(limits = c(-0.03,0.9), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0,10,by = 5),expand = c(0, 0)) + 
  geom_vline(xintercept = mean(as.numeric(Cameroon_cofoundresses$KING_multiplied_by_2)), 
             linetype="dashed") + theme(legend.position = "none")
Cameroon_plot_KING

# South Africa only:
SA_plot_KING <- ggplot(SouthAfrican_cofoundresses, aes(x=as.numeric(KING_multiplied_by_2), fill=ida_Country)) + 
  geom_histogram(aes(y = ..density..),
                 fill = mySouthAfricaColour, 
                 alpha = 0.8, bins = 30) +
  geom_density(alpha = 0.2, adjust = 2) +
  theme_cowplot(font_size = myfontsize) + 
  labs(y= "Density", 
       x = "Co-foundress relatedness (KING-robust)") + 
  scale_fill_manual( values = c(mySouthAfricaColour)) + 
  scale_x_continuous(limits = c(-0.03,0.9), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0,15,by = 5),expand = c(0, 0)) + 
  geom_vline(xintercept = mean(as.numeric(SouthAfrican_cofoundresses$KING_multiplied_by_2)), 
             linetype="dashed") + theme(legend.position = "none")
SA_plot_KING

# Supplementary panel using KING-robust estimator:
my_output_panel_KING <- ggdraw() +
  draw_plot(my_plot_KING,  x=0, y=0, width= .3, height=1) +
  draw_plot(Cameroon_plot_KING,  x=.3, y=0, width= .7, height=.5) +
  draw_plot(SA_plot_KING,  x=.3, y=.5, width= .7, height=.5)
my_output_panel_KING

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "my_output_panel_KING.svg", 
       plot = my_output_panel_KING, 
       height = 2.5,
       width = 5, dpi = 200)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.


# -----------------------------------------------------------------------------
# PROPORTION OF RELATEDNESSES THAT ARE NOT FULL SISTERS:

Threshold_for_interpretting_as_full_sisters = 0.6

# Proportion of pairwise relatednesses that are not full-sisters in Cameroon:
Cameroon_total_full_sister_relatednesses <- dim(subset(Cameroon_cofoundresses, rab > Threshold_for_interpretting_as_full_sisters))[1]
Cameroon_total_relatednesses <- dim(Cameroon_cofoundresses)[1]
Cameroon_Percent_of_relatednesses_that_are_not_full_sisters <- (1-(Cameroon_total_full_sister_relatednesses/Cameroon_total_relatednesses))*100
Cameroon_Percent_of_relatednesses_that_are_not_full_sisters

# Proportion of pairwise relatednesses that are not full-sisters in South Africa:
SA_total_full_sister_relatednesses <- dim(subset(SouthAfrican_cofoundresses, rab > Threshold_for_interpretting_as_full_sisters))[1]
SA_total_relatednesses <- dim(SouthAfrican_cofoundresses)[1]
SA_Percent_of_relatednesses_that_are_not_full_sisters <- (1-(SA_total_full_sister_relatednesses/SA_total_relatednesses))*100
SA_Percent_of_relatednesses_that_are_not_full_sisters

Cameroon_total_not_sisters <- Cameroon_total_relatednesses-Cameroon_total_full_sister_relatednesses
SA_total_not_sisters <- SA_total_relatednesses-SA_total_full_sister_relatednesses

# Two-proportions Z test:
prop.test(x = c(Cameroon_total_not_sisters,SA_total_not_sisters), 
          n = c(Cameroon_total_relatednesses,SA_total_relatednesses), 
          p = NULL, alternative = "two.sided", 
          correct = TRUE)

## OUTPUT OF ANALYSIS (27th April 2024):
## 2-sample test for equality of proportions with
## continuity correction
## 
## data:  c(Cameroon_total_not_sisters, SA_total_not_sisters) out of c(Cameroon_total_relatednesses, SA_total_relatednesses)
## X-squared = 66.038, df = 1, p-value = 4.422e-16
## alternative hypothesis: two.sided
## 95 percent confidence interval:
##   0.2560086 0.4243068
## sample estimates:
##   prop 1    prop 2 
## 0.4619289 0.1217712 

# Barplot showing the proportions of cofoundresses pairwise relatednesses that are full sisters, with '***' to denote the significant p-value from the test above:
SA_total_not_sisters <- SA_total_relatednesses-SA_total_full_sister_relatednesses;
Cameroon_total_not_sisters <- Cameroon_total_relatednesses-Cameroon_total_full_sister_relatednesses;
df2 <- data.frame(supp=rep(c( "Sisters","xNon-Sisters"), each=2),
                  Country=rep(c("SA", "CA"),2),
                  Nonsisters=c(SA_total_full_sister_relatednesses,Cameroon_total_full_sister_relatednesses,SA_total_not_sisters, Cameroon_total_not_sisters));
nonsisters_barplot <- ggplot(data=df2, aes(x=Country, y=Nonsisters, fill=supp)) +
  geom_bar(aes(fill = interaction(supp,Country)),color='black',stat="identity") + 
  scale_fill_manual(values=c('white',myCameroonColour,'white',mySouthAfricaColour)) + 
  theme(legend.position = "none") + scale_y_continuous(expand = c(0,0),limits = c(0,300)) + 
  theme_classic() + 
  theme(legend.position = "none") + annotate("text", x = 1.5, y = 290, label = "***")
nonsisters_barplot

# Plot on the panel:
plot_grid(nonsisters_barplot, 
          SA_plot, 
          nonsisters_barplot,
          Cameroon_plot,  align = "v",
          nrow = 2, 
          rel_widths  = c(1/15, 1/4))

library(svglite)
ggsave(filename = "Nonsisters_barplot.svg", 
       plot = nonsisters_barplot, 
       height = 4,
       width = 2, dpi = 200)
# -----------------------------------------------------------------------------
# PROPORTION OF RELATEDNESSES THAT ARE NONRELATIVES OR VERY DISTANT RELATIVES

Threshold_for_interpretting_as_nonrelatives = 0.1

# Proportion of pairwise relatednesses that are <0.15 in Cameroon:
Cameroon_total_nonrelatives_relatednesses <- dim(subset(Cameroon_cofoundresses, rab < Threshold_for_interpretting_as_nonrelatives))[1]
Cameroon_total_relatednesses <- dim(Cameroon_cofoundresses)[1]
Cameroon_Percent_of_relatednesses_that_are_nonrelatives <- (Cameroon_total_nonrelatives_relatednesses/Cameroon_total_relatednesses)*100
Cameroon_Percent_of_relatednesses_that_are_nonrelatives

# Proportion of pairwise relatednesses that are <0.15 in Cameroon:
SA_total_nonrelatives_relatednesses <- dim(subset(SouthAfrican_cofoundresses, rab < Threshold_for_interpretting_as_nonrelatives))[1]
SA_total_relatednesses <- dim(SouthAfrican_cofoundresses)[1]
SA_Percent_of_relatednesses_that_are_nonrelatives <- (SA_total_nonrelatives_relatednesses/SA_total_relatednesses)*100
SA_Percent_of_relatednesses_that_are_nonrelatives

# Two-proportions Z test:
prop.test(x = c(Cameroon_total_nonrelatives_relatednesses,SA_total_nonrelatives_relatednesses), 
          n = c(Cameroon_total_relatednesses,SA_total_relatednesses), 
          p = NULL, alternative = "two.sided", 
          correct = TRUE)

## OUTPUT OF ANALYSIS (27th April 2024):
## 2-sample test for equality of proportions with continuity correction
## 
## data:  c(Cameroon_total_nonrelatives_relatednesses, SA_total_nonrelatives_relatednesses) out of c(Cameroon_total_relatednesses, SA_total_relatednesses)
## X-squared = 17.888, df = 1, p-value = 2.343e-05
## alternative hypothesis: two.sided
## 95 percent confidence interval:
##   0.04629936 0.15030281
## sample estimates:
##   prop 1     prop 2 
## 0.11675127 0.01845018 

# -----------------------------------------------------------------------------
# WHAT PERCENTAGE OF NESTS CONTAIN AT LEAST ONE NONRELATIVE OR DISTANT RELATIVE?

# In Polistes dominula, Field & Leadbeater (2016) write: "In the Spanish populations, more than 80% of co-foundress 
# groups contain at least one foundress that is unrelated or only distantly 
# related to other group members" (https://royalsocietypublishing.org/doi/10.1098/rstb.2015.0093)
# What is the equivalent percentage in Belonogaster juncea?

# The minimum relatedness value on each nest:
Nest_min <- aggregate(rab ~ ida_Tagging_nest_if_foundress, 
                      Cofoundresses_data, 
                      min)
CountryList <- cbind(Cofoundresses_data$ida_Tagging_nest_if_foundress, Cofoundresses_data$ida_Country)
CountryList <- unique(CountryList)
colnames(CountryList) <- c("ida_Tagging_nest_if_foundress","Country")
Nest_min <- merge(Nest_min, CountryList, by.x = "ida_Tagging_nest_if_foundress", by.y = "ida_Tagging_nest_if_foundress")

nests_with_nonrelative_or_distant_relative <- subset(Nest_min,Nest_min$rab<Threshold_for_interpretting_as_nonrelatives)

Cameroon_nests_with_nonrelative_or_distant_relative_COUNT <- dim(subset(nests_with_nonrelative_or_distant_relative,nests_with_nonrelative_or_distant_relative$Country=="Cameroon"))[[1]]
SA_nests_with_nonrelative_or_distant_relative_COUNT <- dim(subset(nests_with_nonrelative_or_distant_relative,nests_with_nonrelative_or_distant_relative$Country=="SouthAfrica"))[[1]]

Cameroon_Proportion_of_nests_with_nonrelative_or_distant_relative <- (Cameroon_nests_with_nonrelative_or_distant_relative_COUNT/dim(subset(Nest_min, Country == "Cameroon"))[1])*100
SA_Proportion_of_nests_with_nonrelative_or_distant_relative <- (SA_nests_with_nonrelative_or_distant_relative_COUNT/dim(subset(Nest_min, Country == "SouthAfrica"))[1])*100

# Two-proportions Z test:
prop.test(x = c(Cameroon_nests_with_nonrelative_or_distant_relative_COUNT, SA_nests_with_nonrelative_or_distant_relative_COUNT), 
          n = c(dim(subset(Nest_min, Country == "Cameroon"))[1], dim(subset(Nest_min, Country == "SouthAfrica"))[1]), 
          p = NULL, alternative = "two.sided", 
          correct = TRUE)

## ANALYSIS 27th April  2024:
## 2-sample test for equality of proportions with continuity correction
## data:  c(Cameroon_nests_with_nonrelative_or_distant_relative_COUNT, SA_nests_with_nonrelative_or_distant_relative_COUNT) out of c(dim(subset(Nest_min, Country == "Cameroon"))[1], dim(subset(Nest_min, Country == "SouthAfrica"))[1])
## X-squared = 4.5671, df = 1, p-value = 0.03259
## alternative hypothesis: two.sided
## 95 percent confidence interval:
##   0.02160672 0.24366899
## sample estimates:
##   prop 1     prop 2 
## 0.18181818 0.04918033 

# BOXPLOT FOR RELATEDNESS OF THE LEAST-RELATED INDIVIDUAL IN EACH GROUP:
# Generate boxplots (following https://github.com/erocoar/ggpol):
least_related_plot <- ggplot(Nest_min) + 
  geom_boxjitter(aes(x = Country, 
                     y = rab, 
                     fill = Country),
                 jitter.shape = 21, 
                 jitter.color = NA, 
                 jitter.alpha = 0.5,
                 jitter.size = 1.5,
                 jitter.params = list(height = 0, width = 0.09),
                 outlier.color = "white", outlier.fill = "white", outlier.shape = 21,
                 errorbar.draw = TRUE) + 
  scale_fill_manual(values = myColors) +
  theme_cowplot(font_size = myfontsize) + 
  scale_x_discrete(labels=c("C","SA")) +
  theme(text = element_text(size=20)) +
  labs(y= "Minimum r", 
       x = "Country") + 
  theme(legend.position="none") + 
  theme(axis.line.x.bottom=element_line(size=0.5)) +
  theme(axis.line.y.left=element_line(size=0.5)) +
  theme(axis.text.x = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"),
        axis.text.y = element_text(color = "black", size = myfontsize, angle = 0, hjust = 1, vjust = 0, face = "plain"),  
        axis.title.x = element_text(color = "black", size = myfontsize, angle = 0, hjust = .5, vjust = 0, face = "plain"),
        axis.title.y = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"))
least_related_plot

# -----------------------------------------------------------------------------
# COMBINE PLOTS FOR PUBLICATION IN PANEL:

# Generate panel:
library("cowplot")
my_output_panel <- ggdraw() +
  draw_plot(least_related_plot,  x=0, y=0, width= .3, height=1) +
  draw_plot(Cameroon_plot,  x=.3, y=0, width= .7, height=.5) +
  draw_plot(SA_plot,  x=.3, y=.5, width= .7, height=.5) + 
  draw_plot_label("a", x = 0, y = 1, size = myfontsize, fontface = "bold") +
  draw_plot_label("b", x = .3, y = 1, size = myfontsize, fontface = "bold") +
  draw_plot_label("c", x = .3, y = .5,size = myfontsize, fontface = "bold")

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "my_output_panel.svg", 
       plot = my_output_panel, 
       height = 2.5,
       width = 5, dpi = 200)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.

# -----------------------------------------------------------------------------
# AVERAGE RELATEDNESSES PER NEST:

# Use the 'aggregrate' function to extract the mean relatedness on each nest:
Nest_means <- aggregate(rab ~ ida_Tagging_nest_if_foundress, 
                        Cofoundresses_data, 
                        mean)
Nest_means <- merge(Nest_means, CountryList, by = "ida_Tagging_nest_if_foundress")

# And the maximum relatedness value on each nest:
Nest_max <- aggregate(rab ~ ida_Tagging_nest_if_foundress, 
                      Cofoundresses_data, 
                      max)
Nest_max <- merge(Nest_max, CountryList, by.x = "ida_Tagging_nest_if_foundress", by.y = "ida_Tagging_nest_if_foundress")

# Use that table to calculate the proportion of foundress nests in each country that have at least one
# pair of full sisters:
Threshold_for_interpretting_as_full_sisters = 0.6
Cameroon_total_with_at_least_one_sister_pair <- dim(subset(Nest_max, rab > Threshold_for_interpretting_as_full_sisters & Country == "Cameroon"))[1]
Cameroon_total_cofoundress_nests <- dim(subset(Nest_max, Country == "Cameroon"))[1]
Cameroon_Percent_without_at_least_one_sister_pair <- (1-(Cameroon_total_with_at_least_one_sister_pair/Cameroon_total_cofoundress_nests))*100
Cameroon_Percent_without_at_least_one_sister_pair

SA_total_with_at_least_one_sister_pair <- dim(subset(Nest_max, rab > Threshold_for_interpretting_as_full_sisters & Country == "SouthAfrica"))[1]
SA_total_cofoundress_nests <- dim(subset(Nest_max, Country == "SouthAfrica"))[1]
SA_Percent_without_at_least_one_sister_pair <- (1-(SA_total_with_at_least_one_sister_pair/SA_total_cofoundress_nests))*100
SA_Percent_without_at_least_one_sister_pair

# That's quite striking. When I ran the script just now (31st May 2023), it showed 39.5% (32/81) of cofoundress nests
# did not involve any full-sisters in Cameroon, compared to just 7% (4/56) in South Africa.

# -----------------------------------------------------------------------------
# HOW RELATED ARE NEIGHBOURS?

# We categorise each nest into a specific 'aggregation' (a local cluster of neighbouring nests, separated
# typically by <10 metres, on a single building or a wing of a building).

# Here, we ask how closely related are neighbouring foundresses (i.e., members of other foundress nests
# in the same aggregation as a focal individual, excluding foundresses on the same nest as the focal).

# Add a new column to 'All', to record whether a given pairwise relatedness is between neighbours (non-nestmate 
# foundresses in the same aggregation):
All$Neighbours <- NA
All$Neighbours[All$SpecificAggregation.x == All$SpecificAggregation.y & All$ida_Tagging_nest_if_foundress != All$idb_Tagging_nest_if_foundress] <- 1

# Focus on neighbour relatednesses:
NeighbourRelatednesses <- subset(All, Neighbours == 1)

# Focus on neighbour relatednesses in Cameroon:
Cameroon_NeighbourRelatednesses <- subset(All, Neighbours == 1 & ida_Country == "Cameroon")
Cameroon_NeighbourRelatednesses$rab <- as.numeric(Cameroon_NeighbourRelatednesses$rab)
hist(as.numeric(Cameroon_NeighbourRelatednesses$rab))

# Focus on neighbour relatednesses in South Africa:
SA_NeighbourRelatednesses <- subset(All, Neighbours == 1 & ida_Country == "SouthAfrica")
SA_NeighbourRelatednesses$rab <- as.numeric(SA_NeighbourRelatednesses$rab)
hist(as.numeric(SA_NeighbourRelatednesses$rab))

# Cameroon neighbour relatedness only:
CA_neighbour_plot <- ggplot(Cameroon_NeighbourRelatednesses, aes(x=as.numeric(rab), fill=ida_Country)) + 
  geom_histogram(aes(y = ..density..),
                 fill = myCameroonColour, 
                 alpha = 0.8, bins = 60) +
  geom_density(alpha = 0.4, adjust = 3) +
  theme_cowplot(font_size = myfontsize) +
  labs(y= "Density", 
       x = "Intra-deme neighbour relatedness") + 
  scale_fill_manual( values = c(myCameroonColour)) + 
  scale_x_continuous(limits = c(-0.01,0.9), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) + 
  geom_vline(xintercept = mean(as.numeric(Cameroon_NeighbourRelatednesses$rab)), 
             linetype="dashed") + theme(legend.position = "none")
CA_neighbour_plot

# South African neighbour relatedness only:
SA_neighbour_plot <- ggplot(SA_NeighbourRelatednesses, aes(x=as.numeric(rab), fill=ida_Country)) + 
  geom_histogram(aes(y = ..density..),
                 fill = mySouthAfricaColour, 
                 alpha = 0.8, bins = 60) +
  geom_density(alpha = 0.4, adjust = 3) +
  theme_cowplot(font_size = myfontsize) +
  labs(y= "Density", 
       x = "Intra-deme neighbour relatedness") + 
  scale_fill_manual( values = c(mySouthAfricaColour)) + 
  scale_x_continuous(limits = c(-0.01,0.9), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) + 
  geom_vline(xintercept = mean(as.numeric(SA_NeighbourRelatednesses$rab)), 
             linetype="dashed") + theme(legend.position = "none")
SA_neighbour_plot

#CONTINUEHERE
# Plot on the panel:
plot_grid(my_plot, 
          SA_plot, 
          SA_neighbour_plot,
          nonsisters_barplot,
          Cameroon_plot,
          CA_neighbour_plot,
          align = "v",
          nrow = 2, 
          rel_widths  = c(1/15, 1/4, 1/4))


# -----------------------------------------------------------------------------
# COMBINE PLOTS FOR PUBLICATION IN PANEL:

# Generate panel:
library("cowplot")
my_neighbour_panel <- ggdraw() +
  draw_plot(nonsisters_barplot,  x=0, y=0, width= .3, height=1) +
  draw_plot(CA_neighbour_plot,  x=.3, y=0, width= .7, height=.5) +
  draw_plot(SA_neighbour_plot,  x=.3, y=.5, width= .7, height=.5) 
my_neighbour_panel

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "my_neighbour_panel.svg", 
       plot = my_neighbour_panel, 
       height = 2.5,
       width = 5, dpi = 200)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.

# Percentage probability that a randomly-chosen neighbour is a full sister:
# ...in South Africa:
dim(subset(SA_NeighbourRelatednesses, rab > 0.6))[1]/dim(SA_NeighbourRelatednesses)[1]*100
# ...in Cameroon:
dim(subset(Cameroon_NeighbourRelatednesses, rab > 0.6))[1]/dim(Cameroon_NeighbourRelatednesses)[1]*100

# When I ran this on 28th April 2024, probability that a randomly-chosen neighbour (foundress on a 
# different nest in the same aggregation) is a full sister is 17.46% in South Africa and 5.95% in Cameroon.

# Visualising the same information, but split into different aggregations:
# South African neighbour relatedness only (colour-coded by aggregation):
ggplot(SA_NeighbourRelatednesses, aes(x=as.numeric(rab), fill=ida_Population)) + 
  geom_histogram(aes(y = ..density..),
                 fill = mySouthAfricaColour, 
                 alpha = 0.8, bins = 60) +
  geom_density(alpha = 0.4, adjust = 0.7) +
  theme_classic() + 
  labs(y= "Density", 
       x = "Neighbour relatedness") + 
  scale_x_continuous(limits = c(-0.01,0.9), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) + 
  geom_vline(xintercept = mean(as.numeric(SA_NeighbourRelatednesses$rab)), 
             linetype="dashed")

# -----------------------------------------------------------------------------
# NETWORK DIAGRAM TO VISUALISE KINSHIP STRUCTURE ON A NEST OF INTEREST:

# Following: http://www.sthda.com/english/articles/33-social-network-analysis/135-network-visualization-essentials-in-r/

# List of all nests from the chosen country:
nestlist <- levels(as.factor(SouthAfrican_cofoundresses$ida_Tagging_nest_if_foundress))

p <- list()
for (nest in 1:length(nestlist)){
  
  # Enter your nest of interest here:
  Nest_of_interest <- nestlist[nest]
  
  # Extract data for this nest:
  this_nest_data <- subset(Cofoundresses_data, ida_Tagging_nest_if_foundress == Nest_of_interest)
  # Load packages:
  library(tidyverse)
  library(dplyr)
  # Generate a list of which wasps are present on this nest:
  this_nest_wasps <- cbind(this_nest_data$ida_WaspID, this_nest_data$idb_WaspID)
  this_nest_wasps <- as.data.frame(this_nest_wasps)
  this_nest_wasps <- stack(this_nest_wasps)
  this_nest_wasps <- as.data.frame(this_nest_wasps$values)
  this_nest_wasps <- distinct(this_nest_wasps)
  colnames(this_nest_wasps) <- c("label")
  # Give each wasp in the nest a unique number as a node ID number:
  this_nest_wasps <- this_nest_wasps %>% mutate(id = row_number())
  # Reorder the columns so that 'id' is first:
  col_order <- c("id","label")
  this_nest_wasps <- this_nest_wasps[, col_order]
  # Convert this node list to 'tibble' format (http://www.sthda.com/english/articles/33-social-network-analysis/135-network-visualization-essentials-in-r/):
  nodes <- as_tibble(this_nest_wasps)
  # Now generate an edgelist for this nest:
  my_edgelist <- cbind(this_nest_data$ida_WaspID, 
                       this_nest_data$idb_WaspID, 
                       this_nest_data$rab)
  my_edgelist <- as.data.frame(my_edgelist)
  my_edgelist$V3 <- as.numeric(my_edgelist$V3)
  # We will have different edge types for different inferred kinships (i.e., full sisters, cousins, etc.):
  my_edgelist$InferredKinship <- NA
  my_edgelist$InferredKinship[my_edgelist$V3 < 0.1] <- "Unrelated (ideal r<0.1)"
  my_edgelist$InferredKinship[my_edgelist$V3 > 0.1 & my_edgelist$V3 < 0.3] <- "Cousins (ideal r<0.1875)"
  my_edgelist$InferredKinship[my_edgelist$V3 > 0.3 & my_edgelist$V3 < 0.44] <- "Aunt-niece (ideal r=0.375)"
  my_edgelist$InferredKinship[my_edgelist$V3 > 0.44 & my_edgelist$V3 < 0.6] <- "Mother-daughter (ideal r=0.5)"
  my_edgelist$InferredKinship[my_edgelist$V3 > 0.6] <- "Full sisters (ideal r=0.75)"
  
  
  # Choose the linetype for the different inferred kinships:
  my_edgelist$linetype <- NA
  my_edgelist$linetype[my_edgelist$InferredKinship == "Unrelated (ideal r<0.1)"] <- "dotted"
  my_edgelist$linetype[my_edgelist$InferredKinship == "Cousins (ideal r<0.1875)"] <- "dotdash"
  my_edgelist$linetype[my_edgelist$InferredKinship == "Aunt-niece (ideal r=0.375)"] <- "dashed"
  my_edgelist$linetype[my_edgelist$InferredKinship == "Mother-daughter (ideal r=0.5)"] <- "solid"
  my_edgelist$linetype[my_edgelist$InferredKinship == "Full sisters (ideal r=0.75)"] <- "solid"
  
  
  # Choose the line colours for the different inferred kinships:
  my_edgelist$my_line_colours <- NA
  my_edgelist$my_line_colours[my_edgelist$InferredKinship == "Unrelated (ideal r<0.1)"] <- "grey"
  my_edgelist$my_line_colours[my_edgelist$InferredKinship == "Cousins (ideal r<0.1875)"] <- "pink"
  my_edgelist$my_line_colours[my_edgelist$InferredKinship == "Aunt-niece (ideal r=0.375)"] <- "turquoise"
  my_edgelist$my_line_colours[my_edgelist$InferredKinship == "Mother-daughter (ideal r=0.5)"] <- "green"
  my_edgelist$my_line_colours[my_edgelist$InferredKinship == "Full sisters (ideal r=0.75)"] <- "navy"
  
  
  # Convert to tibble format:
  edges <- as_tibble(my_edgelist)
  
  # Use VLOOKUP ('merge') to phrase the edgelist in terms of the node IDs:
  colnames(edges) <- c("WaspA","WaspB","Relatedness", "type","linetype","my_line_colours")
  edges <- merge(x = edges, 
                 y = nodes, 
                 by.x = "WaspA", 
                 by.y = "label")
  names(edges)[names(edges) == 'id'] <- 'from'
  
  # Now do the same for the 'to' wasp ('WaspB'):
  edges <- merge(x = edges, 
                 y = nodes, 
                 by.x = "WaspB", 
                 by.y = "label")
  names(edges)[names(edges) == 'id'] <- 'to'
  
  # Rearrange the 'edges' sheet by getting rid of the unnecessary columns:
  edges <- cbind(edges$from, edges$to, edges$Relatedness, edges$type, edges$linetype, edges$my_line_colours)
  colnames(edges) <- c("from","to","weight","type","linetype","my_line_colours")
  edges <- as_tibble(edges)
  
  # Plot the resulting diagram:
  library(igraph)
  library(ggraph)
  net <- graph_from_data_frame(d=edges,vertices=nodes,directed=T)
  p[[nest]] <- ggraph(net,layout = 'linear', circular = TRUE) +
    geom_edge_fan(aes(linetype = linetype,
                      color = my_line_colours) # You set linetype in the code above.
    ) +
    geom_node_point(fill = "white", shape = 21, size = 1, color = "black") +
    scale_edge_alpha(range = c(0,1)) +
    scale_edge_width(range = c(0,1)) + 
    theme_graph() + ##geom_node_text(aes(label=label),size=2, repel = TRUE) +
    scale_edge_linetype_manual(limits = as.factor(edges$linetype),
                               values = edges$linetype) +
    scale_edge_color_manual(limits = as.factor(edges$my_line_colours), 
                            values = edges$my_line_colours) + 
    expand_limits(x = c(-0.1,0.1), y = c(-0.1,0.1)) + 
    theme(legend.position = "none", 
          plot.background = element_rect(fill='transparent', color=NA))
  
  
  ggsave(p[[nest]],filename=paste("myplot",Nest_of_interest,".pdf", sep=""), width = 2, height = 2) 
  
  
} # end for-loop through each nest.

# The diagrams are now available in the current directory, and can be imported into Illustrator/Powerpoint for arranging.

margin = theme(plot.margin = unit(c(0,0,0,0), "cm"))
grid.arrange(grobs = lapply(p, "+", margin))

# -----------------------------------------------------------------------------
# NETWORK DIAGRAM TO SHOW HOW MANY PARENTAL NESTS CONTRIBUTED TO EACH AGGREGATION:

# Following: http://www.sthda.com/english/articles/33-social-network-analysis/135-network-visualization-essentials-in-r/

# We only want to plot between-foundress relatednesses in this section (i.e., no post-emergence nests and no brood).
# Therefore, restrict 'All' to foundresses only:
All_F <- subset(All,All$`Wasp type.x` == 'F' & All$`Wasp type.y` == 'F' )

# The script will loop through each of the aggregations, and export the kinship network:

aggregation_list <- unique(All$SpecificAggregation.x)

for (aggregation in 1:length(aggregation_list)){
  
  # Enter the specific AGGREGATION of interest here:
  Aggregation_of_interest <- aggregation_list[[aggregation]]
  
  # Generate a list of all samples in the dataset from this population:
  this_aggregation_data <- subset(All_F, SpecificAggregation.x == Aggregation_of_interest)
  this_aggregation_data <- subset(this_aggregation_data, SpecificAggregation.y == Aggregation_of_interest)
  df1 <- cbind(this_aggregation_data$ida_WaspID, this_aggregation_data$idb_WaspID)
  df1 <- as.data.frame(df1)
  df1 <- stack(df1)
  df1 <- as.data.frame(df1$values)
  colnames(df1) <- c("label")
  library(tidyverse)
  df1 <- distinct(df1)
  
  # Only continue with this aggregation if has data to plot:
  if (nrow(this_aggregation_data) > 0){
    
    # Record which country this aggregation is in:
    this_aggregation_country <- this_aggregation_data$ida_Country[[1]]
    
    # Set colours to red for South Africa and turquoise for Cameroon:
    if (this_aggregation_country == 'Cameroon'){my_edge_colour = "turquoise"}
    if (this_aggregation_country == 'SouthAfrica'){my_edge_colour = "red"}
    
    # Give each wasp in the population a unique number as a node ID number:
    library(dplyr)
    df1 <- df1 %>% mutate(id = row_number())
    
    # Reorder the columns so that 'id' is first:
    col_order <- c("id","label")
    df1 <- df1[, col_order]
    
    # Convert this node list to 'tibble' format (http://www.sthda.com/english/articles/33-social-network-analysis/135-network-visualization-essentials-in-r/):
    nodes <- as_tibble(df1)
    
    # Now generate an edgelist for this population:
    rm(my_edgelist)
    my_edgelist <- cbind(this_aggregation_data$ida_WaspID, 
                         this_aggregation_data$idb_WaspID, 
                         this_aggregation_data$rab)
    my_edgelist <- as.data.frame(my_edgelist)
    my_edgelist$V3 <- as.numeric(my_edgelist$V3)
    
    # Remove any edges that represent zero relatedness (using a cut-off of r < 0.01):
    myCutOff <- 0.1 # Set this is zero if you want to include everything (you can always make edges with a weight of zero transparent later)
    my_edgelist <- subset(my_edgelist, V3 > myCutOff)
    
    # I think it would be good to have two edge types. One showing relatedness (with width/alpha),
    # the other other showing who is nesting together (i.e., cofoundressses). That could be a dotted or dashed line.
    # We can follow this example (https://stackoverflow.com/questions/72880329/different-aesthetic-scales-for-different-types-of-edges-on-same-graph)
    # to have two different types of edge in the edgelist.
    # So here, I will add in edges linking co-foundresses:
    my_edgelist2 <- cbind(this_aggregation_data$ida_WaspID,
                          this_aggregation_data$idb_WaspID,
                          this_aggregation_data$Same_nest)
    my_edgelist2 <- as.data.frame(my_edgelist2)
    my_edgelist2$V3 <- as.numeric(my_edgelist2$V3)
    my_edgelist2 <- subset(my_edgelist2, V3 == 1)
    
    # Only continue with this aggregation if has at least one egde:
    if (nrow(my_edgelist2) > 0){
      
      my_edgelist2$type <-"Wasp cofoundresses"
      my_edgelist$type <-"Relatedness"
      my_edgelist2$V3 <- 0.7 # Change the value '1' to something else (such as 0.5) to avoid these lines
      # being much thicker than the relatedness lines
      # For plotting on the graph, state whether you want dashed, dotted, or solid lines:
      my_edgelist2$V4 <- "solid"       # cofoundresses edges
      my_edgelist$V4 <- "solid"         # relatedness edges
      # For plotting on the graph, state the colours for each edge type:
      my_edgelist2$V5 <- "black"              # cofoundresses edges
      my_edgelist$V5 <- my_edge_colour         # relatedness edges - set to turquoise for Cameroon and red for South Africa
      my_edgelist <- rbind(my_edgelist2,my_edgelist)
      
      # Convert the edgelist to 'tibble' format too (http://www.sthda.com/english/articles/33-social-network-analysis/135-network-visualization-essentials-in-r/):
      edges <- as_tibble(my_edgelist)
      
      # Use VLOOKUP ('merge') to phrase the edgelist in terms of the node IDs:
      colnames(edges) <- c("WaspA","WaspB","Relatedness", "type","linetype","my_line_colours")
      edges <- merge(x = edges, 
                     y = nodes, 
                     by.x = "WaspA", 
                     by.y = "label")
      names(edges)[names(edges) == 'id'] <- 'from'
      
      # Now do the same for the 'to' wasp ('WaspB'):
      edges <- merge(x = edges, 
                     y = nodes, 
                     by.x = "WaspB", 
                     by.y = "label")
      names(edges)[names(edges) == 'id'] <- 'to'
      
      # Rearrange the 'edges' sheet by getting rid of the unnecessary columns:
      edges <- cbind(edges$from, edges$to, edges$Relatedness, edges$type, edges$linetype, edges$my_line_colours)
      colnames(edges) <- c("from","to","weight","type","linetype","my_line_colours")
      edges <- as_tibble(edges)
      
      # Plot the resulting diagram:
      library(igraph)
      library(ggraph)
      net <- graph_from_data_frame(d=edges,vertices=nodes,directed=T)
      my_plot_aggregation <- ggraph(net,layout='stress') + 
        geom_edge_fan(aes(color=my_line_colours, # You set line colours in the code above.
                          alpha=as.numeric(weight),
                          width=as.numeric(weight),
                          linetype=linetype) # You set linetype in the code above.
        ) + 
        scale_edge_linetype_manual(limits = as.factor(edges$linetype), 
                                   values = edges$linetype) +
        scale_edge_color_manual(limits = as.factor(edges$my_line_colours), 
                                values = edges$my_line_colours) +
        geom_node_point(fill = "white", shape = 21, size = 2, color = "black") +
        scale_edge_alpha(range = c(0,1)) +
        scale_edge_width(range = c(0.1,0.5)) + 
        theme_graph() + theme(legend.position = "none")
      
      # layout = 'stress'  is quite good
      
      # To include the wasp ID names, add the following option:
      ##        + geom_node_label(aes(label=label),size=1)
      
      
      # Opening the graphical device
      pdf(paste("Aggregation_",Aggregation_of_interest,".pdf", sep = ""),
          width = 4, height = 2) # Width and height in inches
      
      # Creating a plot
      print(my_plot_aggregation)
      
      # Closing the graphical device
      dev.off() 
      
    }}}

# -----------------------------------------------------------------------------
# LOOK AT RELATEDNESS IN THE EXPERIMENT WASPS:

# For calculating the relatedness data, we won't use the 'Cofoundresses_data' table, because
# that is limited to tagging nests (i.e., relatedness on nests at tagging, before any experimental
# manipulation). Some wasps shifted colony, meaning they appeared on trials with
# new co-foundresses who were not from their tagging nest. For relatedness in the experimental 
# nests, therefore, we need to look at the whole dataset ('All').

# Manually import the 'Experiment wasps' table into R, as 'temp_Experiment_wasps_table':
View(temp_Experiment_wasps_table)

# Extract the subordinates only:
Subordinates <- subset(temp_Experiment_wasps_table, Position == "Subordinate")
View(Subordinates)

# Add in relatednesses (focusing only on the subordinates for whom we have a relatedness to the dominant):
temp1 <- merge(Subordinates, All, by.x=c("WaspID","Who_is_dominant_on_this_nest"), by.y = c("ida_WaspID","idb_WaspID"))
temp2 <- merge(Subordinates, All, by.x=c("WaspID","Who_is_dominant_on_this_nest"), by.y = c("idb_WaspID","ida_WaspID"))
Subordinates <- rbind(temp1,temp2)
Subordinates$rab <- as.numeric(Subordinates$rab)

# Cameroonian experiment subordinates:
Cameroon.ExperimentSubordinates <- subset(Subordinates, Country == "Ca")
SA.ExperimentSubordinates <- subset(Subordinates, Country == "SA")

# That provides the specific relatednesses of subordinates to dominants, albeit in a fairly small sample.
# We can plot it here:
Cameroon.ExperimentSubordinatesRelatednessPlot <- ggplot(Cameroon.ExperimentSubordinates, aes(x=as.numeric(rab), fill=ida_Country)) + 
  geom_histogram(aes(y = ..density..), alpha = 0.8, bins = 40) + geom_density(alpha = 0.4, adjust = 0.2) + theme_cowplot() + 
  labs(y= "Density", x = "Subordinate's relatedness to dominant") + scale_fill_manual( values = c(myCameroonColour, mySouthAfricaColour)) + scale_x_continuous(limits = c(-0.018,0.9), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) + geom_vline(xintercept = mean(as.numeric(Cameroon_cofoundresses$rab)), linetype="dashed")
Cameroon.ExperimentSubordinatesRelatednessPlot

SA.ExperimentSubordinatesRelatednessPlot <- ggplot(SA.ExperimentSubordinates, aes(x=as.numeric(rab))) + 
  geom_histogram(aes(y = ..density..), fill="red", alpha = 0.8, bins = 40) + geom_density(alpha = 0.4, adjust = 0.8,fill="red") + theme_cowplot() + 
  labs(y= "Density", x = "Subordinate's relatedness to dominant") + scale_fill_manual( values = c(myCameroonColour, mySouthAfricaColour)) + scale_x_continuous(limits = c(-0.018,0.9), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) + geom_vline(xintercept = mean(as.numeric(Cameroon_cofoundresses$rab)), linetype="dashed")
SA.ExperimentSubordinatesRelatednessPlot

# Relatedness is near-uniformly full-sister in South Africa. However, there is variability in Cameroon. Does it predict likelihood of defection?

# Simple logistic regression of relatedness to dominant against whether Cameroonian subordinates visited the prize nest at any time:

var1 <- Cameroon.ExperimentSubordinates$DidThisWaspEverVisitPrize
var2 <- Cameroon.ExperimentSubordinates$rab

Cameroon.ExperimentSubordinates$MoreThan25PercentOnPrize <- ifelse(Cameroon.ExperimentSubordinates$`Proportion of observations on prize`>0.25, 1, 0)

# Run logistic regression on the data:
logistic_model <- glm(MoreThan25PercentOnPrize ~ rab, 
                      data=Cameroon.ExperimentSubordinates, family=binomial)
summary(logistic_model)
report(logistic_model)
# OUTPUT (5th June 2024) SHOWS NO SIGNIFICANT EFFECT OF RELATEDNESS
## report() function output: "We fitted a logistic model (estimated using ML) to predict MoreThan25PercentOnPrize with rab (formula: MoreThan25PercentOnPrize ~ rab). The model's explanatory power is weak
## (Tjur's R2 = 0.02). The model's intercept, corresponding to rab = 0, is at -0.18 (95% CI [-1.29, 0.89], p = 0.738). Within this model:
##   - The effect of rab is statistically non-significant and negative (beta = -1.44, 95% CI [-3.80, 0.84], p = 0.218; Std. beta = -0.36, 95% CI [-0.94, 0.21])
## Standardized parameters were obtained by fitting the model on a standardized version of the dataset. 95% Confidence Intervals (CIs) and p-values were computed using a Wald
## z-distribution approximation."

# To plot the logistic regression, you can use ggplot2:
ggplot(Cameroon.ExperimentSubordinates, 
       aes(x=Cameroon.ExperimentSubordinates$rab, y=Cameroon.ExperimentSubordinates$MoreThan25PercentOnPrize, )) + 
  geom_point() +
  stat_smooth(method="glm", color="red", se=FALSE,
              method.args = list(family=binomial))    

# BE CAREFUL, AS SOME WASPS PARTICIPATED IN MORE THAN ONE TRIAL.

# How about average relatedness on each trial nest? This is not the same as the average
# relatedness on that trial nest when it was at the tagging stage, because wasps can move
# position (leave and arrive, and - in some cases - participate in more than one trial). 
# We therefore need to calculate average relatedness in the trial nests DURING the experiment,
# defined as the average relatedness between all participating individuals in the trial
# of interest. Caveat: not all participating individuals will have been sequenced.

# MAKING A LOOP THROUGH ALL THE NESTS (HAVEN'T YET ADDED IN THE OVERARCHING LOOP OVER ALL THE NESTS - BUILDING IT HERE:)

# Make sure the table is in dataframe format:
temp_Experiment_wasps <- as.data.frame(temp_Experiment_wasps_table)

# List all the trial nests:
trials_list <- levels(as.factor(temp_Experiment_wasps$Trial_not_necessarily_tagging_nest))

# Set up an empty dataframe to store the mean participant relatednesses on each trial:
MeanParticipantRelatednesses <- data.frame(Trial=character(),
                                           MeanRelatedness=numeric(),
                                           count1=numeric(),
                                           count2=numeric())

# Loop through each of the trials to extract the mean relatedness between the trial participants:
for (trial in 1:length(trials_list)){
  
  # Currently working on this nest:
  Focal_trial = trials_list[trial]
  
  # List all the participants on this trial (at any stage):
  Focal_trial_participants <- subset(temp_Experiment_wasps, Trial_not_necessarily_tagging_nest == Focal_trial)$WaspID
  
  # How many participants are there on this nest?
  Total_participants <- length(Focal_trial_participants)
  
  # Set up an empty dataframe to store the relatednesses on this focal trial:
  df <- data.frame(WaspA=character(), 
                   WaspB=character(), 
                   Relatedness=numeric())
  
  # Use a for-loop to extract all the relatednesses between participants in this trial:
  for (Participant in 1:Total_participants){
    # Work through each participant to extract its relatedness to each of the other participants on this nest:
    this_Participant <- Focal_trial_participants[Participant]
    for (OtherParticipant in 1:Total_participants){
      # Find the relatedness between this pair:
      OtherWasp <- Focal_trial_participants[OtherParticipant]
      this_rab <- as.numeric(subset(All, ida_WaspID == this_Participant & idb_WaspID == OtherWasp)$rab)
      # If there is no relatedness for this pair, just print 'NA':
      if(identical(this_rab, numeric(0)) == TRUE){this_rab="NA"}
      # Add this pair to the growing list:
      new_row_to_add_to_df <- c(this_Participant, OtherWasp, this_rab)
      df <- rbind(df,new_row_to_add_to_df)
    } # end loop through other participants.
  } # end loop through participants.
  
  # Name the columns:
  colnames(df) <- c("WaspA","WaspB","rab")
  
  # Remove 'NA' values from the dataframe:
  df <- subset(df, rab != "NA")
  
  # Make sure that the relatedness column is in numeric format:
  df$rab <- as.numeric(df$rab)
  
  # Record how many wasps we have data for for this trial:
  wasp_data_count <- length(unique(c(df$WaspA,df$WaspB)))
  # If there are no wasps at all, print 0:
  if(identical(wasp_data_count, integer(0)) == TRUE){wasp_data_count=0}
  
  # Calculate mean trial-participant relatedness for this trial, and add it the output:
  this_trial_row_to_add <- c(Focal_trial, # trial ID
                             mean(df$rab), # mean relatedness calculated from available wasps in the dataset
                             wasp_data_count, # how many wasps do we have relatedness data for?
                             Total_participants) # how many participants were there in total? Compare this to wasp_data_count to see the proportion of the total participants that we have relatednesses for.
  MeanParticipantRelatednesses <- rbind(MeanParticipantRelatednesses,this_trial_row_to_add)
  
} # end loop through each of the trials.

# Name the columns:
colnames(MeanParticipantRelatednesses) <- c("Trial","MeanRelatedness", "wasp_data_count","Total_participants")

# Focus on trials for which we have relatedness data:          
MeanParticipantRelatednesses <- subset(MeanParticipantRelatednesses, MeanRelatedness != "NaN")
MeanParticipantRelatednesses <- subset(MeanParticipantRelatednesses, Trial != "TWO TRIALS")

# ------------------------------------------------------------------------------
# BROOD RELATEDNESS:

# Focus on the brood only:
All_brood <- subset(All, All$`Wasp_type.x` == "Brood" & All$`Wasp_type.y` == "Brood")

# Add a new column, identifying if they are brood on the same nest:
All_brood$Same_nest_brood <- as.numeric(All_brood$Nest_if_brood.x == All_brood$Nest_if_brood.y)

# Extract brood on the same nest:
All_brood <- subset(All_brood, Same_nest_brood == 1)

# Make sure that the numeric columns are numeric:
All_brood$rab <- as.numeric(All_brood$rab)
All_brood$nSites <- as.numeric(All_brood$nSites)  

# Plot number of sites in inference against calculated relatedness to check that there isn't
# bias at the lower end (remember that we have already culled relatednesses with nSites below 'my_nSites_threshold'):
plot(All_brood$nSites, All_brood$rab)

# Plot histograms of brood relatednesses:
hist(All_brood$rab)
hist(subset(All_brood, ida_Country == "Cameroon")$rab)
hist(subset(All_brood, ida_Country == "SouthAfrica")$rab)

# Plot histograms focusing just on the eggs:
# Focus on the cofoundresses only:
Cofoundresses_data <- subset(All, Same_nest == 1)

# Make sure that the relatedness column is in 'numeric' format (as some entries that are in scientific notation
# will otherwise be missed out):
Cofoundresses_data$rab <- as.numeric(Cofoundresses_data$rab)

# Focus on the South African cofoundresses only:
SouthAfrican_cofoundresses <- subset(Cofoundresses_data, ida_Country == "SouthAfrica")
mean(as.numeric((SouthAfrican_cofoundresses$rab)))
hist(as.numeric((SouthAfrican_cofoundresses$rab)))

# Focus on the Cameroonian cofoundresses only:
Cameroon_cofoundresses <- subset(Cofoundresses_data, ida_Country == "Cameroon")
mean(as.numeric((Cameroon_cofoundresses$rab)))
hist(as.numeric((Cameroon_cofoundresses$rab)))

# ----------------------------------------------------------------------
# PLOT BOXPLOT COMPARING SOUTH AFRICA AND CAMEROON:

# Load the libraries:
library(ggplot2)
library(ggthemes)
library(ggpol)

my_x_variable <-  as.factor(All_brood$Nest_if_brood.x)
my_y_variable <-  as.numeric(All_brood$rab)
my_color_variable <- All_brood$ida_Country

myColors <- c("#56ddc5","red")

# Plot violin plots to show brood relatednesses on each of the sampled nests:
All_brood$ida_Country <- as.factor(All_brood$ida_Country)
All_brood$Nest_if_brood.x <- as.factor(All_brood$Nest_if_brood.x)

library(ggplot2)
library(ggbeeswarm)

ggplot(All_brood, aes(x = my_x_variable, y = my_y_variable, fill = my_color_variable)) +
  geom_hline(yintercept = 0.75, linetype = "dashed", color = "navy", size = 0.5, alpha = 1) +
  geom_hline(yintercept = 0.75, linetype = "solid", color = "navy", size = 35, alpha = 0.05) +
  geom_hline(yintercept = 0.1875, linetype = "dashed", color = "grey", size = 0.5, alpha = 1) +
  geom_hline(yintercept = 0.1875, linetype = "solid", color = "grey", size = 15, alpha = 0.15) +
  geom_hline(yintercept = 0.25, linetype = "dashed", color = "purple", size = 0.5, alpha = 1) +
  geom_hline(yintercept = 0.25, linetype = "solid", color = "purple", size = 20, alpha = 0.05) +
  geom_hline(yintercept = 0, linetype = "solid", color = "blue", size = 10, alpha = 0.05) +
  geom_violin(alpha = 0.9, linewidth = 0) +
  geom_quasirandom(size = 0.0005, color = "black") +
  theme(legend.position = "none") + theme_classic() + 
  scale_fill_manual(values = myColors) + 
  facet_grid(. ~ ida_Country, scales = "free", space='free') + 
  theme(strip.background = element_blank(), # Removes the panel headings introduced by 'facet'.
        strip.text.x = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 20,
                                  face = 'bold', color = 'black')) +
  ylim(0,1) +
  theme(text = element_text(size=20)) +
  labs(y= "Relatedness among brood", 
       x = "Nest") + 
  theme(axis.text.x = element_text(color = "black", size = 12, angle = 90, hjust = .5, vjust = .5, face = "plain"),
        axis.text.y = element_text(color = "black", size = 12, angle = 0, hjust = 1, vjust = 0, face = "plain"),  
        axis.title.x = element_text(color = "black", size = 12, angle = 0, hjust = .5, vjust = 0, face = "plain"),
        axis.title.y = element_text(color = "black", size = 12, angle = 90, hjust = .5, vjust = .5, face = "plain"))

# There are some brood with approx r=0.25 relatedness to each other. That is the relatedness you would expect from a 
# sister to a brother. Check whether these are brothers by seeing whether they have zero heterozygosity (i.e., haploids):
Estimated_heterozygosity_table <- read_excel("Estimated_heterozygosity_table.xlsx")
View(Estimated_heterozygosity_table) 
test1 <-merge(All_brood, Estimated_heterozygosity_table, by.x = "ida_WaspID", by.y = "WaspID")

# -----------------------------------------------------------------------------
# NETWORK DIAGRAMS TO VISUALISE KINSHIP STRUCTURE AMONG THE BROOD WITHIN EACH TARGET NEST:

# Following: http://www.sthda.com/english/articles/33-social-network-analysis/135-network-visualization-essentials-in-r/

# List of all nests currently loaded in this R session:
BROOD_nestlist <- levels(as.factor(All_brood$Nest_if_brood.x))

for (nest in 1:length(BROOD_nestlist)){
  
  # Enter your nest of interest here:
  Nest_of_interest <- BROOD_nestlist[nest]
  
  # Extract data for this nest:
  this_nest_data <- subset(All_brood, Nest_if_brood.x == Nest_of_interest)
  # Load packages:
  library(tidyverse)
  library(dplyr)
  # Generate a list of which wasps are present on this nest:
  this_nest_wasps <- cbind(this_nest_data$ida_WaspID, this_nest_data$idb_WaspID)
  this_nest_wasps <- as.data.frame(this_nest_wasps)
  this_nest_wasps <- stack(this_nest_wasps)
  this_nest_wasps <- as.data.frame(this_nest_wasps$values)
  this_nest_wasps <- distinct(this_nest_wasps)
  colnames(this_nest_wasps) <- c("label")
  # Give each wasp in the nest a unique number as a node ID number:
  this_nest_wasps <- this_nest_wasps %>% mutate(id = row_number())
  
  
  # Add in a column stating this brood's stage of development:
  StageList <- cbind(temp_BAM_list$WaspID, temp_BAM_list$Stage_if_brood)
  colnames(StageList) <- c("Wasp","stage")
  this_nest_wasps <- merge(this_nest_wasps, StageList, by.x = "label", by.y = "Wasp")
  
  # Reorder the columns so that 'id' is first:
  col_order <- c("id","label","stage")
  this_nest_wasps <- this_nest_wasps[, col_order]
  
  # Convert this node list to 'tibble' format (http://www.sthda.com/english/articles/33-social-network-analysis/135-network-visualization-essentials-in-r/):
  nodes <- as_tibble(this_nest_wasps)
  # Now generate an edgelist for this nest:
  my_edgelist <- cbind(this_nest_data$ida_WaspID, 
                       this_nest_data$idb_WaspID, 
                       this_nest_data$rab)
  my_edgelist <- as.data.frame(my_edgelist)
  my_edgelist$V3 <- as.numeric(my_edgelist$V3)
  # We will have different edge types for different inferred kinships (i.e., full sisters, cousins, etc.):
  my_edgelist$InferredKinship <- NA
  my_edgelist$InferredKinship[my_edgelist$V3 < 0.1] <- "Unrelated (ideal r<0.1)"
  my_edgelist$InferredKinship[my_edgelist$V3 > 0.3 & my_edgelist$V3 < 0.6] <- "Not full sisters"
  my_edgelist$InferredKinship[my_edgelist$V3 > 0.6] <- "Full sisters (ideal r=0.75)"
  
  # Choose the linetype for the different inferred kinships:
  my_edgelist$linetype <- NA
  my_edgelist$linetype[my_edgelist$InferredKinship == "Unrelated (ideal r<0.1)"] <- "solid"
  my_edgelist$linetype[my_edgelist$InferredKinship == "Not full sisters"] <- "solid"
  my_edgelist$linetype[my_edgelist$InferredKinship == "Full sisters (ideal r=0.75)"] <- "solid"
  
  # Choose the line colours for the different inferred kinships:
  my_edgelist$my_line_colours <- NA
  my_edgelist$my_line_colours[my_edgelist$InferredKinship == "Unrelated (ideal r<0.1)"] <- "lightgrey"
  my_edgelist$my_line_colours[my_edgelist$InferredKinship == "Not full sisters"] <- "cyan"
  my_edgelist$my_line_colours[my_edgelist$InferredKinship == "Full sisters (ideal r=0.75)"] <- "navy"
  
  # Convert to tibble format:
  edges <- as_tibble(my_edgelist)
  
  # Use VLOOKUP ('merge') to phrase the edgelist in terms of the node IDs:
  colnames(edges) <- c("WaspA","WaspB","Relatedness", "type","linetype","my_line_colours")
  edges <- merge(x = edges, 
                 y = nodes, 
                 by.x = "WaspA", 
                 by.y = "label")
  names(edges)[names(edges) == 'id'] <- 'from'
  
  # Now do the same for the 'to' wasp ('WaspB'):
  edges <- merge(x = edges, 
                 y = nodes, 
                 by.x = "WaspB", 
                 by.y = "label")
  names(edges)[names(edges) == 'id'] <- 'to'
  
  # Rearrange the 'edges' sheet by getting rid of the unnecessary columns:
  edges <- cbind(edges$from, edges$to, edges$Relatedness, edges$type, edges$linetype, edges$my_line_colours)
  colnames(edges) <- c("from","to","weight","type","linetype","my_line_colours")
  edges <- as_tibble(edges)
  
  # Plot the resulting diagram:
  library(igraph)
  library(ggraph)
  net <- graph_from_data_frame(d=edges,vertices=nodes,directed=T)
  p <- ggraph(net,layout = 'linear', circular = TRUE) +
    geom_edge_fan(aes(linetype = linetype,
                      color = my_line_colours), # You set linetype in the code above.
                  alpha = 0.5) +
    geom_node_point(aes(fill = stage),
                    shape = 21, size = 3) +
    scale_edge_alpha(range = c(0.5,1)) +
    scale_edge_width(range = c(0.5,1)) + 
    theme_graph() +
    geom_node_text(aes(label=label),size=2, repel = TRUE) + 
    scale_edge_linetype_manual(limits = as.factor(edges$linetype),
                               values = edges$linetype) +
    scale_edge_color_manual(limits = as.factor(edges$my_line_colours), 
                            values = edges$my_line_colours) +
    expand_limits(x = c(-0.1,0.1), y = c(-0.1,0.1)) + theme_void() +
    theme(legend.position = "none", 
          plot.background = element_rect(fill='transparent', color=NA))
  
  
  ggsave(p,filename=paste("Brood_Plot_",Nest_of_interest,".pdf", sep=""), width = 2, height = 2) 
  
}# end for-loop through each nest.

# The diagrams are now available in the current directory, and can be imported into Illustrator/Powerpoint for arranging.
