#!/bin/bash
#SBATCH --job-name=Chunk_of_distANGSD
#SBATCH --cpus-per-task=16
#SBATCH --mem=10G
#SBATCH --time=12:00:00
#SBATCH --output=logs/dA_chunk_%A_%a.out
#SBATCH --error=logs/dA_chunk_%A_%a.out
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282

set -euo pipefail

# Inherited from submission script:
my_pair_list="${my_pair_list}"                            
my_chunk_size_to_run="${my_chunk_size_to_run}"            
my_choice_of_phylogenetic_model_to_run="${my_choice_of_phylogenetic_model_to_run}"   

# distANGSD executable:
my_path_to_distANGSD_executable_file="/user/work/pk14885/distAngsd/distAngsd"

# ------------------------------------------------------------------------------
# Array task math
ID_of_this_task_in_the_array_job="${SLURM_ARRAY_TASK_ID:?Need --array and SLURM_ARRAY_TASK_ID}"
starting_pair_in_this_chunk=$(((ID_of_this_task_in_the_array_job - 1) * my_chunk_size_to_run + 1))
last_pair_in_this_chunk=$(( starting_pair_in_this_chunk + my_chunk_size_to_run - 1 ))
total_number_of_pairs_across_the_whole_array_job=$(wc -l < "$my_pair_list")

# ------------------------------------------------------------------------------
# Modules
module load samtools/1.19.2-737f
module load htslib/1.19.1-jbbb

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

mkdir -p logs results
task_results="results/distances.${SLURM_ARRAY_TASK_ID}.tsv"
[[ -f "$task_results" ]] || echo -e "A\tB\tOUTPFX\tmodel\tmethod\tt\tp_inv" > "$task_results"

# ------------------------------------------------------------------------------
# Bounds
if (( starting_pair_in_this_chunk > total_number_of_pairs_across_the_whole_array_job )); then
  echo "Nothing to do for task ${ID_of_this_task_in_the_array_job}"
  exit 0
fi
(( last_pair_in_this_chunk > total_number_of_pairs_across_the_whole_array_job )) && last_pair_in_this_chunk=$total_number_of_pairs_across_the_whole_array_job

echo "Task ${ID_of_this_task_in_the_array_job}: lines ${starting_pair_in_this_chunk}-${last_pair_in_this_chunk}"

# ------------------------------------------------------------------------------
# Scratch directory
temporary_root="${SLURM_TMPDIR:-/tmp}"
directory_to_work_in="$(mktemp -d "${temporary_root}/dA.${ID_of_this_task_in_the_array_job}.XXXX")"
trap 'rm -rf "$directory_to_work_in"' EXIT

scratch_bam_dir="${directory_to_work_in}/bams"
mkdir -p "$scratch_bam_dir"

localize_bam() {
  local src="$1"
  local dst="${scratch_bam_dir}/$(basename "$src")"
  cp -f "$src" "$dst"
  if [[ -f "${src}.bai" ]]; then cp -f "${src}.bai" "${dst}.bai"; fi
  echo "$dst"
}

# ------------------------------------------------------------------------------
# Main loop
for (( line=starting_pair_in_this_chunk; line<=last_pair_in_this_chunk; line++ )); do
  IFS=$'\t' read -r A B OUTPFX < <(sed -n "${line}p" "$my_pair_list")
  [[ -z "$A" || -z "$B" || -z "$OUTPFX" ]] && continue

  echo ">> $(date +'%F %T')  ${A##*/} vs ${B##*/}"
  outdir="$(dirname "$OUTPFX")"; mkdir -p "$outdir"

  A_local="$(localize_bam "$A")"
  B_local="$(localize_bam "$B")"

  pair_scratch="${directory_to_work_in}/$(basename "$OUTPFX")"
  mkdir -p "$pair_scratch"
  outbase="$(basename "$OUTPFX")"
  mpileup_gz="${pair_scratch}/${outbase}.mpileup.txt.gz"

  # Chromosome list
  chroms="$(samtools view -H "$A_local" | awk '$1=="@SQ"{for(i=1;i<=NF;i++){if($i~/^SN:/){sub(/^SN:/,"",$i); print $i}}}')"
  [[ -z "$chroms" ]] && { echo "ERROR: No chromosomes found"; continue; }

  jobs="${SLURM_CPUS_PER_TASK}"
  n_chroms=$(echo "$chroms" | wc -l)
  (( jobs > n_chroms )) && jobs="$n_chroms"

  echo "$chroms" | parallel -j "$jobs" \
    "samtools mpileup -B -q 20 -Q 20 -r {} '$A_local' '$B_local' | bgzip -@ 1 -l 1 > '${pair_scratch}/{}.mpileup.txt.gz'"

  # Combine chunks
  find "$pair_scratch" -name '*.mpileup.txt.gz' -size +0c -print0 | sort -z | xargs -0 cat > "$mpileup_gz"

  # Run distANGSD
  set +e
  dist_out="$(
    "$my_path_to_distANGSD_executable_file" \
      -mpileup "$mpileup_gz" \
      -method nuc \
      -model "$my_choice_of_phylogenetic_model_to_run" \
      -o "$OUTPFX" \
      -is2Dinfer 0 -isex 0 -isthreading 1
  )"
  STATUS=$?
  set -e

  t_value="$(printf '%s\n' "$dist_out" | awk -F'=' '/Estimated t[[:space:]]*=/{gsub(/[[:space:]]*/, "", $2); print $2}')"

  rm -f "$mpileup_gz" "$pair_scratch"/*.mpileup.txt.gz || true

  if (( STATUS != 0 )) || [[ -z "$t_value" ]]; then
    echo "ERROR: distANGSD failed or t not parsed for ${A##*/} vs ${B##*/}"
    printf '%s\n' "$dist_out"
  else
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
      "${A##*/}" "${B##*/}" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" "nuc" \
      "$t_value" "${p_inv_value:-}" >> "$task_results"
    echo "SUCCESS: ${OUTPFX} (t=${t_value})"
  fi
done
