#!/bin/bash
#SBATCH --job-name=CaSA_PCANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=120G
#SBATCH --time=2-00:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# -------------------------------------------------------------
# PCANGSD:
# Before running PCANGSD, you need to generate the Beagle file using ANGSD (above). The following assumes that you have already completed that step.

# Activate PCANGSD:
		module add lang/python/anaconda/3.8.8-2021.05-2.5
		source activate pcangsd

# See all options:
		pcangsd -h

# -------------------------------------------------------------
# DIFFERENT POTENTIAL ANALYSES THAT CAN BE RUN WITH PCANGSD
# following https://github.com/therkildsen-lab/genomic-data-analysis/blob/master/scripts/run_pcangsd.sh
# -------------------------------------------------------------
# (1) PCA ANALYSIS WITH PCANGSD:

# Report current step:
echo
echo "P: Now about to generate a covariance matrix and neighbour joining tree for subsequent plotting in a PCA plot and tree in R:"
echo

# Make sure we are in the right directory:
		cd /user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_both_countries_together

# Run PCANGSD to generate covariance matrix (and tree data) ready for making the PCA (and tree) in R:
		pcangsd -b my_Angsd_file.beagle.gz -t 4 --tree --tree_samples ../WaspNameList -o output.for.pca.in.R.pcangsd
   # 10TH MAY: I'VE JUST ADDED IN THE --tree COMMAND TO ALSO GENERATE A NEIGHBOUR-JOINING TREE. HOPEFULLY IT DOESN'T MESS UP THE PCANGSD COMMAND. This paper (https://www.cell.com/current-biology/pdfExtended/S0960-9822(21)00129-9) plots the resulting tree using the 'ape' package in R.

# You can now use the output file to produce a PCA plot in R, following http://www.popgen.dk/software/index.php/PCAngsdTutorial#Plot_the_results_in_R:
# First, download the output (from outside BluePebble).

# -------------------------------------------------------------
# (2) ADMIXTURE ANALYSIS USING PCANGSD:
# Following https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial3_ld_popstructure/markdowns/pca_admixture.md#2-alternative-approach-covariance-matrix-estimation-with-pcangsd
# and: https://www.popgen.dk/software/index.php/PCAngsdTutorial#Demo_1:_Allele_Frequencies

# Report current step:
echo
echo "P: Now about to run admixture analysis using PCANGSD:"
echo

# Run PCANGSD to conduct admixture analysis (leaving K unspecified so that PCANGSD will automatically infer the most likely value):
	pcangsd -b my_Angsd_file.beagle.gz --admix -o PCANGSD_admixture_outputs --admix_alpha 50

# -------------------------------------------------------------
# (3) INBREEDING ANALYSIS USING PCANGSD:

# Report current step:
echo
echo "P: Now about run inbreeding analysis using PCANGSD:"
echo

# Inbreeding analysis with PCANGSD:
    pcangsd -b my_Angsd_file.beagle.gz --inbreedSites --minMaf 0.05 -t 64 -o output.inbreeding.pcangsd --sites_save

# P: For analysing the inbreeding outputs, you can import the two resulting .npy files into R. There are two outputs from 
# the pcangsd function: one seems to be the per-site inbreeding coefficient, and the other seems to the the likelihood ratio 
#test ('lrt') output. 
# Here is my script for plotting them in R on the local computer: 
##library(RcppCNPy); LRT_results <- npyLoad("output.inbreeding.pcangsd.lrt.sites.npy"); inbreeding <- npyLoad("output.inbreeding.pcangsd.inbreed.sites.npy"); inbreeding <- as.data.frame(inbreeding); hist(inbreeding$inbreeding); LRT_results <- as.data.frame(LRT_results)

# -------------------------------------------------------------
# (4 - OPTIONAL) ADMIXTURE ANALYSIS USING NGSADMIX:

# Report current step:
##echo
##echo "P: Now about to run NGSadmix to generate an admixture plot."
##echo

# You can apparently run NGSadmix as part of ANGSD, but I can't seem to get that to work on BluePebble. Luckily, you can also install it independently on the cluster, which I have done (following the commands at http://www.popgen.dk/software/index.php/NgsAdmix). Here is the path to where I have installed it on my BluePebble account:
##NGSADMIX="/user/work/pk14885/MySoftware/NGSadmix"

# This means that we can run NGSadmix just by typing $NGSADMIX:
##$NGSADMIX -likes my_Angsd_file.beagle.gz -K 4 -minMaf 0.05 -seed 1 -o NGSadmix.output -P 10
# You can set the value of 'K' (number of clusters), presumably as the number of populations.

# We then need to follow the scripts online for plotting this in R. Go to 'Plot the results in R' at http://www.popgen.dk/software/index.php/NgsAdmixTutorial#Plot_the_results_in_R

# -------------------------------------------------------------
# SELECTION ANALYSIS (SUPPRESSED IN THIS SCRIPT, AS SHOULD BE RUN WITHIN A SINGLE COUNTRY):

# Selection analysis with PCANGSD (should only be run within a continuous population, i.e. just one country):
    ##pcangsd -b my_Angsd_file.beagle.gz --selection --minMaf 0.05 -t 64 -o output.selection.pcangsd --sites_save
    
