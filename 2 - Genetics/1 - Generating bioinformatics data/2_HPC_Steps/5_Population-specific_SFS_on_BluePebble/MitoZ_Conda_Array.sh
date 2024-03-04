#!/bin/bash
#SBATCH --job-name=MitoZ
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=30G
#SBATCH --time=0-06:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
#SBATCH --array=1-60
# Update the array range to the required number of wasps to include in the sample (i.e., the number 
# of wasps in /user/work/pk14885/Input_wasps_for_Mitoz)

# ARRAY JOB FOR RUNNING 'MITOZ' ON HPC, USING MITOZ AS A UDOCKER CONTAINER
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Before running this script, you must do two things:

# (1) Upload the chosen wasps to BluePebble. For each wasp, have a folder
# containing two files: the forward and reverse trimmed files (the '_val_1' and '_val_2' files).
# Upload that wasp's folder (named for the wasp) within /user/work/pk1488/Input_wasps_for_Mitoz
# on BluePebble.

# (2) Before running the array job, generate a text file containing a list of all the target wasps
# (i.e., all wasps in the folder /user/work/pk14885/Input_wasps_for_Mitoz), using:
        ## cd /user/work/pk14885/Input_wasps_for_Mitoz
        ## ls -d */ > Wasps_to_target_with_MitoZ.filelist

# ---------------------------------------------------------------------------------
# IDENTIFY THE SPECIFIC WASP TARGETTED FOR THIS INSTANCE OF THE ARRAY SCRIPT:

# Navigate to the input folder:
        cd /user/work/pk14885/Input_wasps_for_Mitoz

# Allocate a specific wasp to this particular entry of the array job:
        this_wasp_to_sample=$(sed -n ${SLURM_ARRAY_TASK_ID}p Wasps_to_target_with_MitoZ.filelist)

# Print the focal wasp's name to the slurm output file:
        echo $this_wasp_to_sample

# ---------------------------------------------------------------------------------
# RUN MITOZ ON THE FOCAL WASP:

# Following Section 4 here (https://github.com/linzhi2013/MitoZ/wiki/Installation#4-conda-pack),
# I have downloaded the 'conda-unpack' version of MitoZ to BluePebble (/soft/mitoz3.6 on the working directory)
# Activate this environment:
source /soft/mitoz3.6/bin/activate
conda-unpack

# Navigate to the focal wasp's folder (which should contain only its 'val_1' and 'val_2' files):
        cd /user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_to_sample

# Find the names of the two trimmed 'val' .fq.gz files:
        this_wasp_val_1_FILE=$(ls *val_1*)
        this_wasp_val_2_FILE=$(ls *val_2*)

# Now run MitoZ through uDocker on the focal wasp:
mitoz all \
--fq1 $this_wasp_val_1_FILE \
--fq2 $this_wasp_val_2_FILE \
--outprefix $this_wasp_name \
--genetic_code 5 \
--clade Arthropoda \
--fastq_read_length 150 \
--data_size_for_mt_assembly 3,0 \
--assembler megahit \
--kmers_megahit 59 79 99 \
--thread_number 4 \
--memory 30 \
--requiring_taxa Arthropoda

# ---------------------------------------------------------------------------------

# The result of this script is the annotated mitochondrial genome for the focal wasp. In the next script, we
# will collate the outputs from each wasp, and construct a tree.

# ---------------------------------------------------------------------------------

# "Deactivate the environment to remove it from your path when your finish the MitoZ analysis" (https://github.com/linzhi2013/MitoZ/wiki/Installation#4-conda-pack):
cd /user/work/pk14885
source soft/mitoz3.6/bin/deactivate
