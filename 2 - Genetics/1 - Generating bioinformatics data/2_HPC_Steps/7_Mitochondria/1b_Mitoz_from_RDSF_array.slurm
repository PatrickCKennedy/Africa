#!/bin/bash
#SBATCH --job-name=MitoZ_array
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=0-06:00:00
#SBATCH --output=logs/mitoz_%A_%a.out
#SBATCH --error=logs/mitoz_%A_%a.err
#SBATCH --array=1-50  # Adjust per batch.
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282

# Load modules:
       module load bwa/0.7.17-hnox
       module load samtools/1.19.2-737f
       module load apptainer/1.3.1-ksax

SCRATCH_BASE="/user/work/pk14885/MitoZ_using_RDSF"
RESULTS_BASE="/user/work/pk14885/MitoZ_results"
MITOZ_IMAGE="/user/work/pk14885/MitoZ_v3.6.sif"
LOG_FILE="/user/work/pk14885/MitoZ_job_log.txt"

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $BATCH_FILE)
CLIMATE=$(echo $LINE | cut -d',' -f1)
POPULATION=$(echo $LINE | cut -d',' -f2)
WASP=$(echo $LINE | cut -d',' -f3)

temporary_scratch_directory_for_this_wasp="$SCRATCH_BASE/$CLIMATE/$POPULATION/$WASP"
results_directory_for_this_wasp="$RESULTS_BASE/$CLIMATE/$POPULATION/$WASP"

# Check scratch directory exists
if [[ ! -d "$temporary_scratch_directory_for_this_wasp" ]]; then
    echo "$(date): [ERROR] Scratch directory missing for $CLIMATE/$POPULATION/$WASP" >> $LOG_FILE
    exit 1
fi

cd "$temporary_scratch_directory_for_this_wasp" || { echo "$(date): [ERROR] Cannot cd to $temporary_scratch_directory_for_this_wasp" >> $LOG_FILE; exit 1; }

# Find FASTQ files
val1=$(echo *val_1*.fq.gz)
val2=$(echo *val_2*.fq.gz)

if [[ ! -f "$val1" || ! -f "$val2" ]]; then
    echo "$(date): [ERROR] Missing FASTQ files for $CLIMATE/$POPULATION/$WASP" >> $LOG_FILE
    exit 1
fi

# --------------------------------------------------------------------------------
# INCREASE THE CONCENTRATION OF MITOCHONDRIAL READS IN THE POOL FOR THIS WASP:
# To do this, we use our reference mitogenome (developed in Wyatt et al.)

 # Map reads to our Wyatt et al. reference mitogenome "final_mitogenome.fasta" (which should already have been indexed using bwa index):
      bwa mem -B 2 -t 8 /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta "$val1" "$val2" | samtools view -bS - > ${population}_${wasp}_mapped.bam
 
# Extract these mapped reads:
      samtools view -b -F 4 ${population}_${wasp}_mapped.bam > ${population}_${wasp}_mito_only.ba

# Convert the bam file to a FASTQ file:
      samtools fastq ${population}_${wasp}_mito_only.bam -1 ${population}_${wasp}_mito_filtered_R1.fq.gz -2 ${population}_${wasp}_mito_filtered_R2.fq.gz

# --------------------------------------------------------------------------------
# RUN MITOZ FOR EACH WASP:

# Here, we use the apptainer container for MitoZ, which we have installed at "/user/work/pk14885/MitoZ_v3.6.sif"

# Run MitoZ:
echo "$(date): [INFO] Starting MitoZ for $CLIMATE/$POPULATION/$WASP" >> $LOG_FILE
apptainer run -B "$temporary_scratch_directory_for_this_wasp:$temporary_scratch_directory_for_this_wasp" "$MITOZ_IMAGE" mitoz all \
    --fq1 $temporary_scratch_directory_for_this_wasp/${population}_${wasp}_mito_filtered_R1.fq.gz \
    --fq2 $temporary_scratch_directory_for_this_wasp/${population}_${wasp}_mito_filtered_R2.fq.gz \
    --outprefix "${CLIMATE}_${POPULATION}_${WASP}" \
    --genetic_code 5 \
    --clade Arthropoda \
    --fastq_read_length 150 \
    --data_size_for_mt_assembly 0.3 \
    --assembler spades \
    --thread_number 8 \
    --memory 30 \
    --requiring_taxa Arthropoda

# Check if MitoZ succeeded:
if [[ $? -eq 0 ]]; then
    echo "$(date): [INFO] MitoZ completed for $CLIMATE/$POPULATION/$WASP" >> $LOG_FILE
else
    echo "$(date): [ERROR] MitoZ failed for $CLIMATE/$POPULATION/$WASP" >> $LOG_FILE
    exit 1
fi

# Stage output to permanent results directory:
mkdir -p "$results_directory_for_this_wasp"
cp "$temporary_scratch_directory_for_this_wasp"/* "$results_directory_for_this_wasp/" && echo "$(date): [INFO] Results copied for $CLIMATE/$POPULATION/$WASP" >> $LOG_FILE

# Clean up scratch by deleting it for this wasp:
rm -rf "$temporary_scratch_directory_for_this_wasp" && echo "$(date): [INFO] Scratch cleaned for $CLIMATE/$POPULATION/$WASP" >> $LOG_FILE
