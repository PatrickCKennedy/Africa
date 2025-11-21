#!/bin/bash
#SBATCH --job-name=Samtools_Mito_array
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
module load bcftools/1.19-openblas-5yp2
module load seqtk/1.4-rcyr

SCRATCH_BASE="/user/work/pk14885/Samtools_Mito_using_RDSF"
RESULTS_BASE="/user/work/pk14885/Samtools_Mito_results"
LOG_FILE="/user/work/pk14885/Samtools_Mito_job_log.txt"

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $BATCH_FILE)
climate=$(echo $LINE | cut -d',' -f1)
population=$(echo $LINE | cut -d',' -f2)
wasp=$(echo $LINE | cut -d',' -f3)

temporary_scratch_directory_for_this_wasp="$SCRATCH_BASE/$climate/$population/$wasp"
results_directory_for_this_wasp="$RESULTS_BASE/$climate/$population/$wasp"

# Check that the scratch directory exists:
if [[ ! -d "$temporary_scratch_directory_for_this_wasp" ]]; then
    echo "$(date): [ERROR] Scratch directory missing for $climate/$population/$wasp" >> $LOG_FILE
    exit 1
fi

cd "$temporary_scratch_directory_for_this_wasp" || { echo "$(date): [ERROR] Cannot cd to $temporary_scratch_directory_for_this_wasp" >> $LOG_FILE; exit 1; }

# Find FASTQ files:
val1=$(echo *val_1*.fq.gz)
val2=$(echo *val_2*.fq.gz)

if [[ ! -f "$val1" || ! -f "$val2" ]]; then
    echo "$(date): [ERROR] Missing FASTQ files for $climate/$population/$wasp" >> $LOG_FILE
    exit 1
fi

# ---------------------------------------------------------------------------------
# MAP AGAINST THE REFERENCE MITOCHONDRIAL GENOME:
# We have assembled the reference mitochondrial genome as part of a wider project elsewhere to
# provide the reference genome for Belonogaster juncea (Wyatt et al.). The mitochondrial genome
# from that reference is in the file /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta

header_name=$(head -n 1 /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta | sed 's/>//')
coverage_threshold=3  # Positions with depth <3 will be masked

# Make sure we are in the scratch directory:
cd "$temporary_scratch_directory_for_this_wasp"

# Map reads and create sorted BAM:
bwa mem -t 8 /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta $val1 $val2 \
    | samtools view -Sb - \
    | samtools sort -o ${wasp}_sorted.bam
samtools index ${wasp}_sorted.bam

# Generate VCF:
bcftools mpileup -Ou -f /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta ${wasp}_sorted.bam \
    | bcftools call -mv -Oz -o ${wasp}.vcf.gz
bcftools index ${wasp}.vcf.gz

# We now mask the low coverage positions (positions with a depth <3) to avoid reference bias:
samtools depth -a ${wasp}_sorted.bam \
    | awk -v thr=$coverage_threshold '$3<thr {print $1"\t"$2-1"\t"$2}' > lowcov.bed

# Generate consensus FASTA with masking:
cat /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta \
    | bcftools consensus --mask lowcov.bed ${wasp}.vcf.gz \
    > ${wasp}_consensus_masked.fasta

# -----------------------------------------------------------------------------------
# EXTRACT THE COX1 REGION:
# The start and end positions for the COX1 gene are detailed in the GenBank-syle file 'final_mitogenome.gb',
# and are 3417 to 4955.

# Next, extract the COX1 gene from the reference mitogenome:
COX1_START=3417
COX1_END=4955

# Extract COX1 region and reverse complement:
samtools faidx ${wasp}_consensus_masked.fasta ${header_name}:${COX1_START}-${COX1_END} \
    > ${wasp}_COX1_raw.fasta
seqtk seq -r ${wasp}_COX1_raw.fasta \
    > ${population}_${wasp}_COX1_output.fasta

# Replace header with sample name:
awk -v header="${population}_${wasp}" 'NR==1{$0=">"header}1' \
    ${population}_${wasp}_COX1_output.fasta > tmp.fasta && mv tmp.fasta ${population}_${wasp}_COX1_output.fasta

# Calculate coverage summary:
samtools depth -a -r "${header_name}:${COX1_START}-${COX1_END}" ${wasp}_sorted.bam \
    | awk -v sample="${wasp}" '{sum+=$3} END {print sample, "Average coverage:", sum/NR}' \
    >> /user/work/pk14885/Samtools_Mito_coverage_summary.txt

# -----------------------------------------------------------------------------------
# EXTRACT THE cytb REGION:
# The start and end positions for the cytb gene are detailed in the GenBank-syle file 'final_mitogenome.gb',
# and are 16417 to 17397.

# Next, extract the cytb gene from the reference mitogenome:
cytb_START=16417
cytb_END=17397

# Extract cytb region and reverse complement:
samtools faidx ${wasp}_consensus_masked.fasta ${header_name}:${cytb_START}-${cytb_END} \
    > ${wasp}_cytb_raw.fasta
seqtk seq -r ${wasp}_cytb_raw.fasta \
    > ${population}_${wasp}_cytb_output.fasta

# Replace header with sample name:
awk -v header="${population}_${wasp}" 'NR==1{$0=">"header}1' \
    ${population}_${wasp}_cytb_output.fasta > cytb_tmp.fasta && mv cytb_tmp.fasta ${population}_${wasp}_cytb_output.fasta

# Calculate coverage summary:
samtools depth -a -r "${header_name}:${cytb_START}-${cytb_END}" ${wasp}_sorted.bam \
    | awk -v sample="${wasp}" '{sum+=$3} END {print sample, "Average coverage:", sum/NR}' \
    >> /user/work/pk14885/Samtools_Mito_cytb_coverage_summary.txt

# -----------------------------------------------------------------------------------
# EXTRACT THE ND5 REGION:
# The start and end positions for the ND5 gene are detailed in the GenBank-syle file 'final_mitogenome.gb',
# and are 19948 to 21189.

# Next, extract the ND5 gene from the reference mitogenome:
ND5_START=19948
ND5_END=21189

# Extract ND5 region and reverse complement:
samtools faidx ${wasp}_consensus_masked.fasta ${header_name}:${ND5_START}-${ND5_END} \
    > ${wasp}_ND5_raw.fasta
seqtk seq -r ${wasp}_ND5_raw.fasta \
    > ${population}_${wasp}_ND5_output.fasta

# Replace header with sample name:
awk -v header="${population}_${wasp}" 'NR==1{$0=">"header}1' \
    ${population}_${wasp}_ND5_output.fasta > ND5_tmp.fasta && mv ND5_tmp.fasta ${population}_${wasp}_ND5_output.fasta

# Calculate coverage summary:
samtools depth -a -r "${header_name}:${ND5_START}-${ND5_END}" ${wasp}_sorted.bam \
    | awk -v sample="${wasp}" '{sum+=$3} END {print sample, "Average coverage:", sum/NR}' \
    >> /user/work/pk14885/Samtools_Mito_ND5_coverage_summary.txt

# ---------------------------------------------------------------------------------
# TIDY UP THE SCRATCH DIRECTORY TO SAVE SPACE:
# The original data is safely untouched in the RDSF.

# Delete the large input files from the scratch directory:
       cd $temporary_scratch_directory_for_this_wasp
       rm $val1
       rm $val2
       rm ${population}_${wasp}_mito_filtered_R1.fq.gz
       rm ${population}_${wasp}_mito_filtered_R2.fq.gz
       rm ${wasp}_sorted.bam
       rm lowcov.bed

# Stage output to permanent results directory:
       mkdir -p "$results_directory_for_this_wasp"
       cp -r "$temporary_scratch_directory_for_this_wasp"/* "$results_directory_for_this_wasp/" && echo "$(date): [INFO] Results copied for $climate/$population/$wasp" >> $LOG_FILE

# Clean up scratch by deleting it entirely for this wasp:
       rm -rf "$temporary_scratch_directory_for_this_wasp" && echo "$(date): [INFO] Scratch cleaned for $climate/$population/$wasp" >> $LOG_FILE
