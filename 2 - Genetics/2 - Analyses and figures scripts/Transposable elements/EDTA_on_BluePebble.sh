#!/bin/bash

#SBATCH --job-name=Transposable_elements
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=42
#SBATCH --cpus-per-task=1
#SBATCH --mem=200G
#SBATCH --time=14-00:00:00
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# This script uses EDTA ('Extensive de novo TE annotator') to build a TE library for Belonogaster juncea on BluePebble, using the
# B. juncea reference genome.

# Citation for EDTA: Ou, S., Su, W., Liao, Y. et al. Benchmarking transposable element annotation methods for creation of a streamlined, comprehensive pipeline. Genome Biol 20, 275 (2019). https://doi.org/10.1186/s13059-019-1905-y

# ---------------------------------------------------------------------
# RUN EDTA ON BLUEPEBBLE USING A SINGULARITY SHELL:

cd /user/work/pk14885/Running_EDTA
module load apps/singularity/1.1.3
singularity shell -B/user/work/pk14885/Running_EDTA:/mnt /user/work/pk14885/EDTA.sif <<EOF
EDTA.pl --genome /mnt/B_junceaGenome.FINAL.fasta --species others --sensitive 0 --threads 42 
EOF

# ---------------------------------------------------------------------






