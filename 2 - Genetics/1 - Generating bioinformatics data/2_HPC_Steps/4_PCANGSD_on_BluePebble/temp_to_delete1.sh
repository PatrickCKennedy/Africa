#!/bin/bash
#SBATCH --job-name=SaCa_PCANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=120G
#SBATCH --time=8-120:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

cd /user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_both_countries_together

# -------------------------------------------------------------
# (3) INBREEDING ANALYSIS USING PCANGSD:

# Report current step:
echo
echo "P: Now about run inbreeding analysis using PCANGSD:"
echo

# Inbreeding analysis with PCANGSD:
    pcangsd -b my_Angsd_file.beagle.gz --inbreedSamples --minMaf 0.05 -t 64 -o output.inbreeding_per_individual.pcangsd
    
# P: For analysing the inbreeding outputs, you can import the two resulting .npy files into R. There are two outputs from 
# the pcangsd function: one seems to be the per-site inbreeding coefficient, and the other seems to the the likelihood ratio 
#test ('lrt') output. 
# Here is my script for plotting them in R on the local computer: 
##library(RcppCNPy); LRT_results <- npyLoad("output.inbreeding.pcangsd.lrt.sites.npy"); inbreeding <- npyLoad("output.inbreeding.pcangsd.inbreed.sites.npy"); inbreeding <- as.data.frame(inbreeding); hist(inbreeding$inbreeding); LRT_results <- as.data.frame(LRT_results)
# That was for the old analysis, which was inbreeding by sites - have now changed it to by individual.
