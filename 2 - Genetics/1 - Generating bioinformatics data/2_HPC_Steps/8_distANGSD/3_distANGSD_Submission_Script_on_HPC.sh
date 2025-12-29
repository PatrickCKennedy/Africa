#!/usr/bin/env bash
set -euo pipefail

# This is the submission script for running the array job (which is in script 2). You should run this submission script directly
# on the login node, because it uses sbatch to submit the actual array job to the HPC system.

# To submit this script, run the following two lines on the login node:
##              chmod +x 3_distANGSD_Submission_Script_on_HPC.sh
##              ./3_distANGSD_Submission_Script_on_HPC.sh


# -------------------------------------------------------------------------------------------------
# PARAMETER SETTINGS:

# Set the choices below manually. These will be automatically passed to the array job:
  my_chunk_size_to_run=200                       # Each array task will work through this number of pairs of genomes.
  my_choice_of_phylogenetic_model_to_run="JC"    # Here, we run Jukes-Cantor (JC), but an alternative would be General Time Reversible (GTR)

# Point to the list of pairs generated in script 1:
  my_pair_list="/user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder/distangsd_results/pairs.tsv"  # set by submitter
  
# -------------------------------------------------------------------------------------------------
# CALCULATE NUMBER OF TASKS TO RUN:

# Count how many pairs need to be run:
    TOTAL=$(wc -l < "$my_pair_list")

# Exit if there is nothing in the list of pair:
    (( TOTAL > 0 )) || { echo "No pairs in $my_pair_list"; exit 1; }

# Calculate the maximum number of tasks that will need to be run in the array job:
    ARRAY_MAX=$(( (TOTAL + my_chunk_size_to_run - 1) / my_chunk_size_to_run ))
    # For instance, if we had 953 wasps, there would be (953-952)/2=453628 pairwise comparisons to run. With 200 runs per chunk, we would need 2269 array tasks.

# Make a directory to store the logs:
    mkdir -p logs

# -------------------------------------------------------------------------------------------------
# SUBMIT THE ARRAY JOB USING SBATCH:

# Print the array job information:
echo "Submitting array 1-${ARRAY_MAX} (TOTAL=${TOTAL}, my_chunk_size_to_run=${my_chunk_size_to_run})"

sbatch \
  --array=1-"${ARRAY_MAX}" \
  --export=ALL,my_pair_list="${my_pair_list}",my_chunk_size_to_run="${my_chunk_size_to_run}",my_choice_of_phylogenetic_model_to_run="${my_choice_of_phylogenetic_model_to_run}" \
  2_Running_distANGSD_on_HPC.sh

# -------------------------------------------------------------------------------------------------
