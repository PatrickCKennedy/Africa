#!/bin/bash

# ================================
# CONFIGURATION
# ================================
# Paths
BASE_DIR="/Volumes/Social_evolution_in_animals/Adaptor_trimmed_sequences/Organised_by_population/Southern_Cameroon/Rest_of_Yaounde1"
OUTPUT_BASE="/Volumes/Social_evolution_in_animals/COX1_outputs_run_locally_for_Rest_of_Yaounde1"
REFERENCE="/Users/pk14885/Downloads/UCL_Genome_MitoHiFi/final_mitogenome.fasta"
HEADER_NAME=$(head -n 1 $REFERENCE | sed 's/>//')

# Population and climate zone
POPULATION_NAME="Rest_of_Yaounde1"
CLIMATE_ZONE="Southern_Cameroon"

# COX1 gene coordinates
COX1_START=3417
COX1_END=4955

# Number of parallel jobs (adjust based on CPU cores)
JOBS=4

# ================================
# STEP 1: Generate list of wasps
# ================================
cd "$BASE_DIR"
ls -d * > Wasps_to_target_with_MitoZ.filelist

# ================================
# STEP 2: Define processing function
# ================================
process_wasp() {
    wasp=$1
    WORKDIR="$OUTPUT_BASE/$CLIMATE_ZONE/$POPULATION_NAME/$wasp"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR" || exit

    # Locate trimmed files
    val1=$(ls "$BASE_DIR/$wasp"/*val_1*)
    val2=$(ls "$BASE_DIR/$wasp"/*val_2*)

    echo "Processing $wasp..."

    # Map reads to reference mitogenome
    bwa mem -t 8 $REFERENCE $val1 $val2 | samtools view -Sb - > ${wasp}.bam

    # Sort and index BAM
    samtools sort ${wasp}.bam -o ${wasp}_sorted.bam
    samtools index ${wasp}_sorted.bam

    # Variant calling and consensus
    bcftools mpileup -Ou -f $REFERENCE ${wasp}_sorted.bam | \
        bcftools call -mv -Oz -o ${wasp}.vcf.gz
    bcftools index ${wasp}.vcf.gz

    cat $REFERENCE | bcftools consensus ${wasp}.vcf.gz > ${wasp}_consensus.fasta

    # Extract COX1 region
    samtools faidx ${wasp}_consensus.fasta ${HEADER_NAME}:${COX1_START}-${COX1_END} > ${wasp}_COX1_raw.fasta
    seqtk seq -r ${wasp}_COX1_raw.fasta > ${POPULATION_NAME}_${wasp}_COX1_output.fasta

    # Coverage calculation
    samtools depth -a -r "${HEADER_NAME}:${COX1_START}-${COX1_END}" ${wasp}_sorted.bam | \
        awk -v sample="$wasp" '{sum+=$3} END {print sample, "Average coverage:", sum/NR}' >> "$OUTPUT_BASE/coverage_summary.txt"

    # Rename FASTA header
    awk -v header="${POPULATION_NAME}_${wasp}" 'NR==1{$0=">"header}1' ${POPULATION_NAME}_${wasp}_COX1_output.fasta > tmp.fasta && mv tmp.fasta ${POPULATION_NAME}_${wasp}_COX1_output.fasta

    echo "Finished $wasp"
}

export -f process_wasp

# ================================
# STEP 3: Run in parallel
# ================================
cat Wasps_to_target_with_MitoZ.filelist | parallel -j $JOBS process_wasp {}

echo "All jobs completed!"
