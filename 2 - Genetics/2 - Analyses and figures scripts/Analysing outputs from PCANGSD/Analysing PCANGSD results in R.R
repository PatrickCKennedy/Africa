# Patrick
# R SCRIPT FOR ANALYSING THE GENERAL PCANGSD RESULTS ON THE LOCAL COMPUTER AFTER ALL-POPULATIONS HPC SCRIPT HAS COMPLETED

# Before running this script, you should have completed the script 'PCANGSD_across_all_populations_BluePebble.sh'
# on HPC. The result of that script is a folder called 'juncea_PCANGSD_results_for_both_countries_together'.
# Download that folder to the local computer. This script uses the downloaded folder on the local computer.

# Set RStudio's working directory to the downloaded folder:
setwd("/Users/pk14885/Downloads/juncea_PCANGSD_results_for_both_countries_together")

# --------------------------------------
# (1) PCA PLOT OF THE SAMPLES
# following http://www.popgen.dk/software/index.php/PCAngsdTutorial:

# After running PCANGSD on BluePebble, download the .cov file from BluePebble.

cov <- as.matrix(read.table("output.for.pca.in.R.pcangsd.tree.cov")) # Reads in estimated covariance matrix
e<-eigen(cov)
WaspNameList<-read.table("WaspNameList",head=F)
PopulationLabels<-read.table("PopulationLabels",head=F)

my_e_to_plot <- as.data.frame(e$vectors[,1:2])
my_e_to_plot$V3 <- PopulationLabels
my_e_to_plot[my_e_to_plot$V3 == "Douala",4] = "Humid tropics"
my_e_to_plot[my_e_to_plot$V3 == "Maroua",4] = "Semi arid"
my_e_to_plot[my_e_to_plot$V3 == "Mbouda",4] = "Humid tropics"
my_e_to_plot[my_e_to_plot$V3 == "Messa",4] = "Humid tropics"
my_e_to_plot[my_e_to_plot$V3 == "Soa",4] = "Humid tropics"
my_e_to_plot[my_e_to_plot$V3 == "Douala",4] = "Humid tropics"
my_e_to_plot[my_e_to_plot$V3 == "Somalomo",4] = "Humid tropics"
my_e_to_plot[my_e_to_plot$V3 == "Yaounde1",4] = "Humid tropics"
my_e_to_plot[my_e_to_plot$V3 == "AfricanLaboratory",4] = "Temperate"
my_e_to_plot[my_e_to_plot$V3 == "LoversRock",4] = "Temperate"
my_e_to_plot[my_e_to_plot$V3 == "Cowshed",4] = "Temperate"
my_e_to_plot[my_e_to_plot$V3 == "PeterRobertsFarm",4] = "Temperate"
my_e_to_plot[my_e_to_plot$V3 == "Pumphouse",4] = "Temperate"
my_e_to_plot[my_e_to_plot$V3 == "TrudiesFarm",4] = "Temperate"
my_e_to_plot[my_e_to_plot$V3 == "Vusumuzi",4] = "Temperate"
my_e_to_plot[my_e_to_plot$V3 == "ZebraHouse",4] = "Temperate"


my_e_to_plot[,5] <- WaspNameList
my_e_to_plot <- as.data.frame(as.matrix(my_e_to_plot))
library(ggplot2)
ggplot(my_e_to_plot, aes(x=as.numeric(V1), y=as.numeric(V2), col = as.factor(V4))) +
        geom_point() + geom_text(aes(label=V1.1), size=3)




# --------------------------------------
# (2) NJ TREE

library(ape)
library(phytools)

output.for.pca.in.R.pcangsd <- read.csv("output.for.pca.in.R.pcangsd.tree", header=FALSE, sep=";") 
my_text_tree <- output.for.pca.in.R.pcangsd[1,1]
my_text_tree <- paste(my_text_tree,";",sep="")   # Tree data must end in a semi-colon.
wasp.tree<-read.tree(text=my_text_tree)


DF <- as.data.frame(unclass(tree),stringsAsFactors=TRUE)













# ------------------------------------------------------------------
# (2) SELECTION SCAN (MANHATTAN PLOT), following http://www.popgen.dk/software/index.php/PCAngsdTutorial:

# Load the 'RcppCNPy' package (which allows R to read Numpy matrices):
library(RcppCNPy)

# After running PCANGSD with the '--selection' option, import the '...selection.npy' file into R:
s <- npyLoad("output.selection.pcangsd.selection.npy") # Reads PC based selection statistics

# Make a QQ plot "to QC the test statistics" (http://www.popgen.dk/software/index.php/PCAngsdTutorial)
qqchi(s) # This takes a while to run.

# "Convert test statistic to p-value" 
pval<-1-pchisq(s,1)

## "Read positions" (http://www.popgen.dk/software/index.php/PCAngsdTutorial):
# (This also takes quite a long time to run.)
p<-read.table("output.selection.pcangsd.sites",colC=c("factor","integer"),sep="_")

# To avoid errors, I think we need to convert this to a dataframe:
p <- as.data.frame(p)

# Rename the column headers:
names(p)<-c("chr","pos")

## make manhatten plot
plot(-log10(pval),col=p$chr,xlab="Chromosomes",main="Manhattan plot")



# Following https://github.com/pinskylab/codEvol/blob/master/scripts/angsd_pcangsd_plot_selection.R:

library(data.table)
