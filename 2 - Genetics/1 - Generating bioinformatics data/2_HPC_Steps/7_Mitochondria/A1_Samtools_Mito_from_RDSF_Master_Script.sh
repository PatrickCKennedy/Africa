#!/bin/bash
# A1_Samtools_Mito_from_RDSF_Master_Script.sh
# This script should be submitted on the login node, because the compute nodes cannot access RDSF.
# This is a master script that imports the wasps in batches from RDSF, and then submits these batches to the
# compute node as array jobs using the separate submission script. This is an efficient way of running
# the jobs, and upload to HPC is much quicker when doing so from RDSF as here than if running from a local
# computer over the internet. The reason why we have this master script is that we first need to upload
# the input files from RDSF on the login nodes (this script) so that they are then visible to the
# sbatch submission script on the compute nodes (next script, 1b).

# To run this script, use:       bash A1_Samtools_Mito_from_RDSF_Master_Script.sh

# --------------------------------------------------------------------------------
# MANUAL STEPS FIRST:

# Before running this script, we first generate a list of all the wasps in the 'Organised_by_population' folder on RDSF (the Research 
# Data Storage Facility at Bristol, where our data is stored).
# In our case, we can do this via: 
        ## cd /user/work/pk14885
        ## find /projects/Social_evolution_in_animals/Adaptor_trimmed_sequences/     -mindepth 4 -maxdepth 4 -type d | awk -F'/' '{print $(NF-2)","$(NF-1)","$NF}' > wasp_list.txt
# That will produce a text file called "wasp_list.txt".
# The contents of that text file should be in this format:
        ## South_Africa,LoversRock,PETIO_LR10_S1
        ## South_Africa,LoversRock,PETIO_LR10_S3
        ## South_Africa,Cowshed,BRIS_CSD_d
        ## South_Africa,Cowshed,CS1_2
# Open it to confirm that it is structured like this, and only contains the wasps and not extraneous other folders on RDSF.
# You can check how many wasps (lines) are in "wasp_list.txt" using:
        ## wc -l wasp_list.txt

# --------------------------------------------------------------------------------
# DEFINE VARIABLES:

RDSF_base_directory="/projects/Social_evolution_in_animals/Adaptor_trimmed_sequences/Organised_by_population"
my_temporary_scratch_directory="/user/work/pk14885/Samtools_Mito_using_RDSF"
my_Job_script="A2_Samtools_Mito_array.sh"
log="batch_log.txt"
batch_size=50

# --------------------------------------------------------------------------------
# CHECK IF THERE IS ENOUGH SPACE TO STAGE THE NEXT BATCH, AND PAUSE TEMPORARILY IF NOT:
# This waits for the previous batch to finish running and the input files to therefore be
# deleted from HPC, before staging (copying over) the next batch from RDSF to scratch.
# Here, you must decide on the maximum size of the 'Samtools_Mito_using_RDSF' folder ("$my_temporary_scratch_directory").
# Check the user-quota on HPC to confirm that your chosen size is within the quota, also
# leaving space for MitoZ's computations.

# Function to check scratch size and pause if above threshold:
check_scratch_usage() {
    THRESHOLD_GB=100  # Adjust as needed.
    CURRENT_SIZE=$(du -s --block-size=1G "$my_temporary_scratch_directory" | awk '{print $1}')
    if (( CURRENT_SIZE > THRESHOLD_GB )); then
        echo "$(date): [WARNING] Scratch usage ${CURRENT_SIZE}GB exceeds ${THRESHOLD_GB}GB. Pausing..." >> $log
        while (( CURRENT_SIZE > THRESHOLD_GB )); do
            sleep 300  # Wait 5 minutes before checking again
            CURRENT_SIZE=$(du -s --block-size=1G "$my_temporary_scratch_directory" | awk '{print $1}')
        done
        echo "$(date): [INFO] Scratch usage back under threshold. Resuming..." >> $log
    fi
}

# --------------------------------------------------------------------------------
# STAGE THE WASPS INTO THE SCRATCH IN BATCHES BY COPYING THEM FROM RDSF:
# The RDSF files remain safely untouched.

# Split wasp_list.txt into batches:
split -l $batch_size wasp_list.txt batch_

for batch_file in batch_*; do
    echo "Processing $batch_file"

   # Check scratch usage before staging, using the function defined above:
    check_scratch_usage
   
    # We stage the files to the scratch directory in parallel:
    while IFS=',' read -r climate_zone population wasp; do
        SRC="$RDSF_base_directory/$climate_zone/$population/$wasp"
        DEST="$my_temporary_scratch_directory/$climate_zone/$population/$wasp"
        mkdir -p "$DEST"
        rsync -av "$SRC/" "$DEST/" &
    done < "$batch_file"
    wait  # Waits for all rsync jobs to finish.

    # Count wasps in this batch:
    COUNT=$(wc -l < "$batch_file")

    # Submit SLURM job for this batch:
    JOB_ID=$(sbatch --array=1-$COUNT --export=BATCH_FILE=$batch_file $my_Job_script | awk '{print $4}')
    echo "$(date): Submitted $batch_file as job $JOB_ID" >> $log
done
