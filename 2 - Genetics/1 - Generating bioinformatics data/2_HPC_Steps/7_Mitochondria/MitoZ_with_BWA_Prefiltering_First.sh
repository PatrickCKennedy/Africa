#!/bin/bash
#SBATCH --job-name=MitoZ_with_BWA_Prefiltering_First
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=30G
#SBATCH --time=0-06:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
#SBATCH --array=1-102
# Update the array range to cover the required number of wasps to include in the sample (e.g., the number 
# of wasps in /user/work/pk14885/MitoZ_NEE_2025/Maroua)

# PK, latest update: 20th November 2025
# Not yet tested!

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Before running this script, do the following:

# (1) Upload the chosen wasps to BluePebble. For each wasp, have a folder
# containing two files: the forward and reverse trimmed files (the '_val_1' and '_val_2' files).
# Upload that wasp's folder (named for the wasp) within /user/work/pk14885/MitoZ_NEE_2025/POPULATION_ID_HERE
# on BluePebble.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# AUTOMATED UPLOADING OF WASPS TO BLUEPEBBLE WORKSPACE FROM RDSF SPACE:

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

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
# BEFORE RUNNING MITOZ, EXTRACT A POOL OF LIKELY MITOCHONDRIAL READS BY MAPPING TO OUR B. JUNCEA REFERENCE MITOGENOME:
# P: Our aim here is to increase the quality of the subsequent de novo assemblies by MitoZ, which otherwise can lead to
# fragmented assemblies from our low-coverage whole genome reads. This step increases the concentration of true
# mitochondrial reads among the sequences evaluated by MitoZ for assembly, which otherwise will be overwhelmingly
# nuclear. It allows us to continue to use a de novo assembler such as MitoZ, rather than (for instance) generating 
# a consensus sequence between each wasp's reads and the reference mitogenome, an alternative approach which may be prone 
# to increasing reference bias in samples where coverage is lower.

# Note: the reference mitogenome should aleady have been indexed (using: bwa index reference_mitogenome.fasta).

# Use BWA to perform mapping of this wasp's reads to the reference mitogenome:
bwa mem -B 2 /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta $this_wasp_val_1_FILE $this_wasp_val_2_FILE | samtools view -bS - > ${this_wasp_to_sample}_mapped.bam

# P: In the line above, to reduce the possibilty that the BWA mapping step may introduce reference bias (i.e., by tending to differentially exclude true mitochondrial reads that vary more considerably
# from the reference mitogenome), we lower BWA's mismatch penalty from the default (-B 4) to the less strict 2 (-B 2) so that variants are retained. 

# Identify reads that map to the reference mitogenome and are therefore good candidates for being true mitochondrial sequences:
samtools view -b -F 4 ${this_wasp_to_sample}_mapped.bam > ${this_wasp_to_sample}_mito_only.bam
samtools fastq ${this_wasp_to_sample}_mito_only.bam -1 ${this_wasp_to_sample}_mito_R1.fq.gz -2 ${this_wasp_to_sample}_mito_R2.fq.gz

# P: In the next section, we will now use these reads as the input for MitoZ, so that MitoZ's pool of reads to assess is not diluted
# by large numbers of nuclear loci (although this pre-filtering step will not exclude NUMTs).

# To make this work, the files provided for fq1 and fq2 in the MitoZ all command below need to be replaced with mito_R1.fq.gz and mito_R2.fq.gz respectively.
# ---------------------------------------------------------------------------------
# RUN MITOZ ON BLUEPEBBLE (OPTION 1):

# Note: There is a good way to run MitoZ, which is as a container within Singularity. 
# This can be done on the HPC working directory, as you will have downloaded the MitoZ
# Singularity container to the working directory (here, /user/work/pk14885) using:   singularity pull MitoZ_v3.6.sif docker://guanliangmeng/mitoz:3.6
# You don't need to use this Singularity option if it is installed as a general
# available programme on HPC (below). However, for completeness, here is the command 
# if you would like to run it through Singularity on HPC (checked on BluePebble, 4th March 2024):

module load apptainer/1.3.1-ksax

singularity run -B/user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/:/user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/ /user/work/pk14885/MitoZ_v3.6.sif mitoz all \
           --fq1 /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_mito_R1.fq.gz \
           --fq2 /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_mito_R2.fq.gz \
           --outprefix $this_wasp_to_sample \
           --genetic_code 5 \
           --clade Arthropoda \
           --fastq_read_length 150 \
           --data_size_for_mt_assembly 0.3 \
           --assembler spades \
           --thread_number 4 \
           --memory 30 \
           --requiring_taxa Arthropoda

# If using the 'megahit' assembler (rather than 'spades'), specify the kmers, e.g, --kmers_megahit 59 79 99 \
# ---------------------------------------------------------------------------------
# RUN MITOZ ON BLUEPEBBLE (OPTION 2):

## Alternative option using MitoZ preinstalled on HPC:
# In our case, Bristol ACRC has installed MitoZ on BluePebble, in the module:
## module load apps/mitoz/3.6

# Make sure that you are in the focal wasp's folder:
## cd /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample

# Run 'mitoz' from inside the 'mitozEnz' environment:
## mitoz all \
##     --fq1 /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_val_1_FILE \
##     --fq2 /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_val_2_FILE \
##     --outprefix $this_wasp_to_sample \
##     --genetic_code 5 \
##     --clade Arthropoda \
##     --fastq_read_length 150 \
##     --data_size_for_mt_assembly 3,0 \
##     --assembler megahit \
##     --kmers_megahit 59 79 99 \
##     --thread_number 1 \
##     --memory 50 \
##     --requiring_taxa Arthropoda

# ---------------------------------------------------------------------------------
# DELETE THE INPUT VAL FILES FOR THIS WASP FROM BLUEPEBBLE:

# IMPORTANT: The wasp's input files (the adaptor-trimmed val files) are stored securely on RDSF, so their upload onto BluePebble is only temporary. We can therefore delete the input files now that
# MitoZ has finished processing this wasp, in order to free space on BluePebble:

## rm /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_val_1_FILE
## rm /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_val_2_FILE

# Remove the 'clean_data' folder, which contains the raw genome data after MitoZ's initial filtering and cleaning steps:
        cd /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample
        rm -r clean_data/

 # ---------------------------------------------------------------------------------

# The result of this script is the annotated mitochondrial genome for the focal wasp.

# ---------------------------------------------------------------------------------
