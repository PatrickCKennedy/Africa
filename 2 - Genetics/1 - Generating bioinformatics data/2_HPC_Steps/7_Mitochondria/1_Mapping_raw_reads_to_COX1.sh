#!/bin/bash
#SBATCH --job-name=Samtools_Mitochondria_NEE_2025
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
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
# USE THE COX1 GENE FROM THE REFERENCE MITOCHONDRIAL GENOME:
# We have assembled the reference mitochondrial genome as part of a wider project elsewhere to
# provide the reference genome for Belonogaster juncea (Wyatt et al.). The mitochondrial genome
# from that reference is in the file /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta
# The start and end positions for the COX1 gene are detailed in the GenBank-syle file 'final_mitogenome.gb',
# and are 3417 to 4955.

# Load the modules on HPC:
module load bwa/0.7.17-hnox
module load samtools/1.19.2-737f

# We begin by indexing our reference mitogenome, using bwa index:
    bwa index /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta
    samtools faidx /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta

# Next, we map raw reads from the adaptor-trimmed files for each wasp from low-coverage whole genome
# sequencing to the reference mitogenome, using bwa mem:
    bwa mem -t 8 /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta $this_wasp_val_1_FILE $this_wasp_val_2_FILE | samtools view -Sb - > /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}.bam

# Next, sort and index the BAM file:
    samtools sort /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_to_sample.bam -o /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_sorted.bam
    samtools index /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_sorted.bam

# Next, extract the COX1 gene from the reference mitogenome:
    COX1_START=3417
    COX1_END=4955
    samtools faidx /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta:${COX1_START}-${COX1_END}" > /user/work/pk14885/UCL_Genome_MitoHiFi/samtools_reference_COX1.fasta

# Use the mapped reads against the reference to generate a consensus sequence for the current wasp of interest:
    samtools mpileup -uf /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_sorted.bam | bcftools call -c | vcfutils.pl vcf2fq > /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_COX1.fastq

# Convert the output FASTQ to a FASTA file:
    seqtk seq -a /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_COX1.fastq > /user/work/pk14885/MitoZ_NEE_2025/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_COX1.fasta
