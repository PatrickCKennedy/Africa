#!/bin/bash
#SBATCH --job-name=Chunk_of_distANGSD
#SBATCH --cpus-per-task=4       # Number of threads
#SBATCH --mem=10G
#SBATCH --time=12:00:00
#SBATCH --output=logs/dA_chunk_%A_%a.out
#SBATCH --error=logs/dA_chunk_%A_%a.out
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --array=1-453628   # e.g., for 953 wasps, there are (953-952)/2=453628 pairwise comparisons to run.

# ------------------------------------------------------------------------------
# Set the script to stop early in a pipeline if there is a problem, rather than waiting until it finishes:
set -euo pipefail

my_pair_list="/user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder/distangsd_results/pairs.tsv"  # set by submitter
my_chunk_size_to_run=200                       # Each array task will work through this number of pairs of genomes.
my_choice_of_phylogenetic_model_to_run="JC"    # Here, we run Jukes-Cantor (JC), but an alternative would be General Time Reversible (GTR)
my_path_to_distANGSD_executable_file="/user/work/pk14885/distAngsd/distAngsd"                   # binary or full path

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

# Make a folder in which to store the output log files:
mkdir -p logs

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

  if [[ -z "${A:-}" || -z "${B:-}" || -z "${OUTPFX:-}" ]]; then
    echo "WARN: Malformed line ${line}" >&2
    continue
  fi
  if [[ ! -f "$A" || ! -f "$B" ]]; then
    echo "WARN: Missing BAM(s) at line ${line}: $A or $B" >&2
    continue
  fi

  # Double-check that there are corresponding BAI files for these BAM files:
  [[ -f "${A}.bai" || -f "${A%.bam}.bai" ]] || echo "WARN: Missing index for $A" >&2
  [[ -f "${B}.bai" || -f "${B%.bam}.bai" ]] || echo "WARN: Missing index for $B" >&2

  # Print (to the log file) the date, time, and the two wasp genomes that are being compared here:          
  echo ">> $(date +'%F %T')  ${A##*/} vs ${B##*/}"

  # The code below uses a "first in, first out" (FIFO) pipe approach, which creates a pipe without writing
  # the temporary files to the disk:
              # Set the address of the FIFO pipe (it is called a .gz file in the filename, but because this is a FIFO
              # it isn't actually a .gz and doesn't actually store a gzip file on the disk):
              FIFO="${directory_to_work_in}/pair.mpileup.gz"
              mkfifo "$FIFO"
            
              # The "producer" for the FIFO pipe, which sends the data in. First, we
              # run mpileup in SAMTOOLS, then bgzip to compress the output, and then send it into the FIFO pipe:
              ( set -o pipefail; samtools mpileup "$A" "$B" | bgzip -c > "$FIFO" ) &  background_process_ID_of_FIFO_producer=$!

  # The FIFO pipe "consumer" is distANGSD (i.e., distANGSD reads the output from the FIFO pipe). A FIFO consumer
  # reads the output of the pipe at the same time as the producer feeds it in, which is why a FIFO is not a regular
  # file. So here the FIFO pipe completes by running distANGSD on the output:
              set +e
              "$my_path_to_distANGSD_executable_file" \
                -mpileup "$FIFO" \
                -method nuc \
                -o "$OUTPFX" \
                -my_choice_of_phylogenetic_model_to_run "$my_choice_of_phylogenetic_model_to_run" \
                -is2Dinfer 0 \
                -isex 0 \
                -isthreading 1
              STATUS=$?
              set -e
  # In the distANGSD command above, the method is set to "nuc" (as opposed to "geno").

  # Now check that the FIFO producer has successfully worked through the job, and then remove this FIFO:
              # Wait (i.e., pause the scrit from running) until the producer has finished feeding into the FIFO pipe:
              wait $background_process_ID_of_FIFO_producer || true
              # Once the producer has finished, remove the FIFO from the system:
              rm -f "$FIFO"
              
  # If distANGSD didn't work for this pair, report it to the log file:
              if (( STATUS != 0 )); then
                echo "ERROR: distAngsd failed for ${A##*/} vs ${B##*/} (line ${line})." >&2
              else
                echo "SUCCESSFULLY COMPLETED : ${OUTPFX}"
              fi
              
 # End of the loop through all the pairwise comparisons in this chunk:              
 done
            
