# PK
# R SCRIPT FOR PROCESSING TE OUTPUTS
# This script is for processing and plotting the outputs of the TE script ('Array_job_Singularity_shell_for_dnaPipeTE_on_HPC.sh'), once the compressed output folder has been downloaded to the local computer and unzipped.

# The outputs should now be available on the local computer (/Users/pk14885/Downloads/Completed_TE_outputs).

# Load libraries:
library(stringr)
library(ggtern)
library(ggplot2)
library(ggthemes)
library(ggpol)
library(cowplot)

# Set R working directory to the downloaded 'Completed_TE_outputs' folder:
setwd("~/Downloads/Completed_TE_outputs")

# Obtain list of each wasp:
filenames = dir()

# Create a dataframe to store the results, where each row will be a separate wasp, and the columns are the proportions of the genome represented by each type of component:

mat = matrix(ncol = 9, nrow = length(filenames)); TE_results_table=data.frame(mat) 

# check for the dimensions of data  
# frame 
print("Dimensions of data frame") 
dim(TE_results_table)

# If you have previously run this script, there will be two image files called "LTR_plot.eps" and "LTR_plot.pdf" in the folder,
# together with a file called "TE_results_table.csv". So that the loop below works, you should delete these three files.

# LOOP THROUGH EACH WASP'S OUTPUT, AND EXTRACT THE GENOMIC PROPORTIONS:

for (wasp in 1:length(filenames)){
  
  # Extract name of wasp from folder title:
  this_wasp_name <- str_sub(filenames[[wasp]], 8)
  
  # Extract this wasp's data from the 'dfg' output file:
  this_wasp_data <- read.delim(paste("~/Downloads/Completed_TE_outputs/", 
                                     filenames[[wasp]], 
                                     "/dnaPT_utils_outputs_", 
                                     this_wasp_name, 
                                     "_dfg.txt", 
                                     sep=""), 
                               header=FALSE)
  
  # If this is the first wasp, use it to set the column headings:
  if (wasp == 1){ 
    colnames(TE_results_table) <- c("Sequencing_machine_sample_name",this_wasp_data$V1)
    colnames(TE_results_table)[[9]] <- "Non-repetitive"}
  
  # The second column of this_wasp_data contains the relevant proportions. Extract and add to the master spreadsheet:
  TE_results_table[wasp,2:9] <- this_wasp_data$V2
  TE_results_table[wasp,1] <- this_wasp_name
}

# View the resulting dataset:
View(TE_results_table)

# Export the resulting dataset as 'TE_results_table':
write.table(TE_results_table, file = "TE_results_table.csv", sep = ",", col.names = NA,
            qmethod = "double")

# (The outputted table can be found in the Supplementary Material, under 'SUPMAT - TE_results_table'.)

# ----------------------------------------------------------------------------
# PLOTTING TERNARY PLOT:

# Import the 'lcWGS_sequences_table' (available in the SUPMAT Excel file) and view it:
View(lcWGS_sequences_table)

# Since some wasps were sequenced twice, these individuals have a 'main sample' and a 'backup sample'. To avoid double-counting, we need to make sure there is only one row for each individual wasp. Therefore, we will focus only on the main samples in this analysis/plot:
main_samples_only <- subset(lcWGS_sequences_table,lcWGS_sequences_table$`Main sample or backup`=="Main sample")

# Add WaspIDs to the TE_results_table:
dataset_for_plotting <- merge(main_samples_only, TE_results_table,  by="Sequencing_machine_sample_name")

# LTR retrotransposons dominate the repetitive element of the Belonogaster genome. We will therefore use the following vertices for the ternary plot:
# (1) LTR retrotransposons
# (2) Non-LTR and unknown repetitive elements
# (3) Non-repetitive genome

# The values for (1) and (3) are already available in the dataset_for_plotting. 

cols_to_sum=c("DNA", "Low_complexity", "MITE", "repeats_under_0.001%", "Simple_repeat","Unknown")
dataset_for_plotting$"Non-LTR and unknown repetitive elements"<-rowSums(dataset_for_plotting[,cols_to_sum])

# To confirm that this has worked, the three vertices should sum to 100:
cols_to_sum_2=c("LTR", "Non-repetitive", "Non-LTR and unknown repetitive elements")
dataset_for_plotting$"Sum_up"<-rowSums(dataset_for_plotting[,cols_to_sum_2])

# Shuffle the order of the wasps in dataset_for_plotting, so that they don't come in overlapping blocks on the ternary plot:
shuffled_rows_dataset_for_plotting <- dataset_for_plotting[sample(1:nrow(dataset_for_plotting)), ]

x  <- data.frame(
  x1 = shuffled_rows_dataset_for_plotting$LTR,
  x2 = shuffled_rows_dataset_for_plotting$"Non-repetitive",
  x3 = shuffled_rows_dataset_for_plotting$"Non-LTR and unknown repetitive elements",
  x4 = shuffled_rows_dataset_for_plotting$"Climate"
)

# So that we can add the mean values for the juncea (not petiolata) samples to the plot using dashed lines:
juncea_only_results <- subset(dataset_for_plotting,dataset_for_plotting$Species == "Belonogaster_juncea")

humid_tropics_juncea_only_results <- subset(juncea_only_results ,juncea_only_results$Climate == "Humid_tropics")
semi_arid_juncea_only_results <- subset(juncea_only_results ,juncea_only_results$Climate == "Semi_arid")
temperate_juncea_only_results <- subset(juncea_only_results ,juncea_only_results$Climate == "Temperate")
petiolata_only_results <- subset(dataset_for_plotting,dataset_for_plotting$Species == "Belonogaster_petiolata")

my_means <- as.data.frame(t(c(mean(juncea_only_results$LTR)/100, mean(juncea_only_results$`Non-repetitive`)/100, mean(juncea_only_results$`Non-LTR and unknown repetitive elements`)/100)))
colnames(my_means) <- c("x1","x2","x3")

humid_tropics_means <- as.data.frame(t(c(mean(humid_tropics_juncea_only_results$LTR)/100, 
                                         mean(humid_tropics_juncea_only_results$`Non-repetitive`)/100, 
                                         mean(humid_tropics_juncea_only_results$`Non-LTR and unknown repetitive elements`)/100)))
colnames(humid_tropics_means) <- c("x1","x2","x3")

semi_arid_means <- as.data.frame(t(c(mean(semi_arid_juncea_only_results$LTR)/100, 
                                     mean(semi_arid_juncea_only_results$`Non-repetitive`)/100, 
                                     mean(semi_arid_juncea_only_results$`Non-LTR and unknown repetitive elements`)/100)))
colnames(semi_arid_means) <- c("x1","x2","x3")

temperate_means <- as.data.frame(t(c(mean(temperate_juncea_only_results$LTR)/100, 
                                     mean(temperate_juncea_only_results$`Non-repetitive`)/100, 
                                     mean(temperate_juncea_only_results$`Non-LTR and unknown repetitive elements`)/100)))
colnames(temperate_means) <- c("x1","x2","x3")

petiolata_means <- as.data.frame(t(c(mean(petiolata_only_results$LTR)/100, 
                                     mean(petiolata_only_results$`Non-repetitive`)/100, 
                                     mean(petiolata_only_results$`Non-LTR and unknown repetitive elements`)/100)))
colnames(petiolata_means) <- c("x1","x2","x3")

TE_ternary_plot <- ggtern(data=x,aes(x2,x1,x3)) + 
  geom_mask() + theme_showgrid() + theme_showgrid_major() +
  geom_crosshair_tern(data=humid_tropics_means, colour = "#56ddc5", linetype = "dashed") +
  geom_crosshair_tern(data=semi_arid_means, colour = "orange", linetype = "dashed") +
  geom_crosshair_tern(data=temperate_means, colour = "red", linetype = "dashed") +
  geom_crosshair_tern(data=petiolata_means, colour = "gray", linetype = "dashed") +
  geom_point(aes(fill=x4),colour="black",shape=21,size=0.6,alpha=1,stroke = 0.1) + 
  scale_fill_manual(values=c("#56ddc5","orange","red","gray")) + theme_showgrid() +
  theme_classic() + theme_showarrows() +
  Tlab("") + Llab("") + Rlab("") +  
  theme(legend.position="none", axis.text = element_text(size = 10),axis.title = element_text(size = 10)) + 
  Tarrowlab("LTR") + 
  Larrowlab("Single") + 
  Rarrowlab("Other") + 
  theme_showarrows() 
TE_ternary_plot


# Export as SVG file for publication:
library(svglite)
ggsave(filename = "TE_ternary_plot.svg", 
       plot = TE_ternary_plot)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.


# ----------------------------------------------------------------------------
# BOXPLOT FOCUSING JUST ON LTR RETROTRANSPOSONS:

myColors <- c("#56ddc5","orange","red","gray")

myfontsize <- 10

# Generate boxplots (following https://github.com/erocoar/ggpol):
my_plot <- ggplot(dataset_for_plotting) + 
  geom_boxjitter(aes(x = Climate, 
                     y = LTR, 
                     fill = Climate),
                 jitter.shape = 21, 
                 jitter.color = NA, 
                 jitter.alpha = 0.5,
                 jitter.size = 0.5,
                 jitter.params = list(height = 0, width = 0.09),
                 outlier.color = 1, outlier.fill = 1, outlier.shape = 21,
                 errorbar.draw = TRUE) + 
  scale_fill_manual(values = myColors) +
  scale_x_discrete(labels=c("Humid\ntropics","Semi-arid","Temperate",expression(italic("B. petiolata") ))) +
  theme_cowplot(font_size = myfontsize) + 
  labs(y= "LTR retrotransposons (%)", 
       x = "Climate") + 
  theme(legend.position="none") + 
  theme(axis.line.x.bottom=element_line(size=0.5)) +
  theme(axis.line.y.left=element_line(size=0.5)) +
  theme(axis.text.x = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"),
        axis.text.y = element_text(color = "black", size = myfontsize, angle = 0, hjust = 1, vjust = 0, face = "plain"),  
        axis.title.x = element_text(color = "black", size = myfontsize, angle = 0, hjust = .5, vjust = 0, face = "plain"),
        axis.title.y = element_text(color = "black", size = myfontsize, angle = 90, hjust = .5, vjust = .5, face = "plain"))
my_plot


# Export as SVG file for publication:
library(svglite)
ggsave(filename = "LTR_plot.eps", 
       plot = my_plot, 
       height = 4,
       width = 2.5, dpi = 200)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.


# ----------------------------------------------------------------------------
# STATISTICAL TEST FOR DIFFERENCES IN TOTAL REPETITIVE CONTENT BETWEEN B. JUNCEA AND B. PETIOLATA:

dataset_for_plotting$Total_repetitive_content <- 100-dataset_for_plotting$`Non-repetitive`
two_species_test <- t.test(Total_repetitive_content ~ Species,
                           data = dataset_for_plotting)
report(two_species_test)

# OUTPUT OF WELCH'S T-TEST (16TH FEB 2024):
## "Effect sizes were labelled following Cohen's (1988) recommendations.
## The Welch Two Sample t-test testing the difference of Total_repetitive_content by Species (mean in group Belonogaster_juncea =
## 43.55, mean in group Belonogaster_petiolata = 26.19) suggests that the effect is positive, statistically significant, and large
## (difference = 17.36, 95% CI [16.54, 18.19], t(51.61) = 42.35, p < .001; Cohen's d = 11.79, 95% CI [9.45, 14.07])"

# ----------------------------------------------------------------------------
# WHAT PROPORTION OF JUNCEA'S MOBILOME CONTENT IS LTR RETROTRANSPOSONS?

mean(juncea_only_results$LTR/(100-juncea_only_results$`Non-repetitive`))*100
## 59.75092
> sd(juncea_only_results$LTR/(100-juncea_only_results$`Non-repetitive`))*100
## 7.413256

# ----------------------------------------------------------------------------
# STATISTICAL TEST FOR DIFFERENCES IN LTR WHOLE-GENOME PERCENTAGE BETWEEN CLIMATES (including population as a random effect):

# Following https://jontalle.web.engr.illinois.edu/MISC/lme4/bw_LME_tutorial.pdf:
# Null model:
library(lme4)
my1.null = lmer(LTR ~ (1|Population), data = dataset_for_plotting)
# Model with climate as a fixed effect:
my1.model = lmer(LTR ~ Climate + (1|Population), data = dataset_for_plotting)
# Comparison:
anova(my1.null,my1.model)

summary(my1.model)
library(report)
report(my1.model)

# Checking assumptions of the model (following https://ademos.people.uic.edu/Chapter18.html):
# (1) Linearity:
      # Plot the residuals against the outcome variable used in the model:
      plot(resid(my1.model), dataset_for_plotting$LTR) 
      # There is clearly a pattern here, so this assumption is violated.
# (2) Homogeneity of variances (following https://stats.stackexchange.com/questions/255546/test-homogeneity-in-lmer-models)
      library(car)
      leveneTest(residuals(my1.model) ~ dataset_for_plotting$Climate)
      # The p-value is very small, so the assumption of equal variances (homoscedasticity) is violated.
# (3) Normally-distributed residuals:
      require("lattice")
      qqmath(my1.model, id=0.05) #id: identifies values that may be exerting undue influence on the model (i.e. outliers)
      # This produces a QQ plot. There is deviation from the normal line at both tails.
      
# ----------------------------------------------------------------------------
# STATISTICAL TEST FOR DIFFERENCES IN LTR WHOLE-GENOME PERCENTAGE BETWEEN CLIMATES (not including population as a random effect):

# ANOVA with climate zone as the response variable:
res_aov <- aov(LTR ~ Climate,
               data = dataset_for_plotting)

# Check normality (https://statsandr.com/blog/anova-in-r/):
par(mfrow = c(1, 2)) # combine plots
hist(res_aov$residuals)
library(car)
qqPlot(res_aov$residuals,
       id = FALSE) # id = FALSE to remove point identification
       
       # Shapiro-Wilk test for normality:
       shapiro.test(res_aov$residuals)
       
       # SHAPIRO-WILK OUTPUT (15TH FEB 2024):
       ## Shapiro-Wilk normality test
       ## data:  res_aov$residuals
       ## W = 0.98016, p-value = 2.658e-09
       
       # Therefore, the data are significantly non-normal.
       
       # Levene's test for homogeneity of variances:
       library(car)
       leveneTest(LTR ~ Climate,
                  data = dataset_for_plotting)
       
       # LEVENE'S TEST OUTPUT (15TH FEB 2024):
       ## Levene's Test for Homogeneity of Variance (center = median)
       ## Df F value    Pr(>F)    
       ## group   3  7.4442 6.356e-05 ***
       ##       841                      
       ## ---
       ## Signif. codes:  
       ## 0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
       
       # Therefore, significantly unequal variances.
       
       # The assumptions of ANOVA are therefore not met. We use Kruskal-Wallis instead:
       kruskal.test(LTR ~ Climate,
                    data = dataset_for_plotting)
       
       # KRUSKAL-WALLIS TEST OUTPUT (15TH FEB 2024):
       ## Kruskal-Wallis rank sum test
       ## data:  LTR by Climate
       ## Kruskal-Wallis chi-squared = 355.97, df = 3, p-value < 2.2e-16
       
       # Therefore, significant differences between the four categories in LTR content.
       
       # We therefore now use the Dunn test (post-hoc test following Kruskal-Wallis):
       library(FSA)
       PT = dunnTest(LTR ~ Climate,
                     data = dataset_for_plotting,
                     method="bh") 
       
       # DUNN POST-HOC TEST OUTPUT (15TH FEB 2024):
       ## Dunn (1964) Kruskal-Wallis multiple comparison
       ## p-values adjusted with the Benjamini-Hochberg method.
       ##                            Comparison         Z      P.unadj        P.adj
       ## 1           Humid_tropics - Semi_arid -6.554316 5.589733e-11 6.707679e-11
       ## 2           Humid_tropics - Temperate 13.064873 5.227175e-39 1.568153e-38
       ## 3               Semi_arid - Temperate 14.419314 3.912103e-47 2.347262e-46
       ## 4 Humid_tropics - Temperate_petiolata 10.388230 2.805102e-25 4.207653e-25
       ## 5     Semi_arid - Temperate_petiolata 12.882249 5.666040e-38 1.133208e-37
       ## 6     Temperate - Temperate_petiolata  4.847020 1.253295e-06 1.253295e-06
       
       # Since Dunn pairwise comparisons find significant effects, *manually* plot the significance letters on the graph using the following:
       
       LTRplot.annotation <- data.frame(
         x = c(1, 2, 3, 4),
         y = c(5+max(humid_tropics_juncea_only_results$LTR),
               5+max(semi_arid_juncea_only_results$LTR),
               5+max(temperate_juncea_only_results$LTR),
               5+max(petiolata_only_results$LTR)),
         label = c("d","c","b","a"))
       
       # Add text
       LTR.boxplot <- my_plot + 
         geom_text(data=LTRplot.annotation, 
                   aes(x=x, y=y, label=label),
                   size=4)
       LTR.boxplot + coord_flip()
       
       
       # For reporting the means and standard deviations of categories:
       mean(juncea_only_results$LTR)     
       ## 26.14001
       sd(juncea_only_results$LTR)
       ## 5.324051
       
       mean(semi_arid_juncea_only_results$LTR)             
       ## 31.54773
       sd(semi_arid_juncea_only_results$LTR)
       ## 3.657366
       
       mean(petiolata_only_results$LTR) 
       ## 13.36271
       sd(petiolata_only_results$LTR) 
       ## 1.572179
       
       # On average, how much of the juncea genome was detected as repetitive?
       mean(100-juncea_only_results$`Non-repetitive`)
       ## 43.55264
       sd(100-juncea_only_results$`Non-repetitive`)
       ## 5.718339
       
       # On average, how much of the petiolata genome was detected as repetitive?
       mean(100-petiolata_only_results$`Non-repetitive`)
       ## 26.18847
       sd(100-petiolata_only_results$`Non-repetitive`)
       ## 1.991448
       
      
