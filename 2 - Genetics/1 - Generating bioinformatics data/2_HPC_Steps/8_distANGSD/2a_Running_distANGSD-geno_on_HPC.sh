#!/bin/bash
#SBATCH --job-name=Chunk_of_distANGSD
#SBATCH --cpus-per-task=16
#SBATCH --mem=20G
#SBATCH --time=2:00:00
#SBATCH --output=logs/dA_chunk_%A_%a.out
#SBATCH --error=logs/dA_chunk_%A_%a.out
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282

set -euo pipefail

echo "Setting up variables."
my_pair_list="${my_pair_list}"                            # TSV: A\tB\tOUTPFX
my_chunk_size_to_run="${my_chunk_size_to_run}"            # Number of pairs per array task
my_choice_of_phylogenetic_model_to_run="${my_choice_of_phylogenetic_model_to_run}"   # e.g. JC or GTR
chromosomes_to_include="${chromosomes_to_include:?Set via --export=...,chromosomes_to_include=...}"
my_path_to_distANGSD_executable_file="/user/work/pk14885/distAngsd/distAngsd"
ID_of_this_task_in_the_array_job="${SLURM_ARRAY_TASK_ID:?Need --array and SLURM_ARRAY_TASK_ID}"
starting_pair_in_this_chunk=$(((ID_of_this_task_in_the_array_job - 1) * my_chunk_size_to_run + 1))
last_pair_in_this_chunk=$(( starting_pair_in_this_chunk + my_chunk_size_to_run - 1 ))
total_number_of_pairs_across_the_whole_array_job=$(wc -l < "$my_pair_list")

module purge
##module load perl/5.38.2-7cykysg
##module load python/3.11.9-keqsz72
##module load htslib/1.19.1-jbbb

echo "Making a results folder."
mkdir -p logs results

echo "Setting up threading to allow later use of threads in distANGSD."
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

echo "Setting up TSV files (shared by all array tasks) and their locks."
DIST_TABLE="results/distances.all.tsv"
DIST_LOCK="${DIST_TABLE}.lock"
PAIR_SUM_TABLE="results/pair_summaries.all.tsv"
PAIR_SUM_LOCK="${PAIR_SUM_TABLE}.lock"

echo "Checking that the headers are entered into the TSV files."
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

echo "Starting main loop through pairwise wasp comparisons."
for (( line=starting_pair_in_this_chunk; line<=last_pair_in_this_chunk; line++ )); do
                                         
              echo ""
              echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
              echo ""
              echo "Identifying the next pairwise comparison to run (from the list of pairwise comparisons)."
              echo ""
              IFS=$'\t' read -r A B OUTPFX < <(sed -n "${line}p" "$my_pair_list")
              
              echo "Validating that the inputs are correct."
              if [[ -z "${A:-}" || -z "${B:-}" || -z "${OUTPFX:-}" ]]; then
                echo "WARN: Malformed line ${line}" >&2
                continue
              fi
              if [[ ! -f "$A" || ! -f "$B" ]]; then
                echo "WARN: Missing BAM(s) at line ${line}: $A or $B" >&2
                continue
              fi
              
              echo ">> $(date +'%F %T')  ${A##*/} vs ${B##*/}"
              
              # echo "Creating the output directory (OUTPFX) for this pairwise comparison."
              outdir="$(dirname "$OUTPFX")"
              mkdir -p "$outdir"
              
              echo ""
              echo "Symlinking the BAM files to the scratch directory for this pairwise comparison."
              A_bam="$(symlink_bam "$A" "$scratch_bam_dir")" || continue
              B_bam="$(symlink_bam "$B" "$scratch_bam_dir")" || continue
              
              echo "Loading samtools."
              module purge
              module load samtools
              # (Samtools is purged later to allow for bcftools, which has conflicting dependency versions on BluePebble.)
              
              echo "Running quickcheck with samtools."
              samtools quickcheck -v "$A_bam" "$B_bam" || echo "WARN: samtools quickcheck reported issues" >&2
              
              echo "Filtering the requested chromosome list to those that are in the BAM file."
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
              
              echo "Making a scratch directory for this pairwise comparison, and preparing the name of the output VCF file that will be created later."
                          pair_scratch="${directory_to_work_in}/$(basename "$OUTPFX")"
                          mkdir -p "$pair_scratch"
                          outbase="$(basename "$OUTPFX")"
                          vcf_gz="${pair_scratch}/${outbase}.vcf.gz"
                          
              echo "Setting up the parallel jobs (for the different chromosomes)."
                          jobs="${SLURM_CPUS_PER_TASK:-1}"
                          n_chroms="${#filtered[@]}"
                          (( jobs < 1 )) && jobs=1
                          (( jobs > n_chroms )) && jobs="$n_chroms"
                          
              echo "Using ${n_chroms} chromosomes: ${filtered[*]}"
              
              echo "Purging samtools and loading bcftools"
                          module purge
                          module load bcftools

              echo "Using a temporary directory."
              : "${TMPDIR:=/tmp}"

              echo "Setting up the criteria for intersection."
                             
# Intersection thresholds
minDP="${minimum_depth_per_sample_in_BOTH_samples}"   # e.g., 5
maxDP="${maximum_depth_per_sample_in_BOTH_samples}"   # e.g., 20 (0 to disable upper bound)

# Build a robust filter using MIN/MAX across samples
dp_filter="MIN(FMT/DP) >= ${minDP}"
if [[ "${maxDP}" =~ ^[1-9][0-9]*$ ]]; then
  dp_filter="${dp_filter} & MAX(FMT/DP) <= ${maxDP}"
fi


echo "Building pairwise BCFs for each chromosome (bcftools mpileup | bcftools filter | bcftools view (custom filters) | index)."

# Per-chromosome build: mpileup -> remove indels -> apply your custom filters -> write BCF -> index
printf "%s\n" "${filtered[@]}" \
 | parallel --delay 0.2 -j "$jobs" --halt now,fail=1 --line-buffer --compress --tmpdir "${TMPDIR}" \
     "bcftools mpileup -Ou \
         -f /user/work/pk14885/3_Patrick_Indexed_ref_using_BWA/B_junceaGenome.FINAL.fasta \
         -q 30 -Q 30 -I -d 200 -r {} \
         -a FORMAT/AD,FORMAT/DP \
         \"${A_bam}\" \"${B_bam}\" \
      | bcftools filter -Ou -e 'INFO/INDEL!=0' \
      | bcftools view -i \"${dp_filter}\" -Ob -o \"${pair_scratch}/{}.bcf\" \
      && bcftools index -f \"${pair_scratch}/{}.bcf\""

echo "Count up the non-empty per-chromosome outputs."
n_nonempty=$(find "$pair_scratch" -maxdepth 1 -name '*.bcf' -size +0c | wc -l | awk '{print $1}')

echo ">> Concatenating per-chromosome BCFs."
mapfile -d '' -t parts < <(find "$pair_scratch" -maxdepth 1 -name '*.bcf' -size +0c -print0 | sort -z)
if (( ${#parts[@]} == 0 )); then
  echo "ERROR: No non-empty per-chromosome BCFs found; skipping pair." >&2
  continue
fi

# Concatenate to BCF, then sort & index
bcf_concat="${pair_scratch}/${outbase}.concat.bcf"
if ! bcftools concat -Ob -o "$bcf_concat" "${parts[@]}"; then
  echo "ERROR: Failed to build combined BCF for ${A##*/} vs ${B##*/}; skipping pair." >&2
  continue
fi

bcf_sorted="${pair_scratch}/${outbase}.sorted.bcf"
echo ">> Sorting and indexing combined BCF (required for random access by distAngSD)."
if ! bcftools sort -Ob -o "$bcf_sorted" "$bcf_concat"; then
  echo "ERROR: bcftools sort failed for ${bcf_concat}" >&2
  continue
fi
if ! bcftools index -f "$bcf_sorted"; then
  echo "ERROR: bcftools index failed for ${bcf_sorted}" >&2
  continue
fi
my_sorted_bcf_file="$bcf_sorted"   

# --- Pair summary stats from the combined BCF ---
echo "Calculating summary statistics from the combined BCF: $my_sorted_bcf_file"

echo "(1) Ensuring that the file and index exist."
if [[ ! -s "$my_sorted_bcf_file" ]]; then
  echo "ERROR: Combined BCF is empty or missing: $my_sorted_bcf_file" >&2
  continue
fi
# Check for either TBI or CSI; BCF typically uses CSI
if [[ ! -r "${my_sorted_bcf_file}.tbi" && ! -r "${my_sorted_bcf_file%.gz}.csi" && ! -r "${my_sorted_bcf_file}.csi" ]]; then
  echo "WARN: Index missing for $my_sorted_bcf_file; creating it now."
  bcftools index -f "$my_sorted_bcf_file" || { echo "ERROR: Failed to index $my_sorted_bcf_file"; continue; }
fi

echo " (2) Counting records (headerless view)."
total_sites=$(bcftools view -H "$my_sorted_bcf_file" | wc -l | awk '{print $1}')
total_sites=${total_sites:-0}

echo "(3) Verifying sample count (expect exactly two samples)."
n_samples=$(bcftools query -l "$my_sorted_bcf_file" | wc -l | awk '{print $1}')
if (( n_samples != 2 )); then
  echo "ERROR: Expected exactly 2 samples in $my_sorted_bcf_file, found $n_samples" >&2
  continue
fi

echo "(4) Calculating the mean and max depth per sample."
if ! read -r mean_depth_A mean_depth_B max_depth_A max_depth_B < <(
  bcftools query -f '[%DP\t]\n' "$my_sorted_bcf_file" \
  | awk 'BEGIN{n=0;s1=0;s2=0;m1=0;m2=0}
         {
           d1 = ($1 ~ /^[0-9]+$/) ? $1+0 : 0
           d2 = ($2 ~ /^[0-9]+$/) ? $2+0 : 0
           n++; s1+=d1; s2+=d2; if(d1>m1)m1=d1; if(d2>m2)m2=d2
         }
         END{
           if(n>0){ printf "%.6f\t%.6f\t%d\t%d", s1/n, s2/n, m1, m2 }
           else   { print "0\t0\t0\t0" }
         }'
); then
  echo "ERROR: Failed to compute per-sample DP stats from $my_sorted_bcf_file" >&2
  mean_depth_A=0 mean_depth_B=0 max_depth_A=0 max_depth_B=0
fi

echo "Summary: total_sites=$total_sites  meanDP=($mean_depth_A, $mean_depth_B)  maxDP=($max_depth_A, $max_depth_B)"

echo ""
echo ">> Running distANGSD (geno): $my_path_to_distANGSD_executable_file -vcf $my_sorted_bcf_file -method geno -model JC -o $OUTPFX -is2Dinfer 0 -isex 0 -isthreading 1"
set +e
"$my_path_to_distANGSD_executable_file" \
  -vcf "$my_sorted_bcf_file" \
  -method geno \
  -model JC \
  -o "$OUTPFX" \
  -is2Dinfer 0 \
  -isex 0 \
  -isthreading 1 \
  2>&1 | tee "${OUTPFX}.run.log"
STATUS=${PIPESTATUS[0]}
set -e


                # --- Parse robustly from the run log ---
                echo "Obtaining the output values (t value, and p_inv if running GTR rather than JC model)."
                run_log="${OUTPFX}.run.log"
                t_value="$(
                  sed -nE 's/.*Estimated[[:space:]]*t[[:space:]]*[:=][[:space:]]*([+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?).*/\1/p' "$run_log" | head -n1
                )"
                p_inv_value="$(
                  sed -nE '
                    s/.*p[_[:space:]]*inv[[:space:]]*[:=][[:space:]]*([+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?).*/\1/p
                    s/.*Estimated[[:space:]]*p[[:space:]]*[:=][[:space:]]*([+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?).*/\1/p
                  ' "$run_log" | head -n1
                )"
                p_inv_value="${p_inv_value:-NA}"
                
                echo "Adding information to the summary table (total_sites, mean depths, max depths)."
                {
                  flock 201
                  printf "%s\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\n" \
                    "$A" "$B" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" \
                    "$n_chroms" "$n_nonempty" "$total_sites" \
                    "$mean_depth_A" "$mean_depth_B" "$max_depth_A" "$max_depth_B"
                } >> "$PAIR_SUM_TABLE" 201>"$PAIR_SUM_LOCK"
                
                echo "Adding the t value (and p_inv value if running GTR) to the summary output table."
                if (( STATUS != 0 )) || [[ -z "${t_value:-}" ]]; then
                  echo "ERROR: distANGSD failed or t not parsed for ${A##*/} vs ${B##*/} (line ${line})." >&2
                  echo "---- distANGSD run log ----"
                  sed 's/^/    /' "$run_log" | tail -n 100
                else
                  {
                    flock 200
                    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
                      "${A##*/}" "${B##*/}" "$OUTPFX" "$my_choice_of_phylogenetic_model_to_run" "geno" \
                      "$t_value" "$p_inv_value"
                  } >> "$DIST_TABLE" 200>"$DIST_LOCK"
                  echo "SUCCESSFULLY COMPLETED: ${OUTPFX}  (t=${t_value}, p_inv=${p_inv_value})"
                fi
                
                echo "Cleaning up intermediate files to save space."
                rm -f "${pair_scratch}/${outbase}.vcf.gz" || true

done
