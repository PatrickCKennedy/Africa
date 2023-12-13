#!/bin/bash

#SBATCH --job-name=kmers_RESPECT
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G
#SBATCH --time=0-05:00:00
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# PK
# k-mer estimation for genome size prediction using the 'RESPECT' algorithm
# Citation: https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009449
# Software on GitHub: https://github.com/shahab-sarmashghi/RESPECT

# I am following the instructions at that GitHub link.
# I am currently on number 4 - getting a Gurobi academic licence. 
# I've registered on the Gurobi website. To be issued a licence, I
# just need to be connected to the university internet I make the request on
# the website. Continue.






# Set working directory to folder on BluePebble containing the read files for the wasp of interest:
cd /user/work/pk14885/Wasps_Dec2023

myForwardRead="A4_2_3_Cameroon_EKDL230052137-1A_22GGMJLT3_L7_1_val_1.fq.gz"
myReverseRead="A4_2_3_Cameroon_EKDL230052137-1A_22GGMJLT3_L7_2_val_2.fq.gz"
