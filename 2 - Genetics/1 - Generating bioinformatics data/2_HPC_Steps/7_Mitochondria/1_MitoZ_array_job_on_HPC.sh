#!/bin/bash
#SBATCH --job-name=MitoZ_Singularity
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=15G
#SBATCH --partition=short
#SBATCH --time=0-02:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
#SBATCH --array=1-65
# Update the array range to the required number of wasps to include in the sample (i.e., the number 
# of wasps in /user/work/pk14885/Input_wasps_for_Mitoz)

# ARRAY JOB FOR RUNNING 'MITOZ' ON HPC
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Before running this script, you must do two things:

# (1) Upload the chosen wasps to BluePebble. For each wasp, have a folder
# containing two files: the forward and reverse trimmed files (the '_val_1' and '_val_2' files).
# Upload that wasp's folder (named for the wasp) within /user/work/pk1488/Input_wasps_for_Mitoz
# on BluePebble.

# (2) Before running the array job, generate a text file containing a list of all the target wasps
# (i.e., all wasps in the folder /user/work/pk14885/Input_wasps_for_Mitoz), using:
        cd /user/work/pk14885/Input_wasps_for_Mitoz
        ls -d */ > Wasps_to_target_with_MitoZ.filelist

# ---------------------------------------------------------------------------------
# IDENTIFY THE SPECIFIC WASP TARGETTED FOR THIS INSTANCE OF THE ARRAY SCRIPT:

# Allocate a specific wasp to this particular entry of the array job:
        this_wasp_to_sample_with_backslash_at_end=$(sed -n ${SLURM_ARRAY_TASK_ID}p Wasps_to_target_with_MitoZ.filelist)

# Print the focal wasp's name to the slurm output file:
        echo $this_wasp_to_sample_with_backslash_at_end
        this_wasp_name_only=$(echo ${this_wasp_to_sample_with_backslash_at_end%?})
        # '%?' removes the backslash, which is the last character (%?? would remove the last two characters, and so on)

# Navigate to the focal wasp's folder (which should contain only its 'val_1' and 'val_2' files):
        cd /user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_name_only

# Find the names of the two trimmed 'val' .fq.gz files:
        this_wasp_val_1_FILE=$(ls *val_1*)
        this_wasp_val_2_FILE=$(ls *val_2*)

# ---------------------------------------------------------------------------------
# RUN MITOZ ON BLUEPEBBLE:

# Make sure that we are in the focal wasp's folder:
cd /user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_name_only

# - - - - - - - - - - - - OPTION 1 (SUPPRESSED, AS SEEMS NOT TO SUCCEED IN FINAL STEPS) RUNNING MITOZ AS A SINGULARITY CONTAINER - - - - - - - - - - - - - - -
# I have downloaded the MitoZ Singularity container to /user/work/pk14885 using:   singularity pull MitoZ_v3.6.sif docker://guanliangmeng/mitoz:3.6
# You don't need to use this Singularity option, since Callum Wright has installed it as a general
# available programme on BluePebble (see 'Option 2' section below). However, it may produce better results
# via Singularity (https://github.com/linzhi2013/MitoZ/issues/89).

# Load Singularity on BluePebble:
## module load apps/singularity/1.1.3

##singularity run -B/user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_name_only/:/user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_name_only/ /user/work/pk14885/MitoZ_v3.6.sif mitoz all \
##                --fq1 /user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_name_only/$this_wasp_val_1_FILE \
##                --fq2 /user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_name_only/$this_wasp_val_2_FILE \
##                --outprefix $this_wasp_name_only \
##                --genetic_code 5 \
##                --clade Arthropoda \
##                --fastq_read_length 150 \
##                --data_size_for_mt_assembly 3,0 \
##                --assembler megahit \
##                --kmers_megahit 39 59 79 99 119 141 \
##                --thread_number 8 \
##                --memory 15 \
##                --requiring_taxa Arthropoda
                 
 # - - - - - - - - - - - - OPTION 2: RUNNING MITOZ AS INSTALLED VERSION ON BLUEPEBBLE - - - - - - - - - - - - - - 
# An alternative way to run MitoZ on BluePebble is as an installed programme.
# Callum Wright (Bristol ACRC) has installed MitoZ on BluePebble, in the module lang/python/miniconda/3.12.2.inc-perl-5.30.0

# The MitoZ website suggests that you may get better results if you use the Singularity version (https://github.com/linzhi2013/MitoZ/issues/89).
# If you want to use the installed version, use the following code:

# Start the correct Miniconda module:
        module add lang/python/miniconda/3.12.2.inc-perl-5.30.0

# Activate the environment installed by Callum Wright:
        source activate mitozEnv

# Check the installation:
        which circos 
# It should print:  /sw/lang/miniconda.3.12.2/envs/mitozEnv/bin/circos

# Run 'mitoz' from inside the 'mitozEnz' environment:
mitoz all \
    --fq1 /user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_name_only/$this_wasp_val_1_FILE \
    --fq2 /user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_name_only/$this_wasp_val_2_FILE \
    --outprefix $this_wasp_name_only \
    --genetic_code 5 \
    --clade Arthropoda \
    --fastq_read_length 150 \
    --data_size_for_mt_assembly 0,0 \
    --assembler megahit \
    --kmers_megahit 39 59 79 99 119 141 \
    --thread_number 8 \
    --memory 15 \
    --requiring_taxa Arthropoda

# ---------------------------------------------------------------------------------

# The result of this script is the annotated mitochondrial genome for the focal wasp. In the next script, we
# will collate the outputs from each wasp, and construct a tree.

# ---------------------------------------------------------------------------------
