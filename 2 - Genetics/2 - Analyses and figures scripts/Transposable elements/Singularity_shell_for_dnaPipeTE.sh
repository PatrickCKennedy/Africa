#!/bin/bash

#SBATCH --job-name=Transposable_elements
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=150G
#SBATCH --time=1-00:00:00
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# This script uses dnaPipeTE (https://github.com/clemgoub/dnaPipeTE) to quantify transposable elements.

# ---------------------------------------------------------------------------------------------------------
# CHOOSE TARGET WASP AND GENERATE A FASTQ FILE FROM THE POST-ALIGNMENT BAM FILE FOR YOUR WASP OF INTEREST:

# In the normal pipeline used for alignments, we produced a BAM file for each wasp (using bwa mem, etc.). 
# We now need to generate a FASTQ file from that BAM file (similar to page 29 in the chapter 'TE Analysis with dnaPipeTE'). To do so, we use samtools:

# If running this section on HPC (BluePebble) - CHOOSE THE TARGET WASP HERE:

            cd /user/work/pk14885/Wasps/Completed_alignments/

            # MANUALLY ENTER BOTH THE LOCATION OF THE TARGET WASP'S BAM FILE IN BLUEPEBBLE AND THE NAME YOU WOULD LIKE TO USE FOR THE DNAPIPETE OUTPUTS:
            my_wasp_to_process="/SouthAfrica/Pumphouse/BRIS_P11_a_CKDL220030776-1A_HK7J7DSX5.no.overlaps.bam"
            my_wasp_name_manual_entry="BRIS_P11_a"
            
            module load apps/samtools/1.16
            samtools sort -n $my_wasp_to_process -o ${my_wasp_name_manual_entry}.sorted.by.name 
            samtools fastq -@ 8 ${my_wasp_name_manual_entry}.sorted.by.name.bam -1 ${my_wasp_name_manual_entry}.SAMPLE_R1.fastq.gz -2 ${my_wasp_name_manual_entry}.SAMPLE_R2.fastq.gz -0 /dev/null -s /dev/null -n
            rm ${my_wasp_name_manual_entry}.sorted.by.name.bam
            rm ${my_wasp_name_manual_entry}.SAMPLE_R2.fastq.gz
            mv ${my_wasp_name_manual_entry}.SAMPLE_R1.fastq.gz /user/work/pk14885/Project/data/
            
# If running this section on the local computer - CHOOSE THE TARGET WASP HERE:

            ##my_wasp_to_process="/Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments/Wasps/Completed_alignments_without_bamutil_stage/SOM2_3_TARSUS_CKDL220030023-1A_HK7J7DSX5.before.removal.of.overlaps.bam"
            ##samtools sort -n $my_wasp_to_process sorted.by.name 
            ##samtools fastq -@ 8 sorted.by.name.bam -1 SAMPLE_R1.fastq.gz -2 SAMPLE_R2.fastq.gz -0 /dev/null -s /dev/null -n
            ##scp SAMPLE_R1.fastq.gz pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Project/data/
  
# The output '$my_wasp_name_manual_entry.SAMPLE_R1.fastq.gz' from 'samtools fastq' is the FASTQ file that we will now use for dnaPipeTE (for dnaPipeTE, you only use one of the R1 or R2 files). 
# It should now be in the /user/work/pk14885/Project/data/
# --------------------------------------------------------------------------------
# (ALL ON BLUEPEBBLE FROM NOW ON:) 
# --------------------------------------------------------------------------------
# REMOVE ANY OUTPUTS ON THE SAME WASP FROM PREVIOUS RUNS:

cd /user/work/pk14885/Project
rm -r ${my_wasp_name_manual_entry}.output
cd /user/work/pk14885

# --------------------------------------------------------------------------------
# SUPPLY THE GENERAL LIBRARY FILE FOR REPETITIVE ELEMENTS

# The Singularity container for dnaPipeTE comes with a default general library file, which we use below by not specifying an -RM_lib option in the call to dnaPipeTE.py
# Alternative option: you can download the general library file as part of the 'noarch/repeatmasker-4.1.5-pl5321hdfd78af_1.tar.bz2' download at https://anaconda.org/bioconda/repeatmasker/files (it is inside the 'Libraries' folder once you've downloaded RepeatMasker):
# In this case, I have uploaded it to BluePebble (you can set it as myRMlibrary="/user/work/pk14885/Project/RepeatMasker.lib" and add -RM_lib $myRMlibrary in the dnaPipeTE.py call below if you choose).

# --------------------------------------------------------------------------------
# INITIATE dnaPipeTE:

cd /user/work/pk14885
module load apps/singularity/1.1.3
module load lang/perl/5.30.0-bioperl-gcc
module load lang/perl

# Initiate and mount dnaPipeTE using a Singularity shell:

singularity shell --cleanenv \
    -B/user/work/pk14885/Project:/mnt \
    /user/work/pk14885/dnaPipeTE/dnapipete.img <<EOF
cd /opt/dnaPipeTE
python3 /opt/dnaPipeTE/dnaPipeTE.py -input /mnt/data/${my_wasp_name_manual_entry}.SAMPLE_R1.fastq.gz -output /mnt/output_${my_wasp_name_manual_entry} -genome_size 407000000 -genome_coverage 0.1 -sample_number 2 -RM_t 0.2 -cpu 8
EOF

