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
  geom_hline(yintercept = 0, linetype = "dashed") +
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

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "my_inbreeding_plot.svg", 
       plot = my_inbreeding_plot, 
       height = 4,
       width = 2, dpi = 200)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.

# ------------------------------------------------------------------------------
# DO THE CLIMATE ZONES DIFFER IN INBREEDING?

# Statistics on heterozygosity data:

# Following https://jontalle.web.engr.illinois.edu/MISC/lme4/bw_LME_tutorial.pdf:
# Null model:
library(lme4)
my1.null = lmer(inbreeding_coefficient  ~ (1|PopulationLabels), data = Combined_inbreeding_dataset)
# Model with climate as a fixed effect:
my1.model = lmer(inbreeding_coefficient  ~ Climate + (1|PopulationLabels), data = Combined_inbreeding_dataset)
# Comparison of null and actual model (likelihood ratio test step) 
# Note: the anova() function "does not actually compute an analysis of variance, but is a convenient
# function for conducting a likelihood ratio test" (https://journals.sagepub.com/doi/10.1177/2515245920960351)
anova(my1.null,my1.model)
          # Likelihood-ratio test (using 'anova()' function) output (8th May 2024):
                ## refitting model(s) with ML (instead of REML)
                ## Data: Combined_inbreeding_dataset
                ## Models:
                ## my1.null: inbreeding_coefficient ~ (1 | PopulationLabels)
                ## my1.model: inbreeding_coefficient ~ Climate + (1 | PopulationLabels)
                ##           npar     AIC     BIC logLik deviance  Chisq Df Pr(>Chisq)  
                ## my1.null     3 -187.46 -179.41 96.729  -193.46                       
                ## my1.model    5 -189.68 -176.27 99.841  -199.68 6.2235  2    0.04452 *
                ##   ---
                ##   Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
                ## summary(my1.model)

# P: From this table, you should report the chi squared value, the degrees of freedom, and the p-value.
# P: You should get the same result when using the 'mixed()' function, which is what you would use if
# you had multiple fixed effects to consider (see: https://journals.sagepub.com/doi/10.1177/2515245920960351)
library(afex)
mixed(inbreeding_coefficient  ~ Climate + (1|PopulationLabels), data = Combined_inbreeding_dataset, method= "LRT")

summary(my1.model)
library(report)
report(my1.model)
          # "report" function output: LINEAR MIXED MODEL REPORT (2ND MAY 2024):
                ## "boundary (singular) fit: see help('isSingular')
                ## Random effect variances not available. Returned R2 does not account for random effects.
                ## boundary (singular) fit: see help('isSingular')
                ## Random effect variances not available. Returned R2 does not account for random effects.
                ## We fitted a linear mixed model (estimated using REML and nloptwrap optimizer) to predict inbreeding_coefficient with Climate (formula:
                ##                                                                                                                                 inbreeding_coefficient ~ Climate). The model included PopulationLabels as random effect (formula: ~1 | PopulationLabels). The model's explanatory
                ## power related to the fixed effects alone (marginal R2) is 0.06. The model's intercept, corresponding to Climate = Humid tropics, is at -0.04 (95%
                ##                                                                                                                                               CI [-0.06, -0.01], t(103) = -2.99, p = 0.004). Within this model:
                ##   
                ## - The effect of Climate [Semi arid] is statistically non-significant and negative (beta = -0.03, 95% CI [-0.08, 0.02], t(103) = -1.09, p = 0.279;
                ##                                                                                      Std. beta = -0.27, 95% CI [-0.77, 0.22])
                ## - The effect of Climate [Temperate] is statistically significant and negative (beta = -0.06, 95% CI [-0.11, -0.01], t(103) = -2.56, p = 0.012;
                ##                                                                                Std. beta = -0.63, 95% CI [-1.11, -0.14])
                ## 
                ## Standardized parameters were obtained by fitting the model on a standardized version of the dataset. 95% Confidence Intervals (CIs) and p-values
                ## were computed using a Wald t-distribution approximation."
library(car) 
myANOVA <- Anova(my1.model, test="F") # Obtain p-value from ANOVA in the model.
report(myANOVA)
          ## "report" output: ANOVA OUTPUT (8th MAY 2024)
                ## The ANOVA suggests that:
                ##  
                ##- The main effect of Climate is statistically not significant and large (F(2) = 2.97, p = 0.166; Eta2 (partial) = 0.61, 95% CI [0.00, 1.00])
                ##
                ## Effect sizes were labelled following Field's (2013) recommendations.
library(emmeans)
myTukey <- emmeans(my1.model, list(pairwise ~ Climate), adjust = "tukey")
myTukey
plot(myTukey, comparisons = TRUE)
          # emmeans OUTPUT: TUKEY POST-HOC TEST OUTPUT (8th MAY 2024):
                ## $`emmeans of Climate`
                ## Climate        emmean     SE    df lower.CL  upper.CL
                ## Humid tropics -0.0355 0.0127  3.95  -0.0711  6.80e-06
                ## Semi arid     -0.0626 0.0218  1.81  -0.1666  4.15e-02
                ## Temperate     -0.0980 0.0220 26.21  -0.1431 -5.28e-02
                ## 
                ## Degrees-of-freedom method: kenward-roger 
                ## Confidence level used: 0.95 
                ## 
                ## $`pairwise differences of Climate`
                ## 1                         estimate     SE    df t.ratio p.value
                ## Humid tropics - Semi arid   0.0270 0.0252  2.11   1.071  0.6098
                ## Humid tropics - Temperate   0.0625 0.0254 14.22   2.459  0.0663
                ## Semi arid - Temperate       0.0354 0.0309  4.51   1.145  0.5348
                ## 
                ## Degrees-of-freedom method: kenward-roger 
                ## P value adjustment: tukey method for comparing a family of 3 estimates 


