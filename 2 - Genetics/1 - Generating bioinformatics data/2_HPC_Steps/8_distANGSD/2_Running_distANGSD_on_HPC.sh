#!/bin/bash
#SBATCH --job-name=Chunk_of_distANGSD
#SBATCH --cpus-per-task=16       # Number of threads
#SBATCH --mem=10G
#SBATCH --time=12:00:00
#SBATCH --output=logs/dA_chunk_%A_%a.out
#SBATCH --error=logs/dA_chunk_%A_%a.out
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
# (array range is set by the submission script)

# ------------------------------------------------------------------------------
# Safety and error handling
set -euo pipefail

# Inherited from submission script:
my_pair_list="${my_pair_list}"                            # TSV: A\tB\tOUTPFX
my_chunk_size_to_run="${my_chunk_size_to_run}"            # Number of pairs per array task
my_choice_of_phylogenetic_model_to_run="${my_choice_of_phylogenetic_model_to_run}"   # e.g. JC or GTR

# distANGSD executable:
my_path_to_distANGSD_executable_file="/user/work/pk14885/distAngsd/distAngsd"

# Optional: set to 1 if your distANGSD build accepts plain gzip (NOT bgzip)
USE_PIGZ=0

# ------------------------------------------------------------------------------
# Array task math
ID_of_this_task_in_the_array_job="${SLURM_ARRAY_TASK_ID:?Need --array and SLURM_ARRAY_TASK_ID}"
starting_pair_in_this_chunk=$(((ID_of_this_task_in_the_array_job - 1) * my_chunk_size_to_run + 1))
last_pair_in_this_chunk=$(( starting_pair_in_this_chunk + my_chunk_size_to_run - 1 ))
total_number_of_pairs_across_the_whole_array_job=$(wc -l < "$my_pair_list")

# ------------------------------------------------------------------------------
# Modules
module load samtools/1.19.2-737f
module load htslib/1.19.1-jbbb     # provides bgzip
if [[ "$USE_PIGZ" -eq 1 ]]; then module load pigz; fi

# Threading for distANGSD (OpenMP)
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

# Basic dirs
mkdir -p logs
mkdir -p results
task_results="results/distances.${SLURM_ARRAY_TASK_ID}.tsv"
[[ -f "$task_results" ]] || echo -e "A\tB\tOUTPFX\tmodel\tmethod\tt\tp_inv" > "$task_results"

# ------------------------------------------------------------------------------
# Bounds and info
if (( starting_pair_in_this_chunk > total_number_of_pairs_across_the_whole_array_job )); then
  echo "Nothing to do for task ${ID_of_this_task_in_the_array_job} (start ${starting_pair_in_this_chunk} > total ${total_number_of_pairs_across_the_whole_array_job})"
  exit 0
fi
(( last_pair_in_this_chunk > total_number_of_pairs_across_the_whole_array_job )) && last_pair_in_this_chunk=$total_number_of_pairs_across_the_whole_array_job

echo "Task ${ID_of_this_task_in_the_array_job}: lines ${starting_pair_in_this_chunk}-${last_pair_in_this_chunk} of ${total_number_of_pairs_across_the_whole_array_job} from $(basename "$my_pair_list")"
echo "Chunk size: ${my_chunk_size_to_run}; CPUs: ${SLURM_CPUS_PER_TASK:-1}; Mem: ${SLURM_MEM_PER_NODE:-${SLURM_MEM_PER_CPU:-?}}"

# ------------------------------------------------------------------------------
# Scratch directory (seekable files, fast I/O)
temporary_root="${SLURM_TMPDIR:-/tmp}"
directory_to_work_in="$(mktemp -d "${temporary_root}/dA.${ID_of_this_task_in_the_array_job}.XXXX")"
cleanup() { rm -rf "$directory_to_work_in"; }
trap cleanup EXIT

# Subdir for localized BAMs
scratch_bam_dir="${directory_to_work_in}/bams"
mkdir -p "$scratch_bam_dir"

# Helper: copy BAM + index to scratch (idempotent)
localize_bam() {
  local src="$1"
  local base; base="$(basename "$src")"
  local dst="${scratch_bam_dir}/${base}"

  # Copy BAM if not present
  if [[ ! -f "$dst" ]]; then
    cp -f "$src" "$dst"
  fi
  # Copy index (handle .bai naming)
  if [[ -f "${src}.bai" ]]; then
    cp -f "${src}.bai" "${dst}.bai"
  elif [[ -f "${src%.bam}.bai" ]]; then
    cp -f "${src%.bam}.bai" "${dst%.bam}.bai"
  else
    echo "WARN: No index found for ${src}" >&2
  fi
  echo "$dst"
}

# ------------------------------------------------------------------------------
# Main loop
for (( line=starting_pair_in_this_chunk; line<=last_pair_in_this_chunk; line++ )); do
  IFS=$'\t' read -r A B OUTPFX < <(sed -n "${line}p" "$my_pair_list")

  # Validate inputs:
  if [[ -z "${A:-}" || -z "${B:-}" || -z "${OUTPFX:-}" ]]; then
    echo "WARN: Malformed line ${line}" >&2
    continue
  fi
  if [[ ! -f "$A" || ! -f "$B" ]]; then
    echo "WARN: Missing BAM(s) at line ${line}: $A or $B" >&2
    continue
  fi

  # Check BAM indexes (warn only)
  [[ -f "${A}.bai" || -f "${A%.bam}.bai" ]] || echo "WARN: Missing index for $A" >&2
  [[ -f "${B}.bai" || -f "${B%.bam}.bai" ]] || echo "WARN: Missing index for $B" >&2

  echo ">> $(date +'%F %T')  ${A##*/} vs ${B##*/}"

  # Ensure OUTPFX dir exists (final outputs go here)
  outdir="$(dirname "$OUTPFX")"
  mkdir -p "$outdir"

  # Localize BAMs to node scratch (speed up I/O)
  A_local="$(localize_bam "$A")"
  B_local="$(localize_bam "$B")"

  # Per-pair scratch subdir and mpileup filename (safe basename)
  pair_scratch="${directory_to_work_in}/$(basename "$OUTPFX")"
  mkdir -p "$pair_scratch"
  outbase="$(basename "$OUTPFX")"
  mpileup_gz="${pair_scratch}/${outbase}.mpileup.txt.gz"

  # Double-check that the coordinates are sorted properly:
  samtools quickcheck -v "$A" "$B" || echo "BAM issues detected"
  
  # Produce mpileup and compress (multi-threaded)
  if [[ "$USE_PIGZ" -eq 1 ]]; then
    # ONLY use pigz if distANGSD accepts plain gzip (not bgzip)
    samtools mpileup -B -q 20 -Q 20 "$A_local" "$B_local" \
      | pigz -c -p "${SLURM_CPUS_PER_TASK}" > "$mpileup_gz"
  else
    # Manual recommends bgzip (block-gzip, seekable)
    samtools mpileup "$A_local" "$B_local" \
      | bgzip -@ "${SLURM_CPUS_PER_TASK}" > "$mpileup_gz"
  fi

  # Run distANGSD on the seekable compressed mpileup file
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

  # Extract t-value
  t_value="$(printf '%s\n' "$dist_out" | awk -F'=' '/Estimated t[[:space:]]*=/{gsub(/[[:space:]]*/, "", $2); print $2}')"

  # Clean up intermediate to save space
  rm -f "$mpileup_gz" || true

  # Log result
  if (( STATUS != 0 )) || [[ -z "${t_value:-}" ]]; then
    echo "ERROR: distANGSD failed or t not parsed for ${A##*/} vs ${B##*/} (line ${line})." >&2
    echo "---- distANGSD stdout/stderr ----"
    printf '%s\n' "$dist_out" | sed 's/^/    /'
    echo "---------------------------------"
  else
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
      "${A##*/}" "${B##*/}" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" "nuc" \
      "$t_value" "${p_inv_value:-}" >> "$task_results"
    echo "SUCCESSFULLY COMPLETED: ${OUTPFX}  (t=${t_value}${p_inv_value:+, p_inv=${p_inv_value}})"
  fi
done
