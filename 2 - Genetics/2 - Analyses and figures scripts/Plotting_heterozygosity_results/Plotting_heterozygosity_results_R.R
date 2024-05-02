# PK

# Import the heterozygosity results (which can be found in the SUPMAT file):
library(readxl)
setwd("/Users/pk14885")
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
       height = 4,
       width = 2.5, dpi = 200)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.

# Statistics on heterozygosity data:

# Following https://jontalle.web.engr.illinois.edu/MISC/lme4/bw_LME_tutorial.pdf:
# Null model:
library(lme4)
my1.null = lmer(`P:Heterozygosity`  ~ (1|Population), data = mydata)
# Model with climate as a fixed effect:
my1.model = lmer(`P:Heterozygosity`  ~ Climate + (1|Population), data = mydata)
# Comparison:
anova(my1.null,my1.model)
                # Output (2nd May 2024):
                ##  Data: mydata
                ##  Models:
                ##  my1.null: `P:Heterozygosity` ~ (1 | Population)
                ##  my1.model: `P:Heterozygosity` ~ Climate + (1 | Population)
                ##            npar     AIC     BIC logLik deviance  Chisq Df Pr(>Chisq)   
                ##  my1.null     3 -8880.4 -8866.2 4443.2  -8886.4                        
                ##  my1.model    6 -8886.8 -8858.4 4449.4  -8898.8 12.354  3   0.006264 **
                ##    ---
                ##    Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
summary(my1.model)
                # "summary" function output: LINEAR MIXED MODEL (2ND MAY 2024):
                ## Linear mixed model fit by REML. t-tests use Satterthwaite's method ['lmerModLmerTest']
                ## Formula: `P:Heterozygosity` ~ Climate + (1 | Population)
                ##    Data: mydata
                ## 
                ## REML criterion at convergence: -8843.1
                ## 
                ## Scaled residuals: 
                ##     Min      1Q  Median      3Q     Max 
                ## -4.5314 -0.6006 -0.1362  0.4187  4.5383 
                ## 
                ## Random effects:
                ##  Groups     Name        Variance  Std.Dev. 
                ##  Population (Intercept) 4.375e-07 0.0006614
                ##  Residual               1.254e-06 0.0011198
                ## Number of obs: 831, groups:  Population, 17
                ## 
                ## Fixed effects:
                ##                              Estimate Std. Error         df t value Pr(>|t|)    
                ## (Intercept)                 0.0069812  0.0002657 13.2898043  26.275  7.6e-13 ***
                ## ClimateSemi_arid_tropics    0.0014480  0.0006100 21.1613493   2.374   0.0272 *  
                ## ClimateTemperate           -0.0008840  0.0003676 13.2001012  -2.405   0.0315 *  
                ## ClimateTemperate_petiolata -0.0001711  0.0007517 12.4182314  -0.228   0.8237    
                ## ---
                ## Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
                ## 
                ## Correlation of Fixed Effects:
                ##             (Intr) ClmS__ ClmtTm
                ## ClmtSm_rd_t -0.324              
                ## ClimatTmprt -0.723  0.234       
                ## ClmtTmprt_p -0.353  0.115  0.255
library(report)
report(my1.model)
                # "report" function output: LINEAR MIXED MODEL REPORT (2ND MAY 2024):
                ## "We fitted a linear mixed model (estimated using REML and nloptwrap optimizer) to predict P:Heterozygosity with Climate (formula: `P:Heterozygosity` ~ Climate). The
                ## model included Population as random effect (formula: ~1 | Population). The model's total explanatory power is substantial (conditional R2 = 0.41) and the part related
                ## to the fixed effects alone (marginal R2) is of 0.21. The model's intercept, corresponding to Climate = Humid_tropics, is at 6.98e-03 (95% CI [6.46e-03, 7.50e-03],
                ##                                                                                                                                       t(825) = 26.28, p < .001). Within this model:
                ##   
                ## - The effect of Climate [Semi_arid_tropics] is statistically significant and positive (beta = 1.45e-03, 95% CI [2.51e-04, 2.65e-03], t(825) = 2.37, p = 0.018; Std.
                ##                                                                                          beta = 1.03, 95% CI [0.18, 1.87])
                ## - The effect of Climate [Temperate] is statistically significant and negative (beta = -8.84e-04, 95% CI [-1.61e-03, -1.62e-04], t(825) = -2.40, p = 0.016; Std. beta =
                ##                                                                                  -0.63, 95% CI [-1.14, -0.12])
                ## - The effect of Climate [Temperate_petiolata] is statistically non-significant and negative (beta = -1.71e-04, 95% CI [-1.65e-03, 1.30e-03], t(825) = -0.23, p =
                ##                                                                                                0.820; Std. beta = -0.12, 95% CI [-1.17, 0.92])
                ## 
                ## Standardized parameters were obtained by fitting the model on a standardized version of the dataset. 95% Confidence Intervals (CIs) and p-values were computed using a
                ## Wald t-distribution approximation."
library(car) 
myANOVA <- Anova(my1.model, test="F") # Obtain p-value from ANOVA in the model.
report(myANOVA)
                ## "report" output: ANOVA OUTPUT (2ND MAY 2024)
                ## The ANOVA suggests that:
                ##   
                ##   - The main effect of Climate is statistically significant and large (F(3) = 4.82, p = 0.016; Eta2 (partial) = 0.50, 95% CI
                ##                                                                        [0.09, 1.00])
                ## 
                ## Effect sizes were labelled following Field's (2013) recommendations.
library(emmeans)
emmeans(my1.model, list(pairwise ~ Climate), adjust = "tukey")
plot(myTukey, comparisons = TRUE)
                # emmeans OUTPUT: TUKEY POST-HOC TEST OUTPUT (2ND MAY 2024):
                ## $`emmeans of Climate`
                ## Climate              emmean       SE   df lower.CL upper.CL
                ## Humid_tropics       0.00698 0.000267 13.2  0.00640  0.00756
                ## Semi_arid_tropics   0.00843 0.000601 17.7  0.00717  0.00969
                ## Temperate           0.00610 0.000255 13.0  0.00555  0.00665
                ## Temperate_petiolata 0.00681 0.000703 12.2  0.00528  0.00834
                ## 
                ## Degrees-of-freedom method: kenward-roger 
                ## Confidence level used: 0.95 
                ## 
                ## $`pairwise differences of Climate`
                ## 1                                        estimate       SE   df t.ratio p.value
                ## Humid_tropics - Semi_arid_tropics       -0.001448 0.000634 21.0  -2.283  0.1342
                ## Humid_tropics - Temperate                0.000884 0.000369 13.1   2.394  0.1269
                ## Humid_tropics - Temperate_petiolata      0.000171 0.000752 12.3   0.227  0.9956
                ## Semi_arid_tropics - Temperate            0.002332 0.000652 16.8   3.575  0.0115
                ## Semi_arid_tropics - Temperate_petiolata  0.001619 0.000925 14.1   1.751  0.3357
                ## Temperate - Temperate_petiolata         -0.000713 0.000748 12.3  -0.953  0.7774
                ## 
                ## Degrees-of-freedom method: kenward-roger 
                ## P value adjustment: tukey method for comparing a family of 4 estimates 
