#!/bin/bash
#SBATCH --job-name=Patrick_ANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=0-00:00:10
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# -----------------------------------------------------------------------------
# WHAT THIS SCRIPT DOES:
# You will already have run ANGSD_on_BluePebble.sh for the population of interest (e.g., 'Somalomo' or 'Yaounde1'), which will have generated a file called 'newres'. This contains the pairwise relatedness estimations for everyone in this population. For population genetics questions about demography, it is important to remove relatives from analysis. Therefore, before running the population genetics scripts (such as PCANGSD_on_BluePebble.sh), you need to run this quick script, which uses the 'newres' output to screen out relatives. The output is a text file called 'nonrelatives.bam.filelist', which should be used instead of bam.filelist for all downstream population genetics questions.
# -----------------------------------------------------------------------------

# Go to the population of interest (e.g., 'Somalomo'):
cd /user/work/pk14885/Wasps/Completed_alignments/Cameroon/Somalomo/ANGSD_results

# Load R:
module load lang/r/4.0.1
R --vanilla

# We are now in an interactive session in R. The following script is therefore R code:

# - - - - - - - - - - - - - R INTERACTIVE SESSION - - - - - - - - - - - - - - - -

# R script for running on BluePebble, to screen out relatives after generating the 'newres' file. The output (comprising non-relatives only) can then be used for population genetics.

newres <- read.delim('newres', header=TRUE)

# Make a list of individuals to exclude (one member of each pair with a relatedness
# greater than a chosen threshold):
my_Relatedness_Threshold <- 0.06
CloseRelatedness <- subset(newres, newres$rab > my_Relatedness_Threshold)

# These are, therefore, the individuals to remove from the list, as they are relatives
# of others in the list:
RelativesToRemove <- unique(CloseRelatedness$idb)
RelativesToRemove <- as.data.frame(RelativesToRemove)

# The total number of individuals to remove is:
dim(RelativesToRemove)[1]

new_df = subset(newres, select = c(ida, idb))
AllWaspsList <- unique(stack(new_df))
AllWaspsList <- AllWaspsList$values
AllWaspsList <- as.data.frame(AllWaspsList)

ToKeep <- AllWaspsList[!(AllWaspsList$AllWaspsList %in% RelativesToRemove$RelativesToRemove),]
ToKeep <- as.data.frame(ToKeep)
ToKeep <- unique(ToKeep)

# Output a text file for BluePebble to use as the input for population genetics analyses
# for this population (i.e., this is a bam.filelist with only non-relatives remaining):
write.table(ToKeep, file = 'nonrelatives.bam.filelist.txt', sep = "\t", row.names = FALSE, col.names = FALSE, quote = FALSE)

# Now end the interactive R session:
quit()

# - - - - - - - - - - - - END OF R INTERACTIVE SESSION - - - - - - - - - - - - - - -

# There should now be a file in the ANGSD_results folder for this population, called 'nonrelatives.bam.filelist.txt'.

