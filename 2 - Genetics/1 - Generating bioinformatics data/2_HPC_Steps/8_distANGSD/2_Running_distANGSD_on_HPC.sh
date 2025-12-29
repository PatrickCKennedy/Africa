#!/bin/bash
#SBATCH --job-name=Chunk_of_distANGSD
#SBATCH --cpus-per-task=16
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

# ------------------------------------------------------------------------------
# Inherited from submission script via --export
my_pair_list="${my_pair_list}"                            # TSV: A\tB\tOUTPFX
my_chunk_size_to_run="${my_chunk_size_to_run}"            # Number of pairs per array task
my_choice_of_phylogenetic_model_to_run="${my_choice_of_phylogenetic_model_to_run}"   # e.g. JC or GTR
chromosomes_to_include="${chromosomes_to_include:?Set in submission script via --export=...,chromosomes_to_include=...}"

# distANGSD executable:
my_path_to_distANGSD_executable_file="/user/work/pk14885/distAngsd/distAngsd"

# ------------------------------------------------------------------------------
# Array task math
ID_of_this_task_in_the_array_job="${SLURM_ARRAY_TASK_ID:?Need --array and SLURM_ARRAY_TASK_ID}"
starting_pair_in_this_chunk=$(((ID_of_this_task_in_the_array_job - 1) * my_chunk_size_to_run + 1))
last_pair_in_this_chunk=$(( starting_pair_in_this_chunk + my_chunk_size_to_run - 1 ))
total_number_of_pairs_across_the_whole_array_job
total_number_of_pairs_across_the_whole_array_job=$(wc -l < "$my_pair_list")

# ------------------------------------------------------------------------------
# Modules (GNU Parallel is available system-wide; no module needed)
module load samtools/1.19.2-737f
module load htslib/1.19.1-jbbb     # provides bgzip

# Threading for distANGSD (OpenMP)
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

# Basic dirs
mkdir -p logs results

# Central TSVs (shared by all array tasks) + locks
DIST_TABLE="results/distances.all.tsv"
DIST_LOCK="${DIST_TABLE}.lock"

PAIR_SUM_TABLE="results/pair_summaries.all.tsv"
PAIR_SUM_LOCK="${PAIR_SUM_TABLE}.lock"

# Ensure headers exist once
{
  flock 200
  if [[ ! -s "$DIST_TABLE" ]]; then
    printf "A\tB\tOUTPFX\tmodel\tmethod\tt\tp_inv\n" > "$DIST_TABLE"
  fi
} 200>"$DIST_LOCK"

{
  flock 201
  if [[ ! -s "$PAIR_SUM_TABLE" ]]; then
    printf "A\tB\tOUTPFX\tmodel\tn_chroms_used\tn_chroms_nonempty\ttotal_sites\tmean_depth_A\tmean_depth_B\tmax_depth_A\tmax_depth_B\n" > "$PAIR_SUM_TABLE"
  fi
} 201>"$PAIR_SUM_LOCK"

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
directory_to_work_in
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

  # Copy BAM (overwrite to be safe if re-run)
  cp -f "$src" "$dst"

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
# Parse fixed chromosome list from environment (space/newline separated)
readarray -t fixed_chroms < <(printf '%s\n' "$chromosomes_to_include" | tr ' ' '\n' | sed '/^$/d')
if (( ${#fixed_chroms[@]} == 0 )); then
  echo "ERROR: chromosomes_to_include is empty." >&2
  exit 1
fi
echo "Chromosomes requested (from --export): ${fixed_chroms[*]}"

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

  # Quickcheck localized BAMs (non-fatal warnings)
  samtools quickcheck -v "$A_local" "$B_local" || echo "WARN: samtools quickcheck reported issues" >&2

  # Per-pair scratch subdir and final combined mpileup filename (seekable)
  pair_scratch="${directory_to_work_in}/$(basename "$OUTPFX")"
  mkdir -p "$pair_scratch"
  outbase="$(basename "$OUTPFX")"
  mpileup_gz="${pair_scratch}/${outbase}.mpileup.txt.gz"

  # --------------------------------------------------------------------------
  # Intersect requested chromosomes with BAM header contigs (avoid mpileup errors)
  # --------------------------------------------------------------------------
  mapfile -t bam_chroms < <(samtools view -H "$A_local" | awk '$1=="@SQ"{for(i=1;i<=NF;i++){if($i~/^SN:/){sub(/^SN:/,"",$i); print $i}}}')
  declare -A present=()
  for c in "${bam_chroms[@]}"; do present["$c"]=1; done

  filtered=()
  for c in "${fixed_chroms[@]}"; do
    if [[ -n "${present[$c]:-}" ]]; then
      filtered+=( "$c" )
    else
      echo "WARN: Requested chromosome '$c' not in BAM header; skipping it." >&2
    fi
  done

  if (( ${#filtered[@]} == 0 )); then
    echo "ERROR: None of the requested chromosomes are present in BAM header; skipping pair." >&2
    continue
  fi

  # Determine parallel jobs (do not exceed number of selected chromosomes)
  jobs="${SLURM_CPUS_PER_TASK}"
  n_chroms="${#filtered[@]}"
  (( jobs > n_chroms )) && jobs="$n_chroms"

  echo "Using ${n_chroms} chromosomes: ${filtered[*]}"
  printf "%s\n" "${filtered[@]}" \
    | parallel -j "$jobs" --halt now,fail=1 \
        "samtools mpileup -B -q 20 -Q 20 -r {} '$A_local' '$B_local' \
         | bgzip -@ 1 -l 1 > '${pair_scratch}/{}.mpileup.txt.gz'"

  # Count non-empty per-chromosome outputs
  n_nonempty=$(find "$pair_scratch" -maxdepth 1 -name '*.mpileup.txt.gz' -size +0c | wc -l | awk '{print $1}')

  # Concatenate per-chromosome outputs into one seekable stream
  echo ">> Concatenating per-chromosome mpileups -> ${mpileup_gz}"
  if ! find "$pair_scratch" -maxdepth 1 -name '*.mpileup.txt.gz' -size +0c -print0 | sort -z | xargs -0 cat > "$mpileup_gz"; then
    echo "ERROR: Failed to build combined mpileup for ${A##*/} vs ${B##*/}; skipping pair." >&2
    continue
  fi

  if [[ ! -s "$mpileup_gz" ]]; then
    echo "ERROR: Combined mpileup is empty for ${A##*/} vs ${B##*/}; skipping pair." >&2
    continue
  fi

  # --------------------------------------------------------------------------
  # Per-pair summary stats from the combined mpileup (single streaming pass)
  # Columns in mpileup (2-sample): chrom pos ref depthA basesA qualA depthB basesB qualB ...
  # --------------------------------------------------------------------------
  pair_stats="$(bgzip -dc "$mpileup_gz" \
    | awk 'BEGIN{n=0; s1=0; s2=0; max1=0; max2=0}
           {n++; d1=$4+0; d2=$7+0; s1+=d1; s2+=d2; if(d1>max1)max1=d1; if(d2>max2)max2=d2}
           END{ if(n>0){ printf "%d\t%.6f\t%.6f\t%d\t%d", n, s1/n, s2/n, max1, max2 } else { print "0\t0\t0\t0\t0" } }')"

  total_sites=$(echo "$pair_stats" | cut -f1)
  mean_depth_A=$(echo "$pair_stats" | cut -f2)
  mean_depth_B=$(echo "$pair_stats" | cut -f3)
  max_depth_A=$(echo "$pair_stats" | cut -f4)
  max_depth_B=$(echo "$pair_stats" | cut -f5)

  # --------------------------------------------------------------------------
  # Run distANGSD to get a single pairwise t (explicit and captured)
  # --------------------------------------------------------------------------
  echo ">> Running distANGSD: $my_path_to_distANGSD_executable_file -mpileup $mpileup_gz -method nuc -model $my_choice_of_phylogenetic_model_to_run -o $OUTPFX -is2Dinfer 0 -isex 0 -isthreading 1"
  set +e
  dist_out="$(
    "$my_path_to_distANGSD_executable_file" \
      -mpileup "$mpileup_gz" \
      -method nuc \
      -model "$my_choice_of_phylogenetic_model_to_run" \
      -o "$OUTPFX" \
      -is2Dinfer 0 \
      -isex 0 \
      -isthreading 1 \
      2>&1
  )"
  STATUS=$?
  set -e

  # Extract t-value from distANGSD stdout/stderr (format: "Estimated t = X")
  t_value="$(printf '%s\n' "$dist_out" | awk -F'=' '/Estimated t[[:space:]]*=/{gsub(/[[:space:]]*/, "", $2); print $2}')"

  # Clean up intermediates to save space
  rm -f "${pair_scratch}"/*.mpileup.txt.gz || true
  rm -f "$mpileup_gz" || true

  # Append summary row (even if distANGSD failed, so you see coverage metrics)
  {
    flock 201
    printf "%s\t%s\t%s\t%s\t%d\t%d\t%d\t%.6f\t%.6f\t%d\t%d\n" \
      "${A##*/}" "${B##*/}" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" \
      "$n_chroms" "$n_nonempty" "$total_sites" "$mean_depth_A" "$mean_depth_B" "$max_depth_A" "$max_depth_B" \
      >> "$PAIR_SUM_TABLE"
  } 201>"$PAIR_SUM_LOCK"

  # Append to central distances table if successful
  if (( STATUS != 0 )) || [[ -z "${t_value:-}" ]]; then
    echo "ERROR: distANGSD failed or t not parsed for ${A##*/} vs ${B##*/} (line ${line})." >&2
    echo "---- distANGSD stdout/stderr ----"
    printf '%s\n' "$dist_out" | sed 's/^/    /'
    echo "---------------------------------"
    # (Optional) Record NA line in distances; leave commented unless you want placeholders.
    # { flock 200; printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "${A##*/}" "${B##*/}" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" "nuc" "NA" "" >> "$DIST_TABLE"; } 200>"$DIST_LOCK"
  else
    {
      flock 200
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "${A##*/}" "${B##*/}" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" "nuc" \
        "$t_value" "${p_inv_value:-}" >> "$DIST_TABLE"
    } 200>"$DIST_LOCK"
    echo "SUCCESSFULLY COMPLETED: ${OUTPFX}  (t=${t_value}${p_inv_value:+, p_inv=${p_inv_value}})"
  fi
done
