#!/bin/bash

#SBATCH --job-name=kmers
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G
#SBATCH --time=0-05:00:00
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# PK
# k-mer estimation for genome size prediction
# Following https://bioinformatics.uconn.edu/genome-size-estimation-tutorial/

# Load 'jellyfish' on BluePebble:
module load apps/jellyfish/2.3.0 

# Set working directory to folder on BluePebble containing the read files for the wasp of interest:
cd /user/work/pk14885/Wasps_Dec2023

myForwardRead="A4_2_3_Cameroon_EKDL230052137-1A_22GGMJLT3_L7_1_val_1.fq.gz"
myReverseRead="A4_2_3_Cameroon_EKDL230052137-1A_22GGMJLT3_L7_2_val_2.fq.gz"

# Run 'jellyfish' on the target wasp's forward and reverse read files:
jellyfish count -t 8 \
-C -m 19 -s 6G \
-o 19mer_out \
--min-qual-char=? \
<(zcat $myForwardRead) <(zcat $myReverseRead)

# The output will be called '19mer_out.histo'. Generate a histogram:
jellyfish histo -o 19mer_out.histo 19mer_out

# Hmmm, the histogram doesn't have a peak - it just descends. Following that tutorial, it therefore isn't clear how to estimate 
# a genome size. We could instead try using the 'RESPECT' programme (https://github.com/shahab-sarmashghi/RESPECT), which seems to be 
# for low-coverage data.

