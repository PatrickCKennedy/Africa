#!/bin/bash

# (1) Manually enter the name of the folder of interest (e.g., Maroua) here:
this_POPULATION_NAME=$'Maroua'

# (2) Before running the job, generate a text file containing a list of all the target wasps:
# (i.e., all wasps in the folder /Volumes/Social_evolution_in_animals/Adaptor_trimmed_sequences/Organised_by_population/Northern_Cameroon/$this_POPULATION_NAME), using:
##        cd /Volumes/Social_evolution_in_animals/Adaptor_trimmed_sequences/Organised_by_population/Northern_Cameroon/$this_POPULATION_NAME
##        ls -d * > Wasps_to_target_with_GetOrganelle.filelist

# (3) Make sure the array range is set to the right number of wasps in the header (e.g., #SBATCH --array=1-102 above).
# To find the right number of wasps, use:
##        wc -l Wasps_to_target_with_GetOrganelle.filelist

# ---------------------------------------------------------------------------------
# PREPARE DESTINATION FOLDER FOR THE OUTPUTS:

# Make a folder elsewhere to store the outputs, if it doesn't already exist:
mkdir /Volumes/Social_evolution_in_animals/GetOrganelle_outputs 
mkdir /Volumes/Social_evolution_in_animals/GetOrganelle_outputs/$this_POPULATION_NAME
mkdir /Volumes/Social_evolution_in_animals/GetOrganelle_outputs/$this_POPULATION_NAME/$this_wasp_to_sample

# As a result, all the outputs will be stored in a separate folder, away from the adaptor-trimmed sequences.

# ---------------------------------------------------------------------------------
# LOOP THROUGH EACH WASP IN THE TARGET POPULATION:

# Activate GetOrganelle (which should already be installed - here, it was previously installed using Miniconda on the local computer):
source ~/miniconda3/etc/profile.d/conda.sh
conda activate getorganelle

conda activate getorganelle

# Navigate to the population of interest:
cd /Volumes/Social_evolution_in_animals/Adaptor_trimmed_sequences/Organised_by_population/Northern_Cameroon/$this_POPULATION_NAME

# Loop through each wasp in the filelist 'Wasps_to_target_with_GetOrganelle.filelist'
while read this_wasp_to_sample; do
    echo "Processing $this_wasp_to_sample"

   cd $this_wasp_to_sample
    
    # Find the names of the two trimmed 'val' .fq.gz files:
        this_wasp_val_1_FILE=$(ls *val_1*)
        this_wasp_val_2_FILE=$(ls *val_2*)

    # Running GetOrganelle:
    get_organelle_from_reads.py \
        -1 $this_wasp_val_1_FILE \
        -2 $this_wasp_val_2_FILE \
        -o ${this_wasp_to_sample}_output \
        -F animal_mt \
        -R 10 \
        -k 21,45,65,85,105 \
        -s /Users/pk14885/Downloads/UCL_Genome_MitoHiFi/final_mitogenome.fasta
    
done < Wasps_to_target_with_GetOrganelle.filelist

# Here, we use the complete mitochondrial genome (generated previously using MitoHiFi) as the 'seed' ('-s' command) for GetOrganelle.

# ---------------------------------------------------------------------------------

# Note: to run this file, download to your Downloads folder and use the following on your local computer:
##  cd Downloads 
##  chmod +x Mitochondria_on_local_computer.sh
##  ./Mitochondria_on_local_computer.sh  
