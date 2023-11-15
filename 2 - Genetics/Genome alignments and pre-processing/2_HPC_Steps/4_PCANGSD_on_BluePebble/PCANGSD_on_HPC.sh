#!/bin/bash
#SBATCH --job-name=Patrick_ANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=120G
#SBATCH --time=8-120:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=patrick.kennedy@bristol.ac.uk
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# ---- POPULATION GENOMICS VIEW OF THE COUNTRY AS A WHOLE -----

# WHAT THIS SCRIPT DOES:

# This script works on a country as a whole (i.e., either SouthAfrica or Cameroon). It runs two main programmes: PCANGSD and NGSadmix. Before running them, it produces a beagle file for the country of interest using ANGSD, which serves as the input file for both PCANGSD and NGSadmix.

# WHY PCANGSD?
# PCANGSD generates the data for plotting a PCA in R. It can also be used for looking at selection and inbreeding (see below).

# WHY NGSadmix?
# NGSadmix generates the data for plotting an admixture plot in R.

# Set the working directory to the country of interest:
cd /user/work/pk14885/Wasps/Completed_alignments/SouthAfrica

# -------------------------------------------------------------
# THIS SECTION RECORDS WHICH COUNTRY WE ARE FOCUSING ON:

# Print the following information to the SLURM output:
echo
echo "This is the script 'PCANGSD_on_HPC.sh'."
echo
echo "Country:"
this_COUNTRY=$(basename "$PWD")
echo $this_COUNTRY
echo
echo "Start time:"
now=$(date)
echo $now
echo

# -------------------------------------------------------------
# FOCUS JUST ON NON-RELATIVES WITHIN EACH POPULATION:

# This script is designed to be run on multiple populations. So the working directory should be either Cameroon or South Africa. Within the working directory, there should be a folder for each population (e.g., 'Somalomo'), and inside each folder should be the relevant bam (and bai) files.

# Before running this script, you must run the quick code in 'Screening_relatives_on_HPC.sh' manually in each of the populations of interest. Once this has been completed, there will be a file for each population in the country's folder (e.g., 'Somalomo.nonrelatives.bam.filelist.txt').

# We therefore merge all the *.nonrelatives.bam.filelist.txt files in the country's main folder:
# I HAVEN'T TESTED THIS LINE YET:
rm Nonrelatives.all.populations.bam.filelist
cat *.nonrelatives.bam.filelist.txt >> Nonrelatives.all.populations.bam.filelist

# Print all the wasps of interest:
echo
echo "Wasps involved in this analysis:"
cat Nonrelatives.all.populations.bam.filelist
echo

# Record the sample size:
echo
echo "Total number of wasps in this analysis:"
file_count=$(cat Nonrelatives.all.populations.bam.filelist | wc -l)
echo $file_count

# We will use the 'file_count' variable below, when we set -minInd in the angsd function to discard sites if fewer than half the individuals have data for it:
    my_minInd=$(($file_count/2))
    # NOTE ON 15TH MAY 2023: I'm getting nonsensical results on the resulting PCA. I wonder if it might be due to minInd. So I have just deleted -minInd from the angsd function. To put it back in, add '-minInd $my_minInd'.
    
# Generate a text file in which the first column contains the population and the second column contains the file name (we just replace the backslash in each line with a space, making the two columns):
    sed 's/\// /' Nonrelatives.all.populations.bam.filelist > PopulationList
    
# For a summary table of how many samples are in each population (following http://www.popgen.dk/software/index.php/NgsAdmixTutorial#Plot_the_results_in_R):
    cut -f 1 -d " " PopulationList | sort | uniq -c
    
# It is also helpful to have a text file that gives the wasp's name, rather than the full bam file name. Every bam file has "_CKDL" after the wasp name, followed by a code that came from Novogene. To list just the wasps' names, we can delete everything in the text that comes after "_CKDL":
    sed 's/_CKDL.*//' PopulationList > WaspNameList
    # The output here is 'WaspNameList', a text file in which each row is a wasp: the first column is the population and the second column is the wasp name. Note that some of the wasp names are in color codes, so you still need to go through the colour codes to make sure there are not duplicated individuals; if there are, their bam files should be merged.

# Make a population label file (following http://www.popgen.dk/software/index.php/NgsAdmixTutorial#Plot_the_results_in_R). We will use this in the NGSadmix part of the script below:
    cut -f1 -d" " PopulationList > PopulationLabels

# Make a folder for this wasp called 'ANGSD_results':
	mkdir ANGSD_results
 
 # Provide the reference genome:
    REF="/user/work/pk14885/3_Patrick_Indexed_ref_using_BWA/B_junceaGenome.FINAL.fasta"

# -------------------------------------------------------------
# A SINGLE FUNCTION FOR QUALITY-FILTERING AND OBTAINING GENOTYPE LIKELIHOODS

# Load ANGSD on BluePebble:
module load apps/angsd

# Run ANGSD to generate the beagle file (which is the input for PCANGSD and NGSadmix below). -doGlf 3 ensures that a beagle file is generated:
angsd -bam Nonrelatives.all.populations.bam.filelist \
    -ref $REF  \
    -out ./ANGSD_results/my_Angsd_file \
    -remove_bads 1 \
    -only_proper_pairs 1 \
    -C 50 \
    -baq 1 \
    -minQ 20 \
    -minMapQ 20 \
    -GL 1 \
    -doGlf 2 \
    -doMaf 1 \
    -minmaf 0.05 \
    -doMajorMinor 1 \
    -snp_pval 1e-6 \
    -nThreads 8

# Here, we have applied some filters. This is what the tutorial says:
# "These filters will retain only uniquely mapping reads, not tagged as bad, considering only proper pairs, without trimming, and adjusting for indel/mapping (as in samtools). -C 50 reduces the effect of reads with excessive mismatches, while -baq 1 computes base alignment quality as explained here (BAQ) used to rule out false SNPs close to INDELS. Also, you may want to remove reads with low mapping quality and sites with low quality or covered by few reads (low depth). Under these circumstances, the assignment of individual genotypes and SNPs is problematic, and can lead to errors. We may also want to remove sites where a fraction (half?) of the individuals have no data. This is achieved by the -minInd option." (https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial2_genotype_snp_calling/markdowns/snp_calling.md)

	# For minInd, I think we should set this value to half of the samples we have. So you would need to change this to 200, for instance, if looking at 400 individuals in total.

	# CHOOSING THE RIGHT OPTION FOR GENOTYPE LIKELIHOOD FUNCTION (THE GL COMMAND IN THE FUNCTION ABOVE).
	# These are the options:

			#-GL=0: 
			#    1: SAMtools
			#    2: GATK
			#    3: SOAPsnp
			#    4: SYK
			#    5: phys
			#    6: Super simple sample an allele type GL. (1.0,0.5,0.0)
			#    7: outgroup gls

		# For an explanation of the options, see here: http://www.popgen.dk/angsd/index.php/Genotype_Likelihoods

		# Note: "The GATK model refers to the first GATK paper, SAMtools is somehow more sophisticated (non-independence of errors), SOAPsnp requires a reference sequence for recalibration of quality scores, SYK is error-type specific. For most applications and data, GATK and SAMtools models should give similar results." (https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial2_genotype_snp_calling/markdowns/snp_calling.md)

# -------------------------------------------------------------
# PCANGSD:
# Before running PCANGSD, you need to generate a Beagle file using ANGSD. The following assumes that you have already completed that step.

cd ANGSD_results

module add lang/python/anaconda/3.8.8-2021.05-2.5
source activate pcangsd

# Running PCAngsd:

# See all options
pcangsd -h

# Report current step:
echo
echo "P: Now about to run PCANGD to generate a covariance matrix for making the PCA in R."
echo

# Run PCANGSD to generate covariance matrix ready for making the PCA in R:
pcangsd -b my_Angsd_file.beagle.gz -o output.pcangsd -t 4

# You can now use the output file to produce a PCA plot in R, following http://www.popgen.dk/software/index.php/PCAngsdTutorial#Plot_the_results_in_R:
# First, download the output (from outside BluePebble) using the following (adjust for Cameroon or South Africa):
##          scp pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/SouthAfrica/ANGSD_results/output.pcangsd.cov output.pcangsd.cov
##

# -------------------------------------------------------------
# DIFFERENT ANALYSES WITH PCANGSD
# following https://github.com/therkildsen-lab/genomic-data-analysis/blob/master/scripts/run_pcangsd.sh

# Selection analysis with PCANGSD:
    ##pcangsd -b my_Angsd_file.beagle.gz --selection --minMaf 0.05 -t 64 -o output.selection.pcangsd --sites_save
    
# PCA analysis with PCANGSD:
    ##pcangsd -b my_Angsd_file.beagle.gz -e 2 -t 64 --tree --tree_SAMPLES ../bam.filelist -o output.pcangsd
    # Genotype likelihood file in Beagle format with 2 eigenvectors using 64 threads
    # 10TH MAY: I'VE JUST ADDED IN THE --tree COMMAND TO ALSO GENERATE A NEIGHBOUR-JOINING TREE. HOPEFULLY IT DOESN'T MESS UP THE PCANGSD COMMAND. This paper (https://www.cell.com/current-biology/pdfExtended/S0960-9822(21)00129-9) plots the resulting tree using the 'ape' package in R.

# Inbreeding analysis with PCANGSD:
    ##pcangsd -b my_Angsd_file.beagle.gz --inbreedSites --minMaf 0.05 -t 64 -o output.inbreeding.pcangsd --sites_save
    # P: For analysing the inbreeding outputs, you can import the two resulting .npy files into R. There are two outputs from the pcangsd function: one seems to be the per-site inbreeding coefficient, and the other seems to the the likelihood ratio test ('lrt') output. Here is my script for plotting them in R: library(RcppCNPy); LRT_results <- npyLoad("output.inbreeding.pcangsd.lrt.sites.npy"); inbreeding <- npyLoad("output.inbreeding.pcangsd.inbreed.sites.npy"); inbreeding <- as.data.frame(inbreeding); hist(inbreeding$inbreeding); LRT_results <- as.data.frame(LRT_results)

# Admix analysis with PCANGSD:
    ##pcangsd -b my_Angsd_file.beagle.gz --admix -e 2 --minMaf 0.05 -t 64 -o output.admix.pcangsd
# P: You should try different values of the 'e' parameter.

# -------------------------------------------------------------
# ADMIXTURE ANALYSIS USING NGSADMIX

# Report current step:
echo
echo "P: Now about tto run NGSadmix to generate an admixture plot."
echo

# You can apparently run NGSadmix as part of ANGSD, but I can't seem to get that to work on BluePebble. Luckily, you can also install it independently on the cluster, which I have done (following the commands at http://www.popgen.dk/software/index.php/NgsAdmix). Here is the path to where I have installed it on my BluePebble account:
NGSADMIX="/user/work/pk14885/MySoftware/NGSadmix"

# This means that we can run NGSadmix just by typing $NGSADMIX:
$NGSADMIX -likes my_Angsd_file.beagle.gz -K 4 -minMaf 0.05 -seed 1 -o NGSadmix.output -P 10
# You can set the value of 'K' (number of clusters), presumably as the number of populations.

# We then need to follow the scripts online for plotting this in R. Go to 'Plot the results in R' at http://www.popgen.dk/software/index.php/NgsAdmixTutorial#Plot_the_results_in_R




