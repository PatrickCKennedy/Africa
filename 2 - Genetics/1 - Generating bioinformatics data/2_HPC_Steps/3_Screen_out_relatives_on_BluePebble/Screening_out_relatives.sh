# This is a very quick script that you should run *manually* in the HPC terminal after the completion of Relatedness_on_BluePebble.sh

# -----------------------------------------------------------------------------
# WHAT THIS SCRIPT DOES:
# You will already have run Relatedness_on_BluePebble.sh for the population of interest (e.g., 'Somalomo' or 'Yaounde1'), which will have generated a file called 'newres'. This contains the pairwise relatedness estimations for everyone in this population. For population genetics questions about demography, it is important to remove relatives from analysis. Therefore, before running the population genetics scripts (such as PCANGSD_on_BluePebble.sh), you need to run this quick script, which uses the 'newres' output to screen out relatives. The output is a text file called 'nonrelatives.bam.filelist', which should be used instead of bam.filelist for all downstream population genetics questions.
# -----------------------------------------------------------------------------

# Go to ANGSD_results folder inside the population of interest (e.g., 'Cameroon/Somalomo'):
cd /user/work/pk14885/Wasps/Completed_alignments/SouthAfrica/Vusumuzi/ANGSD_results

# Load R:
module load lang/r/4.3.0-gcc
R --vanilla

# We are now in an interactive session in R. The following script is therefore R code:

# - - - - - - - - - - - - - R INTERACTIVE SESSION - - - - - - - - - - - - - - - -

# R script for running on BluePebble, to screen out relatives after generating the 'newres' file. The output (comprising non-relatives only) can then be used for population genetics.

newres <- read.delim('newres', header=TRUE)

# Make sure that the relatedness column is in numeric format (to avoid entries in scientific notation being treated as strings):
newres$rab <- as.numeric(newres$rab)

# Make a list of individuals to exclude (one member of each pair with a relatedness greater than a chosen threshold). For instance, in Polistes dominula, Miller et al. (2020) "removed one individual from each pair of samples with kinship coefficients >0.1" (https://academic.oup.com/gbe/article/12/5/701/5818492):
my_Relatedness_Threshold <- 0.12
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

# At this point, the list 'ToKeep' could still contain relatives, who were missed because they were spuriously given a low relatedness value because nSites in their pairwise comparisons was very low. As in the main relatedness analysis script, we need to screen out this small minority of samples. To do that, we go through the list and ask whether any of them have an average nSites < nSites_Threshold:
nSites_list_a <- cbind(newres$ida, newres$nSites)
nSites_list_b <- cbind(newres$idb, newres$nSites)
nSites_list <- rbind(nSites_list_a, nSites_list_b)
ToKeep$mean_nSites <- NA
for (i in 1:dim(ToKeep)[1]){
        this_wasp <- ToKeep[i,1]
        ToKeep[i,]$mean_nSites <- mean(subset(newres, ida == this_wasp)$nSites)
} # end of loop through each wasp.
# Now remove any individuals that have a mean nSites below nSites_Threshold:
nSites_Threshold <- 250000
ToKeep <- subset(ToKeep, mean_nSites > nSites_Threshold)

# Output a text file for BluePebble to use as the input for population genetics analyses
# for this population (i.e., this is a bam.filelist with only non-relatives remaining):
write.table(ToKeep, file = 'nonrelatives.bam.filelist.txt', sep = "\t", row.names = FALSE, col.names = FALSE, quote = FALSE)

# Now end the interactive R session: 
quit()

# - - - - - - - - - - - - END OF R INTERACTIVE SESSION - - - - - - - - - - - - - - -

# There should now be a file in the ANGSD_results folder for this population, called 'nonrelatives.bam.filelist.txt'.

# So far, it is a list of the bam files to use. Because we are going to pass this to the PCANGSD_on_HPC.sh script next, which works on the country as a whole (i.e., SouthAfrica or Cameroon), we need to add in the path to the relevant population.

# We are currently inside the 'ANGSD_results' folder of the population of interest. To obtain the population name, we just obtain the name of the population folder:
cd ..
POPULATION=$(basename "$PWD")
cd ANGSD_results

# We can now add that to the 'nonrelatives.bam.filelist.txt' file:
cat nonrelatives.bam.filelist.txt | sed 's/^/\//' > ${POPULATION}.nonrelatives.bam.filelist.txt
sed -i -e 's/^/'${POPULATION}'/' ${POPULATION}.nonrelatives.bam.filelist.txt

# Move that file to the overview folder for the country of interest:
mv ${POPULATION}.nonrelatives.bam.filelist.txt ../../

# This population is now ready for joining the general PCANGSD run on this country (which takes place in the 'PCANGSD_on_HPC.sh' script).
# ------------------------------------------------------------------------





