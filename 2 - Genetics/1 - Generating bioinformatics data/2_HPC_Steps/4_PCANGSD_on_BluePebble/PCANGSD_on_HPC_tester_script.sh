#!/bin/bash
#SBATCH --job-name=Patrick_ANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G
#SBATCH --time=0-00:60:00
# "Defines how long the job will run in real time. This is a hard cap meaning
# that if the job runs longer than what is written here, it will be
# force-stopped by the server. If you make the expected time too long, it will
# take longer for the job to start. Here, we say the job will take 5 minutes. d-hh:mm:ss"
#SBATCH --account=BISC020282
# That last line is required due to the January 2023 update to BlueCrystal/BluePebble. BISC020282 is my project code in ACRC ("Social evolution of animal altruism").

# -------------------------------------------------------------
# PCANGSD:
# Before running PCANGSD, you need to generate a Beagle file using ANGSD. The following assumes that you have already completed that step.

cd /user/work/pk14885/Wasps/Completed_alignments/SouthAfrica/Brood/ANGSD_results

module add lang/python/anaconda/3.8.8-2021.05-2.5
source activate pcangsd

# Running PCAngsd:

# See all options
pcangsd -h

# Run PCANGSD to generate covariance matrix ready for making the PCA in R:
pcangsd -b my_Angsd_file.beagle.gz --kinship -o kin_test.output.pcangsd
