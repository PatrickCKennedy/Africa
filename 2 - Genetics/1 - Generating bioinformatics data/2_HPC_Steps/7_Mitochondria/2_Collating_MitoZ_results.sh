#!/bin/bash
#SBATCH --job-name=MitoZ_Singularity
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G
#SBATCH --partition=short
#SBATCH --time=0-02:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
# Update the array range to the required number of wasps to include in the sample (i.e., the number 
# of wasps in /user/work/pk14885/Input_wasps_for_Mitoz)

# ---------------------------------------------------------------------------------
# COLLATING MITOZ RESULTS FROM TARGET WASPS

# Make a directory to store all the results in (give it today's date):
mkdir 1_COLLATED_RESULTS_5_MARCH_2024

# Move the outputs for each wasp to the relevant '1_COLLATED_RESULTS' folder (MANUALLY CHANGE THE DATE BELOW):
        cd /user/work/pk14885/Input_wasps_for_Mitoz/
        cp -r */*.result /user/work/pk14885/Input_wasps_for_Mitoz/1_COLLATED_RESULTS_5_MARCH_2024/

# ---------------------------------------------------------------------------------



















