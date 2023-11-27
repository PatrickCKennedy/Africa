#!/bin/bash

#SBATCH --job-name=Transposable_elements
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G
#SBATCH --time=4-00:00:00
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# -------------------------------------------------------------
# LOAD SINGULARITY ON BLUEPEBBLE:

module load apps/singularity/1.1.3

# ---------------------------------------------------------------------------------------------------------
# SECTION THAT IS CURRENTLY RUN ON THE LOCAL COMPUTER: GENERATE A FASTQ FILE FROM THE POST-ALIGNMENT BAM FILE FOR YOUR WASP OF INTEREST:

# For this step, I am using the BAM files before the removal of the overlaps by BAMUTIL.

# In the normal pipeline used for alignments, we produced a BAM file for each wasp (using bwa mem, etc.). 
# We now need to generate a FASTQ file from that BAM file (similar to page 29 in the chapter 'TE Analysis with dnaPipeTE'). 
# To do so, we use samtools:

            # Point to the BAM file for the wasp of interest:
            ##my_wasp_to_process="/Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments/Wasps/Completed_alignments_without_bamutil_stage/SOM2_3_TARSUS_CKDL220030023-1A_HK7J7DSX5.before.removal.of.overlaps.bam"

            # First use samtools to sort the read pairs by name (in order to prevent bedtools complaining that the pairs are not next to each other):
            ##samtools sort -n $my_wasp_to_process sorted.by.name 
             
            # Now use samtools fastq to generate the FASTQ files:
            ##samtools fastq -@ 8 sorted.by.name.bam -1 SAMPLE_R1.fastq.gz -2 SAMPLE_R2.fastq.gz -0 /dev/null -s /dev/null -n

# --------------------------------------------------------------------------------
# (BACK ON BLUEPEBBLE FROM NOW ON:) SUPPLY THE NAME OF THE INPUT WASP FILE:

# We will use the newly-produced 'SAMPLE_R1.fastq.gz' file (for dnaPipeTE, you only use one of the R1 or R2 files):
# Manually upload it to /user/work/pk14885/Project/data/

# --------------------------------------------------------------------------------
# SUPPLY THE GENERAL LIBRARY FILE FOR REPETITIVE ELEMENTS

# We need to supply the TE library file. I downloaded it as part of the 'noarch/repeatmasker-4.1.5-pl5321hdfd78af_1.tar.bz2' download at https://anaconda.org/bioconda/repeatmasker/files (it is inside the 'Libraries' folder once you've downloaded RepeatMasker):
# In this case, I have uploaded it to BluePebble:
myRMlibrary="/user/work/pk14885/Project/RepeatMasker.lib"

# --------------------------------------------------------------------------------
# INITIATE dnaPipeTE:

# Initiate and mount dnaPipeTE:
cd /user/work/pk14885

module load apps/singularity/1.1.3

singularity exec \
-B/user/work/pk14885/Project:/mnt /user/work/pk14885/dnaPipeTE/dnapipete.img \
python3 /opt/dnaPipeTE/dnaPipeTE.py -input /mnt/data/SAMPLE_R1.fastq.gz -output /mnt/output -RM_lib $myRMlibrary -genome_size 407000000 -genome_coverage 0.1 -sample_number 2 -RM_t 0.2 -cpu 2

# You can *either* use -genome_coverage and -genome_size OR -sample_size (number of reads to sample).

# In principle, you can also run this on the BluePebble login node (which would be against ACRC policy).
# That would be:
module load apps/singularity/1.1.3
singularity shell --bind /user/work/pk14885/Project:/mnt /user/work/pk14885/dnaPipeTE/dnapipete.img
cd /opt/dnaPipeTE # <<<--- This line is very important to run the program with singularity!
python3 /opt/dnaPipeTE/dnaPipeTE.py -input /mnt/data/SAMPLE_R1.fastq.gz -output /mnt/output -RM_lib $myRMlibrary -genome_size 407000000 -genome_coverage 0.1 -sample_number 2 -RM_t 0.2 -cpu 2



