# CURRENTLY WORKING ON THIS (8TH FEB 2024 - HAVEN'T YET RUN IT ON BLUEPEBBLE):
# I THINK IT IS READY TO GO. FIRST, LET'S CHECK THAT THE SINGLE-WASP-AT-A-TIME VERSION
# SUCCESSFULLY RUNS - IF IT DOES, RUN THIS ARRAY JOB FOR ALL THE WASPS (IN EACH COUNTRY SEPARATELY):


#!/bin/bash
#SBATCH --job-name=Array_TEs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G
#SBATCH --time=0-07:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
#SBATCH --array=1-312
# Set this to run for the total number of wasps in the relevant country (e.g., I currently have 608 samples listed in bam.filelist for Cameroon, so I would type --array=1-608 above).

# -------------------- TRANSPOSABLE ELEMENT COMPOSITION IN EACH WASP (ARRAY JOB) -------------

# WHAT THIS SCRIPT DOES:

# This is an array job for calculating transposable element content for each wasp individually.
# Like the heterozygosity script, it runs on all wasps in the country (including close relatives).

# -------------------------------------------------------------
# SET THE COUNTRY (and also set the array count in the SBATCH code above):

# Choose whether to run this in the SouthAfrica or Cameroon folder on BluePebble:
cd /user/work/pk14885/Wasps/Completed_alignments/Cameroon
 
# -------------------------------------------------------------
# LOAD THE MODULES ON THE CLUSTER:

# If running on BluePebble:
module load apps/angsd/0.941

# -------------------------------------------------------------
# BEFORE RUNNING THIS SCRIPT, MAKE SURE YOU HAVE GENERATED TWO TEXT FILES IT NEEDS TO RUN (THESE ARE A LIST OF THE WASPS THAT THE ARRAY WILL WORK THROUGH): bam.filelist AND WaspNameOnly. TO GENERATE THEM, TYPE THE FOLLOWING LINES MANUALLY FROM THE RELEVANT COUNTRY FOLDER (SouthAfrica OR Cameroon) IN BLUEPEBBLE:

# You should have already generated these text files when running the Heterozygosity_on_HPC.sh script:
# 'WaspNameOnly'
# 'bam.filelist'
# If not, go over to the Heterozygosity_on_HPC.sh script, and look at the corresponding section for how to generate them manually.

# Make a folder to store the results (if it doesn't already exist):
mkdir TE_content_results
    
# NOTE: In the actual final run, we will need to make sure there are no duplicates (e.g., wasps who appear under both a colour code and a wasp name, as they were sequenced twice).

# -------------------------------------------------------------
# IDENTIFY THE SPECIFIC WASP TARGETTED FOR THIS INSTANCE OF THE ARRAY SCRIPT:

# Allocate a specific wasp to this particular entry of the array job (following https://help.rc.ufl.edu/doc/SLURM_Job_Arrays):
SAMPLE_LIST=($(<bam.filelist))
SAMPLE=${SAMPLE_LIST[${SLURM_ARRAY_TASK_ID}]}
        # The variable $SAMPLE now contains the path to the bam file of interest for this wasp, including the population folder (e.g., Cowshed/CS9_c_CKDL220030015-1A_HK7J7DSX5.no.overlaps.bam)

# Extract the wasp name for this sample:
NAME_LIST=($(<WaspNameOnly))
NAME=${NAME_LIST[${SLURM_ARRAY_TASK_ID}]}
        # The variable $NAME now contains the name for this wasp (e.g., EF3-2).
        
# Print the path and wasp name for the SLURM output file:
echo $SAMPLE
echo $NAME

# -------------------------------------------------------------
# SORT THE TARGET WASP'S BAM FILE AND GENERATE THE FORWARD-ONLY FASTQ FILE THAT WE WILL USE IN dnaPipeTE:
          
module load apps/samtools/1.16
samtools sort -n $PWD$SAMPLE -o ${NAME}.sorted.by.name.bam 
samtools fastq -@ 8 ${NAME}.sorted.by.name.bam -1 ${NAME}.SAMPLE_R1.fastq.gz -2 ${NAME}.SAMPLE_R2.fastq.gz -0 /dev/null -s /dev/null -n
rm ${NAME}.sorted.by.name.bam
rm ${NAME}.SAMPLE_R2.fastq.gz

# Move the resulting forward-only fastq file to the 'Project' folder in the main workspace:
mv ${NAME}.SAMPLE_R1.fastq.gz /user/work/pk14885/Project/data/

# The output '${NAME}.SAMPLE_R1.fastq.gz' from 'samtools fastq' is the FASTQ file that we will now use for dnaPipeTE (for dnaPipeTE, you only use one of the R1 or R2 files). 
# It should now be in the /user/work/pk14885/Project/data/
# -------------------------------------------------------------
# SORT THE TARGET WASP'S BAM FILE AND GENERATE THE FORWARD-ONLY FASTQ FILE THAT WE WILL USE IN dnaPipeTE:

# --------------------------------------------------------------------------------
# REMOVE ANY OUTPUTS ON THE SAME WASP FROM PREVIOUS RUNS:

cd /user/work/pk14885/Project
rm -r ${NAME}.output
cd /user/work/pk14885

# --------------------------------------------------------------------------------
# SUPPLY THE GENERAL LIBRARY FILE FOR REPETITIVE ELEMENTS

# The Singularity container for dnaPipeTE comes with a default general library file, which you can below by not specifying an -RM_lib option in the call to dnaPipeTE.py
# Alternative option: you can download the general library file as part of the 'noarch/repeatmasker-4.1.5-pl5321hdfd78af_1.tar.bz2' download at https://anaconda.org/bioconda/repeatmasker/files (it is inside the 'Libraries' folder once you've downloaded RepeatMasker):
# I have uploaded it to BluePebble (you can set it as myRMlibrary="/user/work/pk14885/Project/RepeatMasker.lib" and add -RM_lib $myRMlibrary in the dnaPipeTE.py call below if you choose).
# Below, we use the Belonogaster juncea custom TE library that we have already generated using EDTA (see the EDTA_on_BluePebble.sh script for that step).

# --------------------------------------------------------------------------------
# INITIATE dnaPipeTE:

cd /user/work/pk14885
module load apps/singularity/1.1.3
module load lang/perl/5.30.0-bioperl-gcc
module load lang/perl

# Initiate and mount dnaPipeTE using a Singularity shell, using the custom Belonogaster juncea TE library we have already generated with EDTA:

singularity shell --cleanenv \
    -B/user/work/pk14885/Project:/mnt \
    /user/work/pk14885/dnaPipeTE/dnapipete.img <<EOF
cd /opt/dnaPipeTE
python3 /opt/dnaPipeTE/dnaPipeTE.py -input /mnt/data/${NAME}.SAMPLE_R1.fastq.gz -output /mnt/output_${NAME} -genome_size 407000000 -genome_coverage 0.15 -sample_number 2 -RM_t 0.2 -cpu 8 -RM_lib /mnt/data/B_junceaGenome.FINAL.fasta.mod.EDTA.TElib.fa
EOF

# --------------------------------------------------------------------------------
# DOWNLOAD THE OUTPUTS ON THE LOCAL COMPUTER:

##     scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Project/NAME.THE.OUTPUT.FIRST.output NAME.THE.OUTPUT.FIRST.output







