#!/bin/bash
#SBATCH --job-name=Chunk_of_distANGSD
#SBATCH --cpus-per-task=16
#SBATCH --mem=10G
#SBATCH --time=2:00:00
#SBATCH --output=logs/dA_chunk_%A_%a.out
#SBATCH --error=logs/dA_chunk_%A_%a.out
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282

# Note: if the array job is stopped or interrupted, we can restart it and it will resume at the right point (see section
# on this below). If we want to start from scratch, make sure that the output table from the previous run has been
# deleted, as this is used to check whether a pairwise comparison has been run already (skipping it if so).

set -euo pipefail

my_pair_list="${my_pair_list}"                            # TSV: A\tB\tOUTPFX
my_chunk_size_to_run="${my_chunk_size_to_run}"            # Number of pairs per array task
my_choice_of_phylogenetic_model_to_run="${my_choice_of_phylogenetic_model_to_run}"   # e.g. JC or GTR
chromosomes_to_include="${chromosomes_to_include:?Set via --export=...,chromosomes_to_include=...}"
my_path_to_distANGSD_executable_file="/user/work/pk14885/distAngsd/distAngsd"
ID_of_this_task_in_the_array_job="${SLURM_ARRAY_TASK_ID:?Need --array and SLURM_ARRAY_TASK_ID}"
starting_pair_in_this_chunk=$(((ID_of_this_task_in_the_array_job - 1) * my_chunk_size_to_run + 1))
last_pair_in_this_chunk=$(( starting_pair_in_this_chunk + my_chunk_size_to_run - 1 ))
total_number_of_pairs_across_the_whole_array_job=$(wc -l < "$my_pair_list")
module load samtools/1.19.2-737f
module load htslib/1.19.1-jbbb
mkdir -p logs results

# Threading for distANGSD (OpenMP)
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

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

# Bounds and info
if (( starting_pair_in_this_chunk > total_number_of_pairs_across_the_whole_array_job )); then
  echo "Nothing to do for task ${ID_of_this_task_in_the_array_job} (start ${starting_pair_in_this_chunk} > total ${total_number_of_pairs_across_the_whole_array_job})"
  exit 0
fi
(( last_pair_in_this_chunk > total_number_of_pairs_across_the_whole_array_job )) && last_pair_in_this_chunk=$total_number_of_pairs_across_the_whole_array_job

echo "Task ${ID_of_this_task_in_the_array_job}: lines ${starting_pair_in_this_chunk}-${last_pair_in_this_chunk} of ${total_number_of_pairs_across_the_whole_array_job} from $(basename "$my_pair_list")"
echo "Chunk size: ${my_chunk_size_to_run}; CPUs: ${SLURM_CPUS_PER_TASK:-1}; Mem: ${SLURM_MEM_PER_NODE:-${SLURM_MEM_PER_CPU:-?}}"

# --------------------------------------------------------------------------
# Scratch directory (seekable files, fast I/O) — never fall back to /tmp

SCRATCH="/user/work/pk14885"
mkdir -p "$SCRATCH/tmp"
export TMPDIR="$SCRATCH/tmp"           # for tools' temp
export PARALLEL_TMPDIR="$SCRATCH/tmp"  # explicit for GNU parallel

# Per-task working directory under scratch
directory_to_work_in="$(mktemp -d "$SCRATCH/dA.${ID_of_this_task_in_the_array_job}.XXXX")"
cleanup() { rm -rf "$directory_to_work_in"; }
trap cleanup EXIT

# Per-pair subdir for outputs and symlinked BAMs
scratch_bam_dir="${directory_to_work_in}/bams"
mkdir -p "$scratch_bam_dir"

# Resolve a BAM path (follows symlink) and verify it
resolve_bam() {
  local src="$1"
  local real
  real="$(readlink -f -- "$src" 2>/dev/null || echo "$src")"
  [[ -r "$real" ]] || { echo "ERROR: BAM not readable: $real" >&2; return 1; }
  if [[ ! -r "${real}.bai" && ! -r "${real%.bam}.bai" ]]; then
    echo "ERROR: No index (.bai) found for $real" >&2
    return 1
  fi
  echo "$real"
}

# Symlink BAM+BAI into pair scratch (tiny footprint; avoids copying)
symlink_bam() {
  local src="$1" d="$2"
  local real base
  real="$(resolve_bam "$src")" || return 1
  base="$(basename "$real")"
  ln -sf "$real" "$d/$base"
  if   [[ -r "${real}.bai" ]]; then
    ln -sf "${real}.bai" "$d/$base.bai"
  elif [[ -r "${real%.bam}.bai" ]]; then
    ln -sf "${real%.bam}.bai" "$d/${base%.bam}.bai"
  fi
  echo "$d/$base"
}

# Parse fixed chromosome list from environment (space/newline separated)
readarray -t fixed_chroms < <(printf '%s\n' "$chromosomes_to_include" | tr ' ' '\n' | sed '/^$/d')
if (( ${#fixed_chroms[@]} == 0 )); then
  echo "ERROR: chromosomes_to_include is empty." >&2
  exit 1
fi
echo "Chromosomes requested (from --export): ${fixed_chroms[*]}"

# Manually set the following, which sets up the masking for shared sites ('intersection'):
# Keep a site only if BOTH samples have depth >= minimum_depth_per_sample_in_BOTH_samples (and <= maximum_depth_per_sample_in_BOTH_samples if >0).
minimum_depth_per_sample_in_BOTH_samples="5"    # i.e., only keep this site in the analysis if both samples have at least this number of reads at the site.
maximum_depth_per_sample_in_BOTH_samples="20"   # i.e., cut out regions with unusually high depth, which might be repeats.

# Note: the use of the intersection approach dramatically increased the speed which this the analysis could be run, as it
# cuts out difficult-to-handle sites with very flat genome likelihoods.

# To avoid an error from very long commands, symlink the reference genome to a shorter name:
cd /user/work/pk14885
[ -e ref.fa ] || ln -s /user/work/pk14885/3_Patrick_Indexed_ref_using_BWA/B_junceaGenome.FINAL.fasta ref.fa
REF="ref.fa"

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
                  
                    echo ">> $(date +'%F %T')  ${A##*/} vs ${B##*/}"
                  
                    # Ensure OUTPFX dir exists (final outputs go here)
                    outdir="$(dirname "$OUTPFX")"
                    mkdir -p "$outdir"

                    # To allow for the array job to be resumed if stopped without losing the outputs of the tasks that have completed, check whether this pair has
                    # already been run in a previous task (by seeing whether OUTPFX and a t value output appears anywhere in the DIST_TABLE output table), and if so move on to the next one instead:                                   
                                    t_prev="$(
                                      awk -v pfx="$OUTPFX" -F'\t' '
                                        $3==pfx { last=$6 }
                                        END { if (last!="") print last }
                                      ' "$DIST_TABLE"
                                    )"                                   
                                    if [[ "$t_prev" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                                      echo "SKIP: ${OUTPFX} already in DIST_TABLE (t=${t_prev})."
                                      continue
                                    fi

                    # Symlink BAMs to per-pair scratch (no copy); then quickcheck
                    A_bam="$(symlink_bam "$A" "$scratch_bam_dir")" || continue
                    B_bam="$(symlink_bam "$B" "$scratch_bam_dir")" || continue
                    samtools quickcheck -v "$A_bam" "$B_bam" || echo "WARN: samtools quickcheck reported issues" >&2
                  
                    # Intersect requested chromosomes with BAM header contigs (avoid mpileup errors)
                    mapfile -t bam_chroms < <(samtools view -H "$A_bam" \
                      | awk '$1=="@SQ"{for(i=1;i<=NF;i++){if($i~/^SN:/){sub(/^SN:/,"",$i); print $i}}}')
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
                  
                    # Per-pair scratch subdir and final combined mpileup filename (seekable)
                    pps="${directory_to_work_in}/$(basename "$OUTPFX")"
                    mkdir -p "$pps"
                    outbase="$(basename "$OUTPFX")"
                    mpileup_gz="${pps}/${outbase}.mpileup.txt.gz"   # <-- final filtered combined stream
                  
                    # Determine parallel jobs (do not exceed number of selected chromosomes)
                    jobs="${SLURM_CPUS_PER_TASK}"
                    n_chroms="${#filtered[@]}"
                    (( jobs > n_chroms )) && jobs="$n_chroms"
                  
                    echo "Using ${n_chroms} chromosomes: ${filtered[*]}"
                    echo "Intersection mask thresholds: minimum_depth_per_sample_in_BOTH_samples=${minimum_depth_per_sample_in_BOTH_samples} maximum_depth_per_sample_in_BOTH_samples=${maximum_depth_per_sample_in_BOTH_samples}"

                    # 1) Per-chromosome mpileup
                    echo "Starting per-chromosome mpileup."
                    printf "%s\n" "${filtered[@]}" \
                      | parallel -j "$jobs" --halt now,fail=1 \
                          --line-buffer --compress --tmpdir "$TMPDIR" \
                          "samtools mpileup -d 20 -B -q 30 -Q 30 \
                             -f '$REF' \
                             -r {} '$A_bam' '$B_bam' \
                           | bgzip -@ 1 -l 1 > '${pps}/{}.mpileup.txt.gz'"
                  
                    # 2) APPLY INTERSECTION MASK (shared callable sites per chr)
                    #    Keep only lines where BOTH samples have depth >= MIN_DP
                    #    (and <= MAX_DP if maximum_depth_per_sample_in_BOTH_samples>0).

                    echo "Applying intersection mask."
                    printf "%s\n" "${filtered[@]}" \
                      | parallel -j "$jobs" --halt now,fail=1 \
                          --line-buffer --tmpdir "$TMPDIR" \
                          "bgzip -cd '${pps}/{}.mpileup.txt.gz' \
                           | awk -v minDP='${minimum_depth_per_sample_in_BOTH_samples}' -v maxDP='${maximum_depth_per_sample_in_BOTH_samples}' '
                               BEGIN { useMax = (maxDP > 0) }
                               {
                                 # mpileup with 2 BAMs: fields -> chr pos ref dp1 bases1 quals1 dp2 bases2 quals2
                                 dp1 = (\$4+0); dp2 = (\$7+0);
                                 if (dp1 >= minDP && dp2 >= minDP && (!useMax || (dp1 <= maxDP && dp2 <= maxDP))) {
                                   print;
                                 }
                               }
                             ' \
                           | bgzip -@ 1 -l 1 > '${pps}/{}.mpileup.intersect.txt.gz'"
                  
                    # Count non-empty per-chromosome *filtered* outputs
                    echo "Counting non-empty filtered outputs per chromosome."
                    n_nonempty=$(find "$pps" -maxdepth 1 -name '*.mpileup.intersect.txt.gz' -size +0c | wc -l | awk '{print $1}')
                  
                    if (( n_nonempty == 0 )); then
                      echo "ERROR: No sites left after intersection filtering for ${A##*/} vs ${B##*/}; skipping pair." >&2
                      # Clean up raw per-chr files
                      rm -f "${pps}"/*.mpileup.txt.gz || true
                      rm -f "${pps}"/*.mpileup.intersect.txt.gz || true
                      continue
                    fi
                  
                    # 3) Concatenate per-chromosome *filtered* outputs into one file
                  
                    echo ">> Concatenating per-chromosome FILTERED mpileups -> ${mpileup_gz}"
                    if ! find "$pps" -maxdepth 1 -name '*.mpileup.intersect.txt.gz' -size +0c -print0 \
                          | sort -z \
                          | xargs -0 cat > "$mpileup_gz"; then
                      echo "ERROR: Failed to build combined filtered mpileup for ${A##*/} vs ${B##*/}; skipping pair." >&2
                      continue
                    fi
                  
                    if [[ ! -s "$mpileup_gz" ]]; then
                      echo "ERROR: Combined filtered mpileup is empty for ${A##*/} vs ${B##*/}; skipping pair." >&2
                      continue
                    fi
                  
                    # 4) Per-pair summary stats from the *filtered* combined mpileup stream
                    
                    pair_stats="$(bgzip -dc "$mpileup_gz" \
                      | awk 'BEGIN{n=0; s1=0; s2=0; max1=0; max2=0}
                             {n++; d1=$4+0; d2=$7+0; s1+=d1; s2+=d2; if(d1>max1)max1=d1; if(d2>max2)max2=d2}
                             END{ if(n>0){ printf "%d\t%.6f\t%.6f\t%d\t%d", n, s1/n, s2/n, max1, max2 } else { print "0\t0\t0\t0\t0" } }')"
                    total_sites=$(echo "$pair_stats" | cut -f1)
                    mean_depth_A=$(echo "$pair_stats" | cut -f2)
                    mean_depth_B=$(echo "$pair_stats" | cut -f3)
                    max_depth_A=$(echo "$pair_stats" | cut -f4)
                    max_depth_B=$(echo "$pair_stats" | cut -f5)
                  
                    # 5) Run distANGSD on the FILTERED set
                                 
                                    # --- Run distANGSD (2D inference: t + p_inv) ---
                                    echo ">> Running distANGSD: $my_path_to_distANGSD_executable_file -mpileup $mpileup_gz -method nuc -model $my_choice_of_phylogenetic_model_to_run -par 2.0431,0.0821,0.0000,0.0670,0.0000,0.2184,0.2606,0.3265,0.1946 -o $OUTPFX -is2Dinfer 1 -isex 0 -isthreading 1"
                                    
                                    set +e
                                    # Capture and sanitize stdout/stderr to avoid CR/ANSI artifacts that break parsing
                                    dist_out="$(
                                      stdbuf -oL -eL "$my_path_to_distANGSD_executable_file" \
                                        -mpileup "$mpileup_gz" \
                                        -method nuc \
                                        -model "$my_choice_of_phylogenetic_model_to_run" \
                                        -par 2.0431,0.0821,0.000001,0.0670,0.000001,0.2184,0.2606,0.3265,0.1946 \
                                        -o "/user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder/distangsd_results/${OUTPFX}.log.txt" \
                                        -is2Dinfer 1 \
                                        -isex 0 \
                                        -outbin 0 \
                                        -outuchar 0 \
                                        -isthreading 1 \
                                      2>&1 | sed -e 's/\r/\n/g' -e $'s/\033\\[[0-9;]*[A-Za-z]//g'
                                    )"
                                    STATUS=$?
                                    set -e
                                    
                                    # Note: if running with the JC model, rather than GTR, take out the 'par' line above.
                                    # The values we have used here are taken directly from Zhao et al. (2022) - see page 5.
                                    
                               

# --- Extract t and p_inv robustly (prefer -o log; fallback to sanitized stdout/err) ---

# Explicit logfile path (MUST match the -o argument used above)
LOGFILE="/user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder/distangsd_results/${OUTPFX}.log.txt"

echo "Creating a clean log."
if [[ -s "$LOGFILE" ]]; then
  clean_log="$(
    sed -e 's/\r/\n/g' -e $'s/\033\\[[0-9;]*[A-Za-z]//g' "$LOGFILE" \
    | tr -d '\000'
  )"
else
  clean_log=""
fi

# Sanitize dist_out (captured stdout/stderr) and strip NULs
echo "Sanitising output."
clean_out="$(
  printf '%s' "$dist_out" \
  | sed -e 's/\r/\n/g' -e $'s/\033\\[[0-9;]*[A-Za-z]//g' \
  | tr -d '\000'
)"

# Function: extract last numeric token on a matched line (handles int/float/scientific)
_extract_num='
  BEGIN { num = "^-?[0-9]+(\\.[0-9]+)?([eE][-+]?[0-9]+)?$" }
  { for (i = NF; i > 0; i--) if ($i ~ num) { print $i; exit } }
'

# ---- Patterns (portable) ----
# Lines that contain "Estimated t = ..." or "Estimated t: ..."
awk_pat_t='/[Ee]stimated[[:space:]]*t[[:space:]]*[:=]/'

# Lines that contain "p_inv = ..." or variants like pInv/p-inv/p inv, case-insensitive.
# Avoid GNU [[:<:]]; use start-of-line or non-word-char as a left boundary.
awk_pat_pinv='
  BEGIN { IGNORECASE=1 }
  /(^|[^[:alnum:]_])p([_-]|[[:space:]]*)inv[[:space:]]*[:=]/ { print; }
'

# ---- Parse t (prefer log, then fallback to sanitized stdout/err) ----
echo "Parsing t value."
t_value="$(
  printf '%s\n' "$clean_log" \
  | awk "$awk_pat_t" \
  | awk "$_extract_num"
)"
if [[ -z "$t_value" ]]; then
  t_value="$(
    printf '%s\n' "$clean_out" \
    | awk "$awk_pat_t" \
    | awk "$_extract_num"
  )"
fi

# ---- Parse p_inv (prefer log, then fallback to sanitized stdout/err) ----
echo "Parsing p_inv value."
p_inv_value="$(
  printf '%s\n' "$clean_log" \
  | awk "$awk_pat_pinv" \
  | awk "$_extract_num"
)"
if [[ -z "$p_inv_value" ]]; then
  p_inv_value="$(
    printf '%s\n' "$clean_out" \
    | awk "$awk_pat_pinv" \
    | awk "$_extract_num"
  )"
fi

# ---- Placeholders for summary when parsing fails ----
t_for_sum="${t_value:-NA}"
p_inv_for_sum="${p_inv_value:-NA}"

                                    # --- Append to summary table (now INCLUDING t and p_inv as the last two columns) ---
                                    echo "Appending t and p_inv to summary table."
                                    {
                                      flock 201
                                      printf "%s\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
                                        "$A" "$B" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" \
                                        "$n_chroms" "$n_nonempty" "$total_sites" \
                                        "$mean_depth_A" "$mean_depth_B" "$max_depth_A" "$max_depth_B" \
                                        "$t_for_sum" "$p_inv_for_sum" >> "$PAIR_SUM_TABLE"
                                    } 201>"$PAIR_SUM_LOCK"
                                    
                                    # --- Append to distances table or report failure (unchanged behavior) ---
                                    echo "Appending t and p_inv to outputs table."
                                    if (( STATUS != 0 )) || [[ -z "${t_value:-}" ]]; then
                                      echo "ERROR: distANGSD failed or t not parsed for ${A##*/} vs ${B##*/} (line ${line})." >&2
                                      echo "---- distANGSD stdout/stderr (sanitized) ----"
                                      printf '%s\n' "$clean_out" | sed 's/^/    /'
                                    else
                                      {
                                        flock 200
                                        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
                                          "${A##*/}" "${B##*/}" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" "nuc" \
                                          "$t_value" "${p_inv_value:-}" >> "$DIST_TABLE"
                                      } 200>"$DIST_LOCK"
                                      echo "SUCCESSFULLY COMPLETED: ${OUTPFX}  (t=${t_value}${p_inv_value:+, p_inv=${p_inv_value}})"
                                    fi
                                                      
                    # Clean up intermediates to save space
                    rm -f "${pps}"/*.mpileup.txt.gz || true
                    rm -f "${pps}"/*.mpileup.intersect.txt.gz || true
                    rm -f "$mpileup_gz" || true
done
