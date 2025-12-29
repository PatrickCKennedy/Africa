#!/bin/bash
#SBATCH --job-name=distANGSD
#SBATCH --cpus-per-task=64       # Number of threads
#SBATCH --mem=200G
#SBATCH --time=24:00:00
#SBATCH --output=distANGSD.out
#SBATCH --error=logs/distANGSD_%j.err
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --array=1-453628   # For 953 wasps, there are (953-952)/2 pairwise comparisons to run.

# ------------------------------------------------------------------------------
# MAKING SYMLINK FOLDER:

# Before running this script as a job on BluePebble, we make sure all the BAM files (and their
# associated BAI files) are in the same symlink folder, using the following:
# First, make a symlink folder to point towards the BAM files:
      ##            mkdir -p /user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder
      ##            cd /user/work/pk14885/Wasps/Completed_alignments
      ##            
      ##            while IFS= read -r bam; do
      ##                [ -z "$bam" ] && continue
      ##                [ ! -f "$bam" ] && { echo "WARN: BAM not found: $bam" >&2; continue; }
      ##            
      ##                bam_base="$(basename "$bam")"
      ##                ln -s -f "$bam" "/user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder/$bam_base"
      ##            
      ##                # Attempt to locate index files
      ##                idx1="${bam}.bai"          # e.g., /path/sample.bam.bai
      ##                idx2="${bam%.*}.bai"       # e.g., /path/sample.bai
      ##            
      ##                if [ -f "$idx1" ]; then
      ##                    ln -s -f "$idx1" "/user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder/${bam_base}.bai"
      ##                elif [ -f "$idx2" ]; then
      ##                    ln -s -f "$idx2" "/user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder/${bam_base%.bam}.bai"
      ##                else
      ##                    echo "INFO: No .bai found for $bam" >&2
      ##                fi
      ##            done < my_bam_list_fullpaths.txt

# -----------------------------------------------------------------------------
# MAKE A LIST OF ALL THE PAIRS OF GENOMES THAT distANGSD WILL CONSIDER:
# As above, run this section once (manually) before submitting the array job.

BAMDIR="/user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder"
OUTDIR="${BAMDIR}/distangsd_results"
PAIR_LIST="${OUTDIR}/pairs.tsv"

mkdir -p "$OUTDIR"

# Collect BAMs (absolute paths) and sort for stable ordering
/user/work/pk14885/Wasps/Completed_alignments
mapfile -t BAMS < <(find -L "$BAMDIR" -maxdepth 1 -type f -name "*.bam" | sort)

cd /user/work/pk14885/Wasps/Completed_alignments
if (( ${#BAMS[@]} < 2 )); then
  echo "Need at least 2 BAMs; found ${#BAMS[@]} in $BAMDIR" >&2
  #exit 1
fi


: > "$PAIR_LIST"
total=${#BAMS[@]}
for ((i=0; i<total; i++)); do
  # Print progress every 100 iterations (or every iteration if you prefer)
  printf "Progress: %d of %d BAMs processed (%.2f%%)\n" "$i" "$total" "$(bc <<< "scale=2; $i/$total*100")"

  for ((j=i+1; j<total; j++)); do
    A="${BAMS[$i]}" ; B="${BAMS[$j]}"
    a_base="$(basename "${A%.bam}")"
    b_base="$(basename "${B%.bam}")"
    echo -e "${A}\t${B}\t${OUTDIR}/${a_base}_vs_${b_base}" >> "$PAIR_LIST"
  done
done

# ------------------------------------------------------------------------------
# RUN distANGSD:

./distAngsd -mpileup /user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder \
            -out wasp_dist \
            -nThreads 64 \
            -GL 1 \
            -doCounts 1 \
            -doMajorMinor 1 \
            -doMaf 1 \
            -SNP_pval 1e-6





            
