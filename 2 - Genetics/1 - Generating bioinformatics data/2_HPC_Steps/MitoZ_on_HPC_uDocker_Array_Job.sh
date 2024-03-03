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
        cd /user/work/pk14885/Input_wasps_for_Mitoz
        ls -d */ > Wasps_to_target_with_MitoZ.filelist

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# NOTE: THE SCRIPT BELOW USES 'UDOCKER' (A FORM OF DOCKER THAT DOES NOT REQUIRE ROOT PRIVILEGES)

# To run this script, I have already installed 'uDocker' in my work directory on BluePebble (following section 2.1 here: https://indigo-dc.github.io/udocker/installation_manual.html)
# ...and then installed udocker's 'Mitoz' container onto my BluePebble account using:    udocker pull guanliangmeng/mitoz:3.6     (following section 2.2 here: https://github.com/linzhi2013/MitoZ/wiki/Installation)

# Before udocker can run, load it into the PATH for the current session:
        export PATH=`pwd`/udocker-1.3.13/udocker:$PATH

# To check that udocker is working, use:
        which udocker

# To check which udocker images are on your own working directory, use:
        udocker images

# ---------------------------------------------------------------------------------
# IDENTIFY THE SPECIFIC WASP TARGETTED FOR THIS INSTANCE OF THE ARRAY SCRIPT:

# Allocate a specific wasp to this particular entry of the array job:
        this_wasp_to_sample=$(sed -n ${SLURM_ARRAY_TASK_ID}p Wasps_to_target_with_MitoZ.filelist)

# Print the focal wasp's name to the slurm output file:
        echo $this_wasp_to_sample

# ---------------------------------------------------------------------------------
# RUN MITOZ THROUGH UDOCKER ON THE FOCAL WASP:

# Navigate to the focal wasp's folder (which should contain only its 'val_1' and 'val_2' files):
        cd /user/work/pk14885/Input_wasps_for_Mitoz/$this_wasp_to_sample

# Find the names of the two trimmed 'val' .fq.gz files:
        this_wasp_val_1_FILE=$(ls *val_1*)
        this_wasp_val_2_FILE=$(ls *val_2*)

# Now run MitoZ through uDocker on the focal wasp:
udocker run -v $PWD:$PWD -w $PWD --rm guanliangmeng/mitoz:3.6  mitoz all \
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
