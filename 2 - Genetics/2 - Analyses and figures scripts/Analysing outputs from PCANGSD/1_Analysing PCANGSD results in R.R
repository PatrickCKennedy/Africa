# Patrick
# R SCRIPT FOR ANALYSING THE GENERAL PCANGSD RESULTS ON THE LOCAL COMPUTER AFTER ALL-POPULATIONS HPC SCRIPT HAS COMPLETED

# Before running this script, you should have completed the script 'PCANGSD_across_all_populations_BluePebble.sh'
# on HPC. The result of that script is a folder called 'juncea_PCANGSD_results_for_both_countries_together'.
# Download that folder to the local computer. This script uses the downloaded folder on the local computer.

# Set RStudio's working directory to the downloaded folder:
setwd("/Users/pk14885/Downloads/juncea_PCANGSD_results_for_both_countries_together")

# -----------------------------------------------------------------------------------
# (1) PCA PLOT OF THE SAMPLES
# following http://www.popgen.dk/software/index.php/PCAngsdTutorial:

# After running PCANGSD on BluePebble, download the .cov file from BluePebble:
cov <- as.matrix(read.table("output.for.pca.in.R.pcangsd.tree.cov")) # Reads in estimated covariance matrix

# Also download the WaspNameList and PopulationLabels files from BluePebble:
WaspNameList<-read.table("WaspNameList",head=F)
PopulationLabels<-read.table("PopulationLabels",head=F)

# Load libraries:
library(ggplot2)
library(ape)
library(phytools)

# Calculate the eigendecomposition:
e<-eigen(cov)

# Prepare inputs to the PCA plot:
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
        
# Percent explained by each dimension (following https://baylab.github.io/MarineGenomics/week-6-principle-component-analyses.html):
        percent_explained <- e$values/sum(e$values)
        percent_explained_by_PC1 <- percent_explained[[1]]*100
        percent_explained_by_PC2 <- percent_explained[[2]]*100
        
# Plot the PCA:
    random_subset_to_label <- sample_n(my_e_to_plot, 40)
ggplot(my_e_to_plot, aes(x=as.numeric(V1), y=as.numeric(V2), col = as.factor(V4))) +
    geom_point() + theme_bw() + 
    labs(
        x = paste("PC1 (",round(percent_explained_by_PC1,1),"%)",sep=""), 
        y = paste("PC2 (",round(percent_explained_by_PC2,1),"%)",sep="")) + scale_fill_manual(values = c("#56ddc5","orange","red"))+ guides(col="none") + guides(fill=guide_legend(title="Climate")) + scale_colour_manual(values = c("#56ddc5","orange","red")) +
    geom_label_repel(data = random_subset_to_label, aes(fill = factor(V4), label = V3),
                     size = 2,
                     max.overlaps = 100,
                     color = 'white', angle = 45,
                     box.padding = 0.1, point.padding = 0.5,
                     segment.color = 'grey50') 

library(ggrepel)
geom_label_repel(aes(fill = factor(V4), label = V3),
                     size = 2,
                     max.overlaps = 100,
                     color = 'white', angle = 45,
                     box.padding = 0.1, point.padding = 0.1,
                     segment.color = 'grey50')
# -----------------------------------------------------------------------------------
# (2) NEIGHBOUR-JOINING TREE:

# Prepare inputs for the tree:
        output.for.pca.in.R.pcangsd <- read.csv("output.for.pca.in.R.pcangsd.tree", header=FALSE, sep=";") 
        my_text_tree <- output.for.pca.in.R.pcangsd[1,1]
        my_text_tree <- paste(my_text_tree,";",sep="")   # Tree data must end in a semi-colon.
        wasp.tree<-read.tree(text=my_text_tree)

# Plot the resulting tree:
        plot(wasp.tree)

# Plot the resulting tree as an unrooted tree:
        plot(unroot(wasp.tree),type="unrooted",cex=0.5,
             use.edge.length=TRUE,lab4ut="axial",
             no.margin=TRUE)

# -----------------------------------------------------------------------------------
# (3) PLOT THE ADMIXTURE PLOT:

# Load packages:
library(RcppCNPy)

q <- npyLoad("PCANGSD_admixture_outputs.admix.3.Q")

q <- read.table("PCANGSD_admixture_outputs.admix.3.Q", quote="\"", comment.char="")

## order according to population
ord<-order(PopulationLabels[,1])
barplot(t(q)[,ord],col=2:10,space=0,border=NA,xlab="Individuals",ylab="Admixture proportions")
text(tapply(1:nrow(PopulationLabels),PopulationLabels[ord,1],mean),-0.05,unique(PopulationLabels[ord,1]),xpd=T)
abline(v=cumsum(sapply(unique(PopulationLabels[ord,1]),function(x){sum(PopulationLabels[ord,1]==x)})),col=1,lwd=1.2)



## order according to population
barplot(t(q),col=2:10,space=0,border=NA,xlab="Individuals",ylab="Admixture proportions")
text(tapply(1:nrow(PopulationLabels),PopulationLabels[,1],mean),-0.1,sort(unique(PopulationLabels[,1])),xpd=T, cex = 0.5)
abline(v=cumsum(sapply(unique(PopulationLabels[,1]),function(x){sum(PopulationLabels[,1]==x)})),col=1,lwd=1.2)







q$V4 <- WaspNameList

library(tidyverse)
plot_data <- q %>% 
  mutate(id = V4) %>% 
  gather('pop', 'prob', V1:V3) %>% 
  group_by(id) %>% 
  mutate(likely_assignment = pop[which.max(prob)],
         assingment_prob = max(prob)) %>% 
  arrange(likely_assignment, desc(assingment_prob)) %>% 
  ungroup() %>% 
  mutate(id = forcats::fct_inorder(factor(id)))

ggplot(plot_data, aes(id, prob, fill = pop)) +
  geom_col() +
  theme_classic()






#open R
pop<-read.table("pop.info")

C <- as.matrix(read.table("input.cov"))
 e <- eigen(C)
plot(e$vectors[,1:2],col=pop[,1],xlab="PC1",ylab="PC2")
legend("top",fill=1:5,levels(pop[,1]))
## close R













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
