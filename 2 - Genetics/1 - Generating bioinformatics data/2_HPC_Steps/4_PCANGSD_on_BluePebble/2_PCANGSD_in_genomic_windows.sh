#!/bin/bash
#SBATCH --job-name=WindowsPCANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=0-18:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# ---- RUNNING PCANGSD IN GENOMIC WINDOWS (ACROSS ALL POPULATIONS) TO FIND POTENTIAL GENOMIC REGIONS OF STRUCTURAL VARIANTS -----

# WHAT THIS SCRIPT DOES:

# The PCA plot from the PCANGSD analysis in '1_PCANGSD_across_all_populations_BluePebble.sh' 
# (once plotted in R using the 'Analysing PCANGSD results in R.R' R script) produces surprising clusters, 
# including individuals from within the same sites as the main Cameroon and South African clusters. Following 
# Mazet et al. (2021), in this script we investigate the possibility that these reflect structural 
# variants (e.g., chromosome inversions/supergenes/etc).
# We follow the pipeline in  Mérot et al. (2021), https://doi.org/10.1093/molbev/msab143
# Mérot et al.'s (2021) script pipeline is available at: https://github.com/clairemerot/angsd_pipeline

# We are specifically following scripts 10A to 10D at https://github.com/clairemerot/angsd_pipeline/tree/master/01_scripts

# The Mazet et al. (2021) pipeline involves a set of python scripts (in their folder 'utility_scripts', at https://github.com/clairemerot/angsd_pipeline/tree/master/01_scripts/utility_scripts). These are needed for the analysis below. 

# We therefore first start by downloading Mazet et al.'s 'utility_scripts' folder to BluePebble (this only needs to be run once - already run):
        ##cd /user/work/pk14885
        ##git clone https://github.com/clairemerot/angsd_pipeline.git
# Therefore, Mazet et al.'s (2021) scripts are now all in the folder 'angsd_pipeline' on the working directory of HPC.

# ------------------------------------------------------------------------------------------------------
# SETTING UP THE INPUT INFORMATION:
# (adapted fromhttps://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/01_config.sh)

#"filter : will keep SNP above this allele frequency (over all individuals)"
MIN_MAF=0.05 

#"filter : will keep positions with at least MIN_DEPTH reads for each individual, This is not necessaily for all individuals, we consider a PERCENT_IND (percentage of individuals over all individuals in step 03, and within each pop at step 07)
#advice: as min depth use a value that is a bit below what you expected. we use 1 for 1X of coverage but if you have 5X it may make sense to put the bar a bit higher to 2 or 3
#advice: as percentage, avoid going below 50% and also consider the whole number of individuals. (it may makes sense to use 50% with 100 ind/pop, but you may want 90% with 9 ind/pop"
PERCENT_IND=0.5
MIN_DEPTH=1

#"filter: will keep SNP with at least a coverage of this factor multiplied by the number of ind - across all ind. 
# advice: we usually set it at 2-4 times the expected coverage to remove repeated regions"
MAX_DEPTH_FACTOR=3

#"window size for sliding window FST & Thetas"
WINDOW=25000 

#"window step"
WINDOW_STEP=5000 

# ------------------------------------------------------------------------------------------------------
# SPLITTING UP THE BEAGLE FILE INTO NON-OVERLAPPING WINDOWS:
# (adapted from https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/10A_cov_by_window.sh)

# Make sure we are in the right directory:
cd /user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_both_countries_together

mkdir "10_pca_by_window/
mkdir "10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR
mkdir "10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size
mkdir "10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/beagle_by_window"
mkdir "10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/cov_by_window"

# "if your reference contigs names are "Chr_1" use this line"
python /user/work/pk14885/angsd_pipeline/01_scripts/utility_scripts/beagle_sliding_window_bis.py /user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_both_countries_together/my_Angsd_file.beagle.gz $window_size 10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/beagle_by_window/

# "Run PCANGSD on each window":
ls -1 10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/beagle_by_window/ | 
    sort -u | 
    while read i
    do
        echo "GL for $i"
INPUT=10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/beagle_by_window/$i

echo "analyse covariance matrix on all individuals"

              # This part of the script in Mazet et al.'s file (https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/10A_cov_by_window.sh) calls ANGSD through python2, because they use the former version of ANGSD. Here, we replace that line with the call directly to ANGSD on BluePebble:
              # Load PCANGSD on BluePebble:
                    module add lang/python/anaconda/3.8.8-2021.05-2.5
                    source activate pcangsd
              # Run PCANGSD to generate covariance matrix ready for making the PCA (and tree) in R:
              		pcangsd -b $INPUT -t 4 -o 10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/cov_by_window/$i

done





