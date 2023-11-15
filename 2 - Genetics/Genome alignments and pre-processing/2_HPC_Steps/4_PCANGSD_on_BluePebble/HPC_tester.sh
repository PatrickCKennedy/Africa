#!/bin/bash
#SBATCH --job-name=Patrick_ANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=0-00:00:5
#SBATCH --account=BISC020282

echo
echo "Quick script to generate PCANGSD results on the 21 non-relatives across the South Africa dataset."
echo

cd /user/work/pk14885/Wasps/Completed_alignments/SouthAfrica/ANGSD_results

module add lang/python/anaconda/3.8.8-2021.05-2.5
source activate pcangsd

# Running PCAngsd:

# See all options
pcangsd -h

# Run PCANGSD to generate covariance matrix ready for making the PCA in R:
pcangsd -b my_Angsd_file.beagle.gz -o output.pcangsd -t 4
