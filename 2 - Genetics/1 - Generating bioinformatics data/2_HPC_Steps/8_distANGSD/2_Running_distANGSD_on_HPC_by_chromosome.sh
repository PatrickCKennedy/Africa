#!/usr/bin/env bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=10G
#SBATCH --time=12:00:00
#SBATCH --output=logs/%A_%a.out
#SBATCH --error=logs/%A_%a.err

set -euo pipefail

# Load modules
module load samtools
module load htslib
module load parallel

# Get environment variables from submission script
PAIR_LIST="${my_pair_list}"
CHUNK_SIZE="${my_chunk_size_to_run}"
MODEL="${my_choice_of_phylogenetic_model_to_run}"

# Determine which chunk this task should process
TASK_ID=${SLURM_ARRAY_TASK_ID}
START=$(( (TASK_ID - 1) * CHUNK_SIZE + 1 ))
END=$(( TASK_ID * CHUNK_SIZE ))

# Extract the relevant lines (pairs) for this chunk
PAIRS=$(sed -n "${START},${END}p" "$PAIR_LIST")

echo "Processing chunk ${TASK_ID}: lines ${START}-${END}"

# Loop through each pair in this chunk
while read -r A_local B_local; do
    echo ">> $(date) Processing pair: $A_local vs $B_local"

    # Get chromosome list from first BAM
    chroms=$(samtools view -H "$A_local" | awk '$1=="@SQ"{print $2}' | cut -d: -f2)

    # Output prefix
    prefix=$(basename "$A_local" .bam)_vs_$(basename "$B_local" .bam)
    outdir="results/${prefix}"
    mkdir -p "$outdir"

    # Run mpileup per chromosome in parallel
    echo "$chroms" | parallel -j ${SLURM_CPUS_PER_TASK} \
        "samtools mpileup -B -q 20 -Q 20 -r {} $A_local $B_local | bgzip -@ 1 -l 1 > $outdir/{}.mpileup.gz"

    # Concatenate all chromosome outputs into one file
    cat $outdir/*.mpileup.gz > $outdir/${prefix}.mpileup.gz

    # Optional: index combined file
    tabix -p mpileup $outdir/${prefix}.mpileup.gz

done <<< "$PAIRS"
``
