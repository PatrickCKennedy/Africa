#!/bin/bash
#SBATCH --job-name=Ca_TEArray
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
#SBATCH --array=1-2
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
forwardslash="/"
samtools sort -n $PWD$forwardslash$SAMPLE -o ${NAME}.sorted.by.name.bam 
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
python3 /opt/dnaPipeTE/dnaPipeTE.py -input /mnt/data/${NAME}.SAMPLE_R1.fastq.gz -output /mnt/output_${NAME} -genome_size 407000000 -genome_coverage 0.1 -sample_number 3 -RM_t 0.2 -cpu 8 -RM_lib /mnt/data/B_junceaGenome.FINAL.fasta.mod.EDTA.TElib.fa
EOF

# --------------------------------------------------------------------------------
# POST-PROCESSING OF OUTPUTS FOR THIS WASP, USING CLEMENT GOUBERT'S 'dnaPT_utils' SCRIPTS:

# Have downloaded 'dnaPT_utils' to the BluePebble work directory using: git clone https://github.com/clemgoub/dnaPT_utils.git
# following p.37 of Chapter 2 in 'Transposable Elements: Methods and Protocols'. The 'dnaPT_utils' scripts
# create final outputs by post-processing the dnaPipeTE outputs. This offers an improvement on the graphs and outputs generated straight from dnaPipeTE.

# Return to the main work directory:
cd /user/work/pk14885

# Load R:
module load lang/r/4.3.0-gcc

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# RUNNING THE CHARTS SCRIPT OF dnaPT_utils:

# First, we will run the 'dnaPT_charts.sh' process (which uses the 'reads_per_component_and_annotation' output). The dnaPT_utils
# folder made by Clement Goubert contains this script. In order to facilitate collation of each sample's pie chart input data,
# I have added a 'write.table' function to a copy of this script (before the 'SCRIPT' line ending the R session the end of the bash 
# file), called 'dnaPT_charts_PK_edit.sh'. I've also added a 'mv' function at the end of the script. As a record to enable
# repeatability, these two additions are the following lines (replacing the previous 'SCRIPT' and 'echo' lines at the end of the script):
                 
           ##              ##############################
           ##              # PK: My only two additions to this script by Clement Goubert are: (1) the following write.table command, to export the dfg file, and (2) the 
           ##              # 'mv' line at the very end, to move it to the right folder:
           ##              write.table(dfg, 
           ##                          paste("$PREF", "_dfg.txt", sep = ""), 
           ##                          sep = "\t", na = "NA", col.names = FALSE)
           ##              ##############################
           ##              
           ##              SCRIPT
           ##              
           ##              echo "All done, results in $OUTF/"
           ##              
           ##              ##############################
           ##              # PK: My other addition (to move the dfg file to the right folder):
           ##              mv ${PREF}_dfg.txt $OUTF/
           ##              ##############################


# We therefore run this script:
bash dnaPT_utils/dnaPT_charts_PK_edit.sh -I Project/output_${NAME} -p dnaPT_utils_outputs_${NAME}

# The outputs are:
      # dnaPT_utils_outputs_${NAME}.charts.pdf
      # ${NAME}_dfg.txt
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# RUNNING THE LANDSCAPES SCRIPT OF dnaPT_utils:

# To generate the landscape versus the blastn consensus sequences for this wasp, we use Clement Goubert's landscapes script. As
# above, we have added a small section at the end of that script to download the table needed to make the ggplot in R, to enable
# easy replotting and changing colour schemes, etc:

           ##              ##############################
           ##              # PK: My only two additions to this script by Clement Goubert are: (1) the following write.table command, to export the dfg file, and (2) the 
           ##              # 'mv' line at the very end, to move it to the right folder:
           ##              write.table(land, 
           ##                          paste("$PREF", "_land.txt", sep = ""), 
           ##                          sep = "\t", na = "NA", col.names = FALSE)
           ##              ##############################
           ##              
           ##              SCRIPT
           ##              
           ##              echo "All done, results in $OUTF/"
           ##              
           ##              ##############################
           ##              # PK: My other addition (to move the dfg file to the right folder):
           ##              mv ${PREF}_land.txt $OUTF/
           ##              ##############################

# We therefore run this script:
bash dnaPT_utils/dnaPT_landscapes_PK_edit.sh -I Project/output_${NAME} -p dnaPT_utils_outputs_${NAME}

# --------------------------------------------------------------------------------
# TO SAVE SPACE ON HPC, DELETE ALL FILES THAT ARE NO LONGER NEEDED:

# The key outputs (which we want to keep) are the following:
      # ${NAME}_dfg.txt    (the table that we will use to plot genomic proportions for each wasp, by collating all the data from each individual)
      # dnaPT_utils_outputs_${NAME}.charts.pdf     (a pie chart PDF produced by dnaPT_utils, for this wasp - useful for a quick overview of this sample's results)
      # dnaPT_utils_outputs_${NAME}_landscapes_subclass.pdf
      # ${NAME}_land.txt

# Navigate to the right folder:
cd /user/work/pk14885/Project/output_${NAME}

# Remove the 'Annotation' and 'blast_out' folders for this wasp:
rm -r Annotation
rm -r blast_out

# Remove the following files for this wasp, which we no longer need:
rm Trinity*
rm Bases*
rm blast*
rm colors
rm Counts.txt
rm factors_and_colors
rm reads*
rm Reads_to_components_Rtable.txt
rm renamed.blasting_reads.fasta
rm TEs_piechart.pdf
rm sorted_families
rm sorted_reads_per_component
rm *fasta

# We also no longer need the sorted fastq file for this wasp, so it can be removed from HPC:
cd /user/work/pk14885/Project/data
rm ${NAME}.SAMPLE_R1.fastq.gz

# --------------------------------------------------------------------------------
# MANUAL STEPS ONCE THE ARRAY JOB HAS COMPLETED: NOW DOWNLOAD THE OUTPUTS TO THE LOCAL COMPUTER

# Once all the wasps have completed, move all the outputs to 'Completed_TE_outputs' within the 'Project' folder:
## mv output* Completed_TE_outputs/

# Some wasps may have failed, leaving a large fasta file in the folder but no outputs. We can remove these
# manually, to avoid including them unnecessarily in the scp download. To find the largest file, use:
## du -sk * | sort -nr | head -1
# Then open the wasp's TE output folder. If no results, delete this wasp's TE output folder.

# Similarly, some wasps may have failed, leaving an empty folder. Remove these using:
find . -type d -empty -delete

# On BluePebble, now use the 'tar' function to compress the outputs folder:
##tar czf Completed_TE_outputs.tar.gz Completed_TE_outputs

# From the local machine, now use 'scp' to download the compressed Completed_TE_outputs.tar.gz file,
# and then unzip it by double-clicking on the file.

# The next steps are in R on the local machine (in the script 'R_script_for_TE_outputs.R').


