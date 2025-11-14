#!/bin/bash
#SBATCH --job-name=MitoBIM_Singularity_Option_NEE_2025
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=30G
#SBATCH --time=0-01:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
#SBATCH --array=1-102
# Update the array range to cover the required number of wasps to include in the sample (e.g., the number 
# of wasps in /user/work/pk14885/MitoZ_NEE_2025/Maroua)

# PK, latest update: 10th November 2025

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Before running this script, do the following:

# (1) Upload the chosen wasps to BluePebble. For each wasp, have a folder
# containing two files: the forward and reverse trimmed files (the '_val_1' and '_val_2' files).
# Upload that wasp's folder (named for the wasp) within /user/work/pk14885/MitoZ_NEE_2025/POPULATION_ID_HERE
# on BluePebble.

# (2) Manually enter the name of the folder of interest within MitoZ_NEE_2025 here:
this_POPULATION_NAME=$'Maroua'

# (3) Before running the array job, generate a text file containing a list of all the target wasps
# (i.e., all wasps in the folder /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME), using:
##        cd /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME
##        ls -d * > Wasps_to_target_with_MitoZ.filelist

# (4) Make sure the array range is set to the right number of wasps in the header (e.g., #SBATCH --array=1-102 above).
# To find the right number of wasps, use:
##        wc -l Wasps_to_target_with_MitoZ.filelist

# ---------------------------------------------------------------------------------
# IDENTIFY THE SPECIFIC WASP TARGETTED FOR THIS INSTANCE OF THE ARRAY SCRIPT:

# Allocate a specific wasp to this particular entry of the array job:
        cd /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME
        this_wasp_to_sample=$(sed -n ${SLURM_ARRAY_TASK_ID}p Wasps_to_target_with_MitoZ.filelist)

# Print the focal wasp's name to the slurm output file:
        echo $this_wasp_to_sample

# Navigate to the focal wasp's folder (which should contain only its 'val_1' and 'val_2' files):
        cd /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample

# Find the names of the two trimmed 'val' .fq.gz files:
        this_wasp_val_1_FILE=$(ls *val_1*)
        this_wasp_val_2_FILE=$(ls *val_2*)

# ---------------------------------------------------------------------------------
# RUN MitoBIM ON BLUEPEBBLE 

module load apptainer/1.3.1-ksax

singularity run -B/user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/:/user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/ /user/work/pk14885/mitobim.sif ./MITObim.pl \
          -start 1 \
          -end 30 \
          -sample $this_wasp_to_sample \
          -ref /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta \
          -readpool /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_val_1_FILE /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_val_2_FILE

# The file 'final_mitogenome.fasta' is the assembled mitochondrial reference genome (UCL project). We use it as the reference above.

# ---------------------------------------------------------------------------------
# DELETE THE INPUT VAL FILES FOR THIS WASP FROM BLUEPEBBLE:

# IMPORTANT: The wasp's input files (the adaptor-trimmed val files) are stored securely on RDSF, so their upload onto BluePebble is only temporary. We can therefore delete the input files now that
# MitoZ has finished processing this wasp, in order to free space on BluePebble:

## rm /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_val_1_FILE
## rm /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_val_2_FILE

 # ---------------------------------------------------------------------------------

# The result of this script is the annotated mitochondrial genome for the focal wasp.

# ---------------------------------------------------------------------------------
