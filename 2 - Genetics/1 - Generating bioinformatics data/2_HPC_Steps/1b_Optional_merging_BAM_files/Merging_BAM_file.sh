#!/bin/bash
#SBATCH --job-name=Patrick_BAM_Merging
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --time=0-01:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
# That last line is required due to the January 2023 update to BlueCrystal/BluePebble. BISC020282 is my project code in ACRC ("Social evolution of animal altruism").

# -------------------- MERGING BAM FILES -------------

# WHAT THIS SCRIPT DOES:

# Some wasps were sequenced in multiple wells (e.g., one well with the number code and one well with the colour code). Here, we merge the .no.overlaps.bam files into one for each wasp.

# I will keep a back-up of the separate BAM files in a folder called 'MergingDuplicates' within each population where I run this script.

# -------------------------------------------------------------
# PLACE THE BAM FILES TO BE MERGED IN A SINGLE FOLDER (WITH THE NAME OF THE WASP OF INTEREST):

cd /user/work/pk14885/Wasps/Completed_alignments/WaspsForPSMC/Merging_BAMs_from_same_wasp/KENYA_TT1_2

# Extract the wasp name from the folder name:
this_WASP_NAME=$(basename "$PWD")

# -------------------------------------------------------------
# MERGE THIS WASP'S BAM FILES:

# Load SAMTOOLS:
module load apps/samtools/1.16

# Use samtools 'merge' on the relevant files. The output should have the suffix '_mergedbams.bam':

# Following https://www.biostars.org/p/9864/ :
samtools merge ${this_WASP_NAME}.mergedbams.bam *.bam

# Once merged, index the output file to obtain the .bai file:
samtools index ${this_WASP_NAME}.mergedbams.bam

# -------------------------------------------------------------


