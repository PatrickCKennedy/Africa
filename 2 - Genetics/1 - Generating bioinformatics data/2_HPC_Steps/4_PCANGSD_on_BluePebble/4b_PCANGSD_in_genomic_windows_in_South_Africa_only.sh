#!/bin/bash
#SBATCH --job-name=Ca_WindowsPCANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=500M
#SBATCH --time=0-2:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# ---- RUNNING PCANGSD IN GENOMIC WINDOWS (ACROSS ALL POPULATIONS) TO FIND POTENTIAL GENOMIC REGIONS OF STRUCTURAL VARIANTS -----

# WHAT THIS SCRIPT DOES:

# The PCA plot from the PCANGSD analysis in '1_PCANGSD_across_all_populations_BluePebble.sh' 
# (once plotted in R using the 'Analysing PCANGSD results in R.R' R script) produces surprising clusters, 
# including individuals from within the same sites as the main Cameroon and South African clusters. Following 
# Merot et al. (2021), in this script we investigate the possibility that these reflect structural 
# variants (e.g., chromosome inversions/supergenes/etc).
# We use the pipeline published by Mérot et al. (2021), https://doi.org/10.1093/molbev/msab143
# Mérot et al.'s (2021) scripts are available at: https://github.com/clairemerot/angsd_pipeline
# We are specifically following scripts 10A to 10D at https://github.com/clairemerot/angsd_pipeline/tree/master/01_scripts

# The Merot et al. (2021) pipeline involves a set of python scripts (in their folder 'utility_scripts', at https://github.com/clairemerot/angsd_pipeline/tree/master/01_scripts/utility_scripts). 
# These are needed for the analysis below. We therefore first start by downloading Merot et al.'s 'utility_scripts' folder to BluePebble (this only needs to be run once - already run):
        ##cd /user/work/pk14885
        ##git clone https://github.com/clairemerot/angsd_pipeline.git
# Therefore, Merot et al.'s (2021) pipeline scripts are in the folder 'angsd_pipeline' on the working directory of HPC.

# ------------------------------------------------------------------------------------------------------
# SETTING UP THE INPUT INFORMATION:
# (adapted from https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/01_config.sh)

#"filter : will keep SNP above this allele frequency (over all individuals)" (https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/01_config.sh)
MIN_MAF=0.05 

#"filter : will keep positions with at least MIN_DEPTH reads for each individual, This is not necessaily for all individuals, we consider a PERCENT_IND (percentage of individuals over all individuals in step 03, and within each pop at step 07)
#advice: as min depth use a value that is a bit below what you expected. we use 1 for 1X of coverage but if you have 5X it may make sense to put the bar a bit higher to 2 or 3
#advice: as percentage, avoid going below 50% and also consider the whole number of individuals. (it may makes sense to use 50% with 100 ind/pop, but you may want 90% with 9 ind/pop" (https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/01_config.sh)
PERCENT_IND=0.5
MIN_DEPTH=1

#"advice: we usually set it at 2-4 times the expected coverage to remove repeated regions" (https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/01_config.sh)
MAX_DEPTH_FACTOR=20

window_size=1000 # for small window along a chromosome for instance
# "adjust memory accordingly - small window = few memory - big window more memory (1G for 1000 snp - 50G for a chromosome)" (https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/01_config.sh)

# ------------------------------------------------------------------------------------------------------
# SPLITTING UP THE BEAGLE FILE INTO NON-OVERLAPPING WINDOWS:
# (adapted from https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/10A_cov_by_window.sh)

# Make sure we are in the right directory:
cd /user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_SouthAfrica_ONLY

mkdir 10_pca_by_window/
mkdir "10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR
mkdir "10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size
mkdir "10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/beagle_by_window"
mkdir "10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/cov_by_window"

# Next, we will use the 'beagle_sliding_window_bis.py' script in the pipeline published by Merot et al. (2021).
# This splits the Beagle file into windows.
# However, Merot et al.'s script assumes that the reference contigs have a name in the format 'Chr_1'. In our
# reference genome, the contigs are named 'HiC_scaffold_1', which means there is an extra underscore. You can
# see this if you go to the Beagle file and use:   zcat my_Angsd_file.beagle.gz | head | cut -f 1-3
# To enable using the Merot et al. pipeline, we need to remove the first underscore, so that it is 'HiCscaffold' rather
# than 'HiC_scaffold'. We do that here:
        # First, make a copy of the whole-genomes Beagle file (so that we still have the untouched original in case an error arises):
                cp SouthAfrica_ONLY.my_Angsd_file.beagle.gz SouthAfrica_ONLY.my_Angsd_file.beagle_tempcopy.gz
        # Second, remove the file 'renamed.beagle.gz' if it exists from a previous run:
                rm renamed.SouthAfrica_ONLY.beagle.gz
        # Third, make an identical beagle file to 'my_Angsd_file.beagle_tempcopy.gz' where the only change is that 'HiC_scaffold' has been replaced with 'HiCscaffold' in the first column, and call it 'renamed.beagle.gz':
                zcat SouthAfrica_ONLY.my_Angsd_file.beagle_tempcopy.gz | cat | awk '{sub("HiC_scaffold","HiCscaffold");print}' | gzip > renamed.SouthAfrica_ONLY.beagle.gz
        # Now remove the tempcopy Beagle file:
                rm SouthAfrica_ONLY.my_Angsd_file.beagle_tempcopy.gz
        # For the rest of this script, we therefore now use the file 'renamed.SouthAfrica_ONLY.beagle.gz' as the global Beagle file. The untouched original ('SouthAfrica_ONLY.my_Angsd_file.beagle.gz') is still available if needed.

# "if your reference contigs names are "Chr_1" use this line" (https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/10A_cov_by_window.sh):
python /user/work/pk14885/angsd_pipeline/01_scripts/utility_scripts/beagle_sliding_window_bis.py /user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_SouthAfrica_ONLY/renamed.SouthAfrica_ONLY.beagle.gz $window_size 10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/beagle_by_window/

# "Run PCANGSD on each window":
ls -1 10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/beagle_by_window/ | 
    sort -u | 
    while read i
    do
        echo "GL for $i"
INPUT=10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/beagle_by_window/$i

echo "analyse covariance matrix on all individuals"

              # This part of the script in Merot et al.'s file (https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/10A_cov_by_window.sh) calls ANGSD through python2, because they use the former version of ANGSD. Here, we replace that line with the call directly to ANGSD on BluePebble:
              # Load PCANGSD on BluePebble:
                    module add lang/python/anaconda/3.8.8-2021.05-2.5
                    source activate pcangsd
              # Run PCANGSD to generate covariance matrix ready for making the PCA (and tree) in R:
              		pcangsd -b $INPUT -t 4 -o 10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/cov_by_window/$i

done

# ------------------------------------------------------------------------------------------------------
# SPLITTING UP THE BEAGLE FILE INTO NON-OVERLAPPING WINDOWS:
# (adapted from https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/10B_pca_lostruct.sh)

# Following Merot et al. (2021), we now use the 'lostruct' (local PCA structure) method of Li & Ralph (2019) [https://academic.oup.com/genetics/article/211/1/289/5931130].
# More information on 'lostruct' is here: https://github.com/petrelharp/local_pca?tab=readme-ov-file

# Get the number of wasps in the WaspNameList. This is the number of individuals included in the analysis:
N_IND=$(wc -l < /user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_SouthAfrica_ONLY/SouthAfrica_ONLY.WaspNameList)

# Set the number of PCs to consider when comparing windows:
N_PC=2 #nb of PC to consider when comparing windows

# "nb of MDS dimension in the output":
N_MDS=50

echo "Run local pca on covariance matrix made by window with window size = $window_size"

# Make a directory to store the analyses for each window:
mkdir "10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/$window_size/analyse_by_window"

# Make a text file to store the results:
ls 10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/cov_by_window/ > 10_pca_by_window/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR"/"$window_size"/analyse_by_window/list_window.txt

# In the script '1_PCANGSD_across_all_populations.sh', we created the PCA covariance matrix ('output.for.pca.in.R.pcangsd') on the whole
# genomes (i.e., a global PCA). In Merot et al.'s (2021) pipeline R script below, the local-window PCAs are plotted against the global PCA. In
# the Merot et al. pipeline, the global PCA was produced in their script 4 (https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/04_pca.sh),
# where it was called:   all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR".cov    
# and placed in a folder called:    04_pca/
# To enable our global PCA to run easily with their Rscript below (which points to this folder), our script '1_PCANGSD_across_all_populations.sh'
# made a copy of 'output.for.pca.in.R.pcangsd' and saved it as 04_pca/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR".cov, which we can now use here directly.

# Run Merot et al.'s (2021) R script from their pipeline:
##module load lang/r/4.0.1
##Rscript /user/work/pk14885/angsd_pipeline/01_scripts/Rscripts/local_pca_mds_all_chr_maxdepth_speedy_version.R "$MIN_MAF" "$PERCENT_IND" "$window_size" "$MAX_DEPTH_FACTOR" "$N_IND" "$N_PC" "$N_MDS"

# That R script uses the R package 'lostruct': "If you use this method, please cite Li & Ralph 2019" (https://github.com/petrelharp/local_pca?tab=readme-ov-file)
