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
# RUN distANGSD:

./distAngsd -mpileup /user/work/pk14885/Wasps/Completed_alignments/all_bams_symlink_folder \
            -out wasp_dist \
            -nThreads 64 \
            -GL 1 \
            -doCounts 1 \
            -doMajorMinor 1 \
            -doMaf 1 \
            -SNP_pval 1e-6





            
