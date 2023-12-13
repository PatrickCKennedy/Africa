#!/bin/bash
#SBATCH --job-name=Cam_Heterozygosity
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G
#SBATCH --time=0-05:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
#SBATCH --array=1-608
# Set this to run for the total number of wasps in the relevant country (e.g., I currently have 233 samples listed in bam.filelist for SouthAfrica, so I would type --array=1-233 above).

# -------------------- GENOME-WIDE HETEROZYGOSITY -------------

# WHAT THIS SCRIPT DOES:

# This is an array job for calculating the genome-wide heterozygosity for each wasp individually.
# It runs on all wasps in the country (including close relatives).

# -------------------------------------------------------------
# SET THE COUNTRY (and also set the array count in the SBATCH code above):

# Choose whether to run this in the SouthAfrica or Cameroon folder on BluePebble:
cd /user/work/pk14885/Wasps/Completed_alignments/Cameroon
 
# -------------------------------------------------------------
# LOAD THE MODULES ON THE CLUSTER:

# If running on BluePebble:
module load apps/angsd/0.941

# -------------------------------------------------------------
# BEFORE RUNNING THIS SCRIPT, MAKE SURE YOU HAVE GENERATED TWO TEXT FILES IT NEEDS TO RUN (THESE ARE A LIST OF THE WASPS THAT THE ARRAY WILL WORK THROUGH): bam.filelist AND WaspNameOnly. TO GENERATE THEM, TYPE THE FOLLOWING LINES MANUALLY FROM THE RELEVANT COUNTRY FOLDER (SouthAfrica OR Cameroon) IN BLUEPEBBLE:

##    ls */*.bam > bam.filelist
##    sed 's/_CKDL.*//' bam.filelist > mytempfile1
##    sed 's/_EKDL.*//' mytempfile1 > mytempfile2
##    sed 's/.*\///' mytempfile2 > WaspNameOnly
##    rm mytempfile1
##    rm mytempfile2
##    mkdir Heterozygosity

# The last line makes a folder to store the results (if it doesn't already exist).
     
# NOTE: In the actual final run, we will need to make sure there are no duplicates (e.g., wasps who appear under both a colour code and a wasp name, as they were sequenced twice).

# -------------------------------------------------------------
# IDENTIFY THE SPECIFIC WASP TARGETTED FOR THIS INSTANCE OF THE ARRAY SCRIPT:

# Allocate a specific wasp to this particular entry of the array job (following https://help.rc.ufl.edu/doc/SLURM_Job_Arrays):
SAMPLE_LIST=($(<bam.filelist))
SAMPLE=${SAMPLE_LIST[${SLURM_ARRAY_TASK_ID}]}
        # The variable $SAMPLE now contains the path to the bam file of interest for this wasp, including the population folder (e.g., Cowshed/CS9_c_CKDL220030015-1A_HK7J7DSX5.no.overlaps.bam)

# Extract the wasp name for this sample:
NAME_LIST=($(<WaspNameOnly))
NAME=${NAME_LIST[${SLURM_ARRAY_TASK_ID}]}
        # The variable $NAME now contains the name for this wasp (e.g., EF3-2).
        
# Print the path and wasp name for the SLURM output file:
echo $SAMPLE
echo $NAME

# -------------------------------------------------------------
# Provide the reference genome:
REF="/user/work/pk14885/3_Patrick_Indexed_ref_using_BWA/B_junceaGenome.FINAL.fasta"

# -------------------------------------------------------------
# CALCULATE GENOME-WIDE HETEROZYGOSITY FOR THE CURRENT WASP:

# Figure 6B in the leopard paper (https://www.cell.com/current-biology/pdfExtended/S0960-9822(21)00129-9) compares genome-wide heterozygosity across different leopard populations in Africa. Here, we will do the same. You can do this for both Cameroon and South Africa, and then plot them together in R. There is a good description of the method in the buffalo paper: https://bio-protocol.org/exchange/minidetail?type=30&id=9005705 (the script for the buffalo paper is here: https://github.com/DeondeJager/Buffalo_PopGenomics/blob/master/02-Data_analysis/12-Genome-wide_Heterozygosity_A_243_14.sh)

# According to http://www.popgen.dk/angsd/index.php/Heterozygosity, the way to calculate heterozygosity in ANGSD is just to calculate the SFS with only a single sample: it is "simply the SFS estimation for single samples".

# "Create saf.idx file in ANGSD" (https://github.com/DeondeJager/Buffalo_PopGenomics/blob/master/02-Data_analysis/12-Genome-wide_Heterozygosity_A_243_14.sh)
angsd -i $SAMPLE \
 -C 50 \
 -ref $REF \
 -anc $REF \
 -dosaf 1 \
 -GL 1 \
 -nThreads 24 \
 -minmapq 30 \
 -minQ 20 \
 -uniqueOnly 1 \
 -remove_bads 1 \
 -only_proper_pairs 1 \
 -out Heterozygosity/$NAME
 
 # Go into the 'Heterozygosity' folder:
 cd Heterozygosity
 
 # Make a folder for storing the outputs (if it doesn't already exist)
 mkdir realSFS_results
 
 # "This is followed by the actual estimation using the realSFS subprogram of ANGSD" (https://github.com/DeondeJager/Buffalo_PopGenomics/blob/master/02-Data_analysis/12-Genome-wide_Heterozygosity_A_243_14.sh)
REALSFS_on_BluePebble="/sw/apps/angsd-0.941/angsd/misc/realSFS"
$REALSFS_on_BluePebble $NAME.saf.idx -P 24 -fold 1 > realSFS_results/$NAME.est.ml

# -------------------------------------------------------------------
# CLEAN-UP BY REMOVING INTERMEDIATE FILES FROM BLUEPEBBLE:

# For each wasp, the process above generates four intermediary files, which are stored in the 'Heterozygosity' folder. Now that we have generated the output of interest ($NAME.est.ml), which is stored in the realSFS_results folder, we can remove these intermediate files:

rm $NAME.arg
rm $NAME.saf.gz
rm $NAME.saf.idx
rm $NAME.saf.pos.gz

# -------------------------------------------------------------------
# CODE TO RUN MANUALLY IN THE BLUEPEBBLE TERMINAL AT THE END OF THE PROCESS:

# ONCE THE ARRAY HAS COMPLETED RUNNING FOR ALL THE WASPS OF INTEREST, TYPE THIS SECTION MANUALLY TO OBTAIN THE HETEROZYGOSITY TABLE.

# In each of the $NAME.est.ml files within the realSFS_results folder, there are two values. The first is the number of homozygous sites for this wasp; the second is its number of heterozygous sites. The proportion of sites that are heterozygous is therefore the second value divided by the sum of both values (see the last lines of https://github.com/DeondeJager/Buffalo_PopGenomics/blob/master/02-Data_analysis/12-Genome-wide_Heterozygosity_A_243_14.sh).

# Once the array job has finished running, manually obtain a text file containing the two values for each wasp by binding these files together. (We start by removing 'Heterozygosity_Results' if it exists from a previous run.) Manually type the following lines from within the relevant realSFS_results folder in BluePebble:

##      rm Heterozygosity_Results
##      cat *.ml >> all.text
##      ls *.ml > my_wasps_list
##      paste my_wasps_list all.text > Heterozygosity_Results

# You can now download the 'Heterozygosity_Results' file from BluePebble by running this from the local laptop terminal (adjust for SouthAfrica or Cameroon):
##      cd /Users/pk14885/Desktop
##      scp pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/SouthAfrica/Heterozygosity/realSFS_results/Heterozygosity_Results Heterozygosity_Results
        
# In R, you can now divide the relevant columns to obtain genome-wide heterozygosity. Plot this.
