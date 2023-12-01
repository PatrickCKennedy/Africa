#!/bin/bash

#SBATCH --job-name=Transposable_elements
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=150G
#SBATCH --time=1-00:00:00
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# This script uses EDTA to build a TE library for Belonogaster juncea on BluePebble, using the
# B. juncea reference genome.

# ---------------------------------------------------------------------
# RUN EDTA ON BLUEPEBBLE USING A SINGULARITY SHELL:

cd /user/work/pk14885/Running_EDTA
module load apps/singularity/1.1.3
singularity shell -B/user/work/pk14885/Running_EDTA:/mnt /user/work/pk14885/EDTA.sif <<EOF
EDTA.pl --genome /mnt/B_junceaGenome.FINAL.fasta --species others --sensitive 1 --threads 42 
EOF

# ---------------------------------------------------------------------






