#!/bin/bash
#SBATCH --job-name=WindowsPCANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=500M
#SBATCH --time=0-01:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").



cd /user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_both_countries_together

module load lang/r/4.3.0-gcc
Rscript /user/work/pk14885/angsd_pipeline/01_scripts/Rscripts/local_pca_mds_all_chr_maxdepth_speedy_version.R "$MIN_MAF" "$PERCENT_IND" "$window_size" "$MAX_DEPTH_FACTOR" "$N_IND" "$N_PC" "$N_MDS"
