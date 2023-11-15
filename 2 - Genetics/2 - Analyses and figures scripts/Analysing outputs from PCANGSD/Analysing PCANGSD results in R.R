# Patrick
# R script for analysing results after running PCANGSD in BluePebble

# --------------------------------------
# (1) PCA PLOT OF THE SAMPLES
# following http://www.popgen.dk/software/index.php/PCAngsdTutorial:

# After running PCANGSD on BluePebble, download the .cov file from BluePebble.

cov <- as.matrix(read.table("output.pcangsd.cov")) # Reads in estimated covariance matrix

# First, plot a PCA of the samples:


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
