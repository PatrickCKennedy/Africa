#!/bin/bash
#SBATCH --job-name=Chunk_of_distANGSD
#SBATCH --cpus-per-task=16       # Number of threads
#SBATCH --mem=10G
#SBATCH --time=12:00:00
#SBATCH --output=logs/dA_chunk_%A_%a.out
#SBATCH --error=logs/dA_chunk_%A_%a.out
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282

# This is the array job for running distANGSD. To actually submit it on HPC, use the 3_distANGSD_HPC_Submission_Script, which calls it.
# Note: normally, we would add the array in the SBATCH details at the top of the script, but in this case the array range is set in the submission script.

# ------------------------------------------------------------------------------
# Set the script to stop early in a pipeline if there is a problem, rather than waiting until it finishes:
            set -euo pipefail

# The following lines inherit the input variable my_pair_list from the submission script, where they are set manually:
            my_pair_list="${my_pair_list}"                            # The location of the pair list file.                
            my_chunk_size_to_run="${my_chunk_size_to_run}"            # Each array task will work through this number of pairs of genomes.
            my_choice_of_phylogenetic_model_to_run="${my_choice_of_phylogenetic_model_to_run}"   # Here, we run Jukes-Cantor (JC), but an alternative would be General Time Reversible (GTR).

# The path to the distANGSD programme installed on my BluePebble working directory:
            my_path_to_distANGSD_executable_file="/user/work/pk14885/distAngsd/distAngsd"

# ------------------------------------------------------------------------------
# IDENTIFY THE TASK ID OF THIS PARTICULAR RUN OF THE ARRAY JOB:

ID_of_this_task_in_the_array_job="${SLURM_ARRAY_TASK_ID:?Need --array and SLURM_ARRAY_TASK_ID}"
starting_pair_in_this_chunk=$(( (ID_of_this_task_in_the_array_job - 1) * my_chunk_size_to_run + 1 ))
last_pair_in_this_chunk=$(( starting_pair_in_this_chunk + my_chunk_size_to_run - 1 ))
total_number_of_pairs_across_the_whole_array_job=$(wc -l < "$my_pair_list")

# ------------------------------------------------------------------------------
# Make sure that SAMTOOLS and HTSLIB are loaded on BluePebble:
module load samtools/1.19.2-737f
module load htslib/1.19.1-jbbb

# Ensure that the number of threads that we use below in distANGSD lines up with the CPUs allocated to this job by SLURM at the top of the page using cpus-per-task:
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

# Make a folder in which to store the output log files:
mkdir -p logs

# Make a results folder (if it hasn't been produced already by a different run within this array job):
mkdir -p results

# Prepare a .tsv file in which to store the results of this task:
task_results="results/distances.${SLURM_ARRAY_TASK_ID}.tsv"

# Add a header to the file:
[[ -f "$task_results" ]] || echo -e "A\tB\tOUTPFX\tmodel\tmethod\tt\tp_inv" > "$task_results"

# ------------------------------------------------------------------------------
# PREPARE FOR RUNNING distANGSD:

# Make sure that there actually are pairs still to run with this chunk:
            if (( starting_pair_in_this_chunk > total_number_of_pairs_across_the_whole_array_job )); then
              echo "Nothing to do for task ${ID_of_this_task_in_the_array_job} (starting_pair_in_this_chunk ${starting_pair_in_this_chunk} > total_number_of_pairs_across_the_whole_array_job ${total_number_of_pairs_across_the_whole_array_job})"
              exit 0
            fi
            (( last_pair_in_this_chunk > total_number_of_pairs_across_the_whole_array_job )) && last_pair_in_this_chunk=$total_number_of_pairs_across_the_whole_array_job

# Print the information (task ID, chunk size, and memory) for this task:
            echo "Task ${ID_of_this_task_in_the_array_job}: lines ${starting_pair_in_this_chunk}-${last_pair_in_this_chunk} of ${total_number_of_pairs_across_the_whole_array_job} from $(basename "$my_pair_list")"
            echo "The size of this chunk of pairwise comparisons between wasps: ${my_chunk_size_to_run}; CPUs: ${SLURM_CPUS_PER_TASK:-1}; Mem: ${SLURM_MEM_PER_NODE:-${SLURM_MEM_PER_CPU:-?}}"

# Make a temporary directory for this task of the array job to run in:
            temporary_root="${SLURM_TMPDIR:-/tmp}"
            directory_to_work_in="$(mktemp -d "${temporary_root}/dA.${ID_of_this_task_in_the_array_job}.XXXX")"
            cleanup() { rm -rf "$directory_to_work_in"; }
            trap cleanup EXIT

# ------------------------------------------------------------------------------
# RUN distANGSD ON THIS CHUNK OF PAIRWISE COMPARISONS BETWEEN WASPS:

# A loop that runs through each of the pairwise comparisons that will be run within this chunk:
for (( line=starting_pair_in_this_chunk; line<=last_pair_in_this_chunk; line++ )); do
    IFS=$'\t' read -r A B OUTPFX < <(sed -n "${line}p" "$my_pair_list")

    # Validate inputs:
    if [[ -z "$A" || -z "$B" || -z "$OUTPFX" ]]; then
        echo "WARN: Malformed line ${line}" >&2
        continue
    fi
    if [[ ! -f "$A" || ! -f "$B" ]]; then
        echo "WARN: Missing BAM(s) at line ${line}: $A or $B" >&2
        continue
    fi

    # Check BAM indexes:
    [[ -f "${A}.bai" || -f "${A%.bam}.bai" ]] || echo "WARN: Missing index for $A" >&2
    [[ -f "${B}.bai" || -f "${B%.bam}.bai" ]] || echo "WARN: Missing index for $B" >&2

    echo ">> $(date +'%F %T')  ${A##*/} vs ${B##*/}"

    # Use node-local scratch (fast disk):
    scratch_dir="${TMPDIR:-$directory_to_work_in}"
    mpileup_gz="${scratch_dir}/${OUTPFX}.mpileup.txt.gz"

    # Produce mpileup and compress with bgzip (multi-threaded):
    # Note: samtools mpileup is single-threaded; bgzip parallelizes compression.
    set -euo pipefail
    samtools mpileup "$A" "$B" \
      | bgzip -@ "${SLURM_CPUS_PER_TASK:-16}" > "$mpileup_gz"

    # Run distANGSD on the compressed file path:
    set +e
    dist_out="$(
      "$my_path_to_distANGSD_executable_file" \
        -mpileup "$mpileup_gz" \
        -method nuc \
        -model "$my_choice_of_phylogenetic_model_to_run" \
        -o "$OUTPFX" \
        -is2Dinfer 0 \
        -isex 0 \
        -isthreading 1
    )"
    STATUS=$?
    set -e

    # Extract t-value:
    t_value="$(printf '%s\n' "$dist_out" | awk -F'=' '/Estimated t[[:space:]]*=/{gsub(/[[:space:]]*/, "", $2); print $2}')"

    # Optionally clean up intermediate file to save space:
    rm -f "$mpileup_gz" || true

    # Log result:
    if (( STATUS != 0 )) || [[ -z "$t_value" ]]; then
        echo "ERROR: distANGSD failed or t not parsed for ${A##*/} vs ${B##*/} (line ${line})." >&2
    else
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
          "${A##*/}" "${B##*/}" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" "nuc" \
          "$t_value" "${p_inv_value:-}" >> "$task_results"
        echo "SUCCESSFULLY COMPLETED: ${OUTPFX}  (t=${t_value}${p_inv_value:+, p_inv=${p_inv_value}})"
    fi
done
