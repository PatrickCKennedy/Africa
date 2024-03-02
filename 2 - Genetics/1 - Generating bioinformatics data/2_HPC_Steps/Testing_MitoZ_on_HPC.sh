#!/bin/bash
#SBATCH --job-name=MitoZ
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --cpus-per-task=1
#SBATCH --mem=50G
#SBATCH --time=0-07:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
#SBATCH --array=1

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Before running this script, upload the chosen wasps to BluePebble. For each wasp, have a folder
# containing two files: the forward and reverse trimmed files (the '_val_1' and '_val_2' files).
# Upload that wasp's folder (named for the wasp) within /user/work/pk1488/Input_wasps_for_Mitoz
# on BluePebble.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# NOTE ABOUT UDOCKER:

# To run this script, I have already installed udocker in my work directory on BluePebble (following option 2.1 here: https://indigo-dc.github.io/udocker/installation_manual.html)
# ...and then installed udocker's 'Mitoz' container using: udocker pull guanliangmeng/mitoz:3.6 (following section 2.2 here: https://github.com/linzhi2013/MitoZ/wiki/Installation)

# To check that udocker is working, use:
which udocker

# To check which udocker images are on my working directory, use:
udocker images
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

cd /user/work/pk14885/Input_wasps_for_MitoZ/PETIO_LR10_1

this_wasp_name=PETIO_LR10_1
this_wasp_val_1_FILE=PETIO_LR10_1_CKDL220030777-1A_HK7J7DSX5_L4_1_val_1.fq.gz
this_wasp_val_2_FILE=PETIO_LR10_1_CKDL220030777-1A_HK7J7DSX5_L4_2_val_2.fq.gz

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
--thread_number 1 \
--memory 50 \
--requiring_taxa Arthropoda
    

