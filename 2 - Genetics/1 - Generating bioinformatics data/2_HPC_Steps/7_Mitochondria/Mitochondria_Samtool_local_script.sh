#!/bin/bash

# Previously, installed required tools using:
##conda create -n mitoz_env bwa samtools bcftools seqtk parallel -c bioconda

# Activate the conda environment above first before running this file.
##conda init bash
##conda activate mitoz_env

# Then run the current file using:
##chmod +x Mitochondria_Samtool_local_script.sh
##./Mitochondria_Samtool_local_script.sh

# -------------------------------------------------------------------
# MANUALLY SPECIFY THE POPULATION OF INTEREST:

POPULATION_NAME="Rest_of_Yaounde1"
CLIMATE_ZONE="Southern_Cameroon"

# -------------------------------------------------------------------
# Make a directory to store the outputs for this population:
mkdir -p /Users/pk14885/Downloads/COX1_local_outputs/$CLIMATE_ZONE/$POPULATION_NAME

# -------------------------------------------------------------------
# Prepare list of wasps in the target population:
cd /Volumes/Social_evolution_in_animals/Adaptor_trimmed_sequences/Organised_by_population/$CLIMATE_ZONE/$POPULATION_NAME
ls -d * > Wasps_to_target_with_MitoZ.filelist

# Make sure the reference mitogenome has previously been indexed (this only needs to be run once):
##bwa index /Users/pk14885/Downloads/UCL_Genome_MitoHiFi/final_mitogenome.fasta
##samtools faidx /Users/pk14885/Downloads/UCL_Genome_MitoHiFi/final_mitogenome.fasta

# -------------------------------------------------------------------
# LOOP THROUGH ALL THE WASPS (RUNNING 8 WASPS IN PARALLEL):

process_wasp() {
    wasp=$1
    mkdir -p /Users/pk14885/Downloads/COX1_local_outputs/$CLIMATE_ZONE/$POPULATION_NAME/$wasp
    cd /Users/pk14885/Downloads/COX1_local_outputs/$CLIMATE_ZONE/$POPULATION_NAME/$wasp || exit

    # Locate adaptor-trimmed files:
    val1=$(ls "/Volumes/Social_evolution_in_animals/Adaptor_trimmed_sequences/Organised_by_population/Southern_Cameroon/Rest_of_Yaounde1/$wasp"/*val_1*)
    val2=$(ls "/Volumes/Social_evolution_in_animals/Adaptor_trimmed_sequences/Organised_by_population/Southern_Cameroon/Rest_of_Yaounde1/$wasp"/*val_2*)

    echo "Processing wasp $wasp"

    # Map reads to reference mitogenome:
    bwa mem -t 8 /Users/pk14885/Downloads/UCL_Genome_MitoHiFi/final_mitogenome.fasta $val1 $val2 | samtools view -Sb - > ${wasp}.bam

    # Sort & index:
    samtools sort ${wasp}.bam -o ${wasp}_sorted.bam
    samtools index ${wasp}_sorted.bam

    # Calculate average coverage:
    avg_cov=$(samtools depth -a -r "atg000004l_rc_rotated:3417-4955" ${wasp}_sorted.bam \
        | awk '{sum+=$3} END {if(NR>0) print sum/NR; else print 0}')

    echo "$wasp Average coverage: $avg_cov" >> /Users/pk14885/Downloads/COX1_local_outputs/coverage_summary.txt

    # Skip if coverage < 20:
    if (( $(echo "$avg_cov < 20" | bc -l) )); then
        echo "Skipping $wasp (coverage $avg_cov < 20)"
        return
    fi

    # Variant calling:
    bcftools mpileup -Ou -f $REFERENCE ${wasp}_sorted.bam | \
        bcftools call -mv -Oz -o ${wasp}.vcf.gz
    bcftools index ${wasp}.vcf.gz

    # Mask low coverage positions (<3 reads):
    samtools depth -a ${wasp}_sorted.bam | awk '$3<3{print $1"\t"$2}' > lowcov.mask

    # Generate consensus with masking:
    bcftools consensus --mask lowcov.mask ${wasp}.vcf.gz < $REFERENCE > ${wasp}_consensus.fasta

    # Extract COX1 region:
    samtools faidx ${wasp}_consensus.fasta "atg000004l_rc_rotated:3417-4955" > ${wasp}_COX1_raw.fasta
    seqtk seq -r ${wasp}_COX1_raw.fasta > ${POPULATION_NAME}_${wasp}_COX1_output.fasta

    # Rename FASTA header:
    awk -v header="${POPULATION_NAME}_${wasp}" 'NR==1{$0=">"header}1' ${POPULATION_NAME}_${wasp}_COX1_output.fasta > tmp.fasta && mv tmp.fasta ${POPULATION_NAME}_${wasp}_COX1_output.fasta

    echo "Finished $wasp"
}

export -f process_wasp

# ================================
# STEP 3: Run in parallel using xargs
# ================================
cat Wasps_to_target_with_MitoZ.filelist | xargs -I {} -P 8 bash -c 'process_wasp "$@"' _ {}

echo "All jobs completed!"
