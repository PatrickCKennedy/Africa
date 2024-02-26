#!/bin/bash
#SBATCH --job-name=SaCa_PCANGSD
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=25G
#SBATCH --time=1-12:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# ---- POPULATION GENOMICS VIEW OF ALL B. JUNCEA POPULATIONS -----

# WHAT THIS SCRIPT DOES:

# This script will work on BOTH POPULATIONS. It runs two main programmes: PCANGSD and NGSadmix. Before running them, it produces a beagle file for ALL B. JUNCEA using ANGSD, which serves as the input file for both PCANGSD and NGSadmix.

# WHY PCANGSD?
# PCANGSD generates the data for plotting a PCA in R. It can also be used for looking at selection and inbreeding (see below).

# WHY NGSadmix?
# NGSadmix generates the data for plotting an admixture plot in R.

# Set the working directory to the completed alignments:
cd /user/work/pk14885/Wasps/Completed_alignments

# -------------------------------------------------------------
# FOCUS JUST ON NON-RELATIVES WITHIN EACH POPULATION:

# This script is designed to be run on multiple populations. So the working directory should be either Cameroon or South Africa. Within the working directory, there should be a folder for each population (e.g., 'Somalomo'), and inside each folder should be the relevant bam (and bai) files.

# Before running this script, you must run the quick code in 'Screening_relatives_on_HPC.sh' manually in each of the populations of interest. Once this has been completed, there will be a file for each population in the country's folder (e.g., 'Somalomo.nonrelatives.bam.filelist.txt').

# If we use all nonrelatives, the PCANGSD run takes a very long time. We therefore select a random sample of up to 10 nonrelatives from each population:

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # SELECT (up to 20) RANDOM NONRELATIVES FROM EACH OF THE CAMEROON POPULATIONS:

        # Each list of nonrelatives from each Cameroonian population should already be in the Cameroon folder:
        cd /user/work/pk14885/Wasps/Completed_alignments/Cameroon
        forwardslash="/"
        myPWD=`pwd`

        # DOUALA:
        # Choose up to 20 random nonrelatives from Douala:
                shuf -n 20 Douala.nonrelatives.bam.filelist.txt > temp.file.Douala
        # Add each BAM file's full location before its line:
                awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Douala > up.to.20.random.nonrelatives.from.Douala
                rm temp.file.Douala

        # MAROUA (the same method as above, and for each population below):
        shuf -n 20 Maroua.nonrelatives.bam.filelist.txt > temp.file.Maroua
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Maroua > up.to.20.random.nonrelatives.from.Maroua
        rm temp.file.Maroua
        
        # MBOUDA:
        shuf -n 20 Mbouda.nonrelatives.bam.filelist.txt > temp.file.Mbouda
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Mbouda > up.to.20.random.nonrelatives.from.Mbouda
        rm temp.file.Mbouda
    
        # MESSA:
        shuf -n 20 Messa.nonrelatives.bam.filelist.txt > temp.file.Messa
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Messa > up.to.20.random.nonrelatives.from.Messa
        rm temp.file.Messa

        # SOA:
        shuf -n 20 Soa.nonrelatives.bam.filelist.txt > temp.file.Soa
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Soa > up.to.20.random.nonrelatives.from.Soa
        rm temp.file.Soa

        # SOMALOMO:
        shuf -n 20 Somalomo.nonrelatives.bam.filelist.txt > temp.file.Somalomo
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Somalomo > up.to.20.random.nonrelatives.from.Somalomo
        rm temp.file.Somalomo

        # YAOUNDE 1:
        shuf -n 20 Yaounde1.nonrelatives.bam.filelist.txt > temp.file.Yaounde1
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Yaounde1 > up.to.20.random.nonrelatives.from.Yaounde1
        rm temp.file.Yaounde1

        # Concatenate all the randomly-selected nonrelatives from Cameroon:
        cat up.to.20.random* >> Cameroonian.randomly.selected.nonrelatives.txt

        # Remove the 'up.to.20.random.nonreatives.from....' files, as we no longer need them:
        rm up.to.20.random*
  
        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # NOW SELECT (up to 10) RANDOM NONRELATIVES FROM EACH OF THE SOUTH AFRICAN POPULATIONS:

        # Each list of nonrelatives from each Cameroonian population should already be in the Cameroon folder:
        cd /user/work/pk14885/Wasps/Completed_alignments/SouthAfrica
        forwardslash="/"
        myPWD=`pwd`

        # AFRICAN LABORATORY:
        shuf -n 20 AfricanLaboratory.nonrelatives.bam.filelist.txt > temp.file.AfricanLaboratory
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.AfricanLaboratory > up.to.20.random.nonrelatives.from.AfricanLaboratory
        rm temp.file.AfricanLaboratory
  
        # COWSHED:
        shuf -n 20 Cowshed.nonrelatives.bam.filelist.txt > temp.file.Cowshed
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Cowshed > up.to.20.random.nonrelatives.from.Cowshed
        rm temp.file.Cowshed

        # LOVERS' ROCK:
        shuf -n 20 LoversRock.nonrelatives.bam.filelist.txt > temp.file.LoversRock
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.LoversRock > up.to.20.random.nonrelatives.from.LoversRock
        rm temp.file.LoversRock

        # PETER ROBERTS:
        shuf -n 20 PeterRobertsFarm.nonrelatives.bam.filelist.txt > temp.file.PeterRobertsFarm
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.PeterRobertsFarm > up.to.20.random.nonrelatives.from.PeterRobertsFarm
        rm temp.file.PeterRobertsFarm

        # PUMPHOUSE:
        shuf -n 20 Pumphouse.nonrelatives.bam.filelist.txt > temp.file.Pumphouse
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Pumphouse > up.to.20.random.nonrelatives.from.Pumphouse
        rm temp.file.Pumphouse

        # TRUDIE'S FARM:
        shuf -n 20 TrudiesFarm.nonrelatives.bam.filelist.txt > temp.file.TrudiesFarm
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.TrudiesFarm > up.to.20.random.nonrelatives.from.TrudiesFarm
        rm temp.file.TrudiesFarm

        # VUSUMUZI:
        shuf -n 20 Vusumuzi.nonrelatives.bam.filelist.txt > temp.file.Vusumuzi
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.Vusumuzi > up.to.20.random.nonrelatives.from.Vusumuzi
        rm temp.file.Vusumuzi

        # ZEBRA HOUSE:
        shuf -n 20 ZebraHouse.nonrelatives.bam.filelist.txt > temp.file.ZebraHouse
        awk -v prefix="$myPWD/" '{print prefix $0}' temp.file.ZebraHouse > up.to.20.random.nonrelatives.from.ZebraHouse
        rm temp.file.ZebraHouse

        # Concatenate all the randomly-selected nonrelatives from South Africa:
        cat up.to.20.random* >> SouthAfrica.randomly.selected.nonrelatives.txt

        # Remove the 'up.to.20.random.nonreatives.from....' files, as we no longer need them:
        rm up.to.20.random*

# -------------------------------------------------------------
# COMBINE THE LIST OF TARGET WASPS FROM CAMEROON AND SOUTH AFRICA:

# Move the South Africa list to the main 'Completed_alignments' folder:
        cd /user/work/pk14885/Wasps/Completed_alignments/SouthAfrica
        mv SouthAfrica.randomly.selected.nonrelatives.txt ../

# Move the Cameroonian list to the main 'Completed_alignments' folder:
        cd /user/work/pk14885/Wasps/Completed_alignments/Cameroon
        mv Cameroonian.randomly.selected.nonrelatives.txt ../

# Return to the 'Completed_alignments' folder:
	cd /user/work/pk14885/Wasps/Completed_alignments
 
# Remove these file if they exist from a previous run:
	rm all.temp.txt
 	rm Cameroon.AND.SouthAfrica.randomly.selected.nonrelatives.txt

# Combine the Cameroonian and South African lists:
        cat *.randomly.selected.nonrelatives.txt >> all.temp.txt

# Remove extraneous information (e.g., the numbers in the second column):
        awk '{print $1}' all.temp.txt > Cameroon.AND.SouthAfrica.randomly.selected.nonrelatives.txt

# Print all the wasps of interest to the slurm output file:
        echo
        echo "Wasps involved in this analysis:"
        cat Cameroon.AND.SouthAfrica.randomly.selected.nonrelatives.txt

# Record the sample size:
        echo
        echo "Total number of wasps in this analysis:"
        N_IND=$(cat Cameroon.AND.SouthAfrica.randomly.selected.nonrelatives.txt | wc -l)
        echo $N_IND
# We will use the 'N_IND' variable below, when we set -minInd in the angsd function to discard sites if fewer than a certain proportion of individuals 

# Generate a list of which population each sample is from:
          sed -e 's/Cameroon/ /g' Cameroon.AND.SouthAfrica.randomly.selected.nonrelatives.txt > temp1
          sed -e 's/SouthAfrica/ /g' temp1 > temp2
          awk '{print $2}' temp2 > temp3
	  sed -i -r 's/.{1}//' temp3
   	  cat temp3 | sed 's/\// /' temp3
      	  cat temp3 | sed 's/\// /' temp3 > temp4
	  rm PopulationList
	  awk '{print $1}' temp4 > PopulationList

# It is also helpful to have a text file that gives the wasp's name, rather than the full bam file name. Every bam file has "_CKDL" or "_EKDL" after the wasp name, followed by a code that came from Novogene. To list just the wasps' names, we can delete everything in the text that comes after "_CKDL" or "_EKDL":
	  awk '{print $2}' temp4 > temp5
	  sed 's/_CKDL.*//' temp5 > temp6
	  sed 's/_EKDL.*//' temp6 > WaspNameList
	  
# Remove all the temporary files:
	rm temp*
 
# For a summary table of how many samples are in each population (following http://www.popgen.dk/software/index.php/NgsAdmixTutorial#Plot_the_results_in_R):
    cut -f 1 -d " " PopulationList | sort | uniq -c
    
# Make a population label file (following http://www.popgen.dk/software/index.php/NgsAdmixTutorial#Plot_the_results_in_R). We will use this in the NGSadmix part of the script below:
    cut -f1 -d" " PopulationList > PopulationLabels

# Make a folder for the PCANGSD results:
	cd /user/work/pk14885/Wasps/Completed_alignments
	mkdir juncea_PCANGSD_results_for_both_countries_together

 # Move the wasp name list and population ID table to this folder:
 	cd /user/work/pk14885/Wasps/Completed_alignments
  	mv WaspNameList juncea_PCANGSD_results_for_both_countries_together/
   	mv PopulationLabels juncea_PCANGSD_results_for_both_countries_together/
    	rm PopulationList
 
 # Provide the reference genome:
    REF="/user/work/pk14885/3_Patrick_Indexed_ref_using_BWA/B_junceaGenome.FINAL.fasta"

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
MIN_IND_FLOAT=$(echo "($N_IND * $PERCENT_IND)"| bc -l)
MIN_IND=${MIN_IND_FLOAT%.*} 

#"advice: we usually set it at 2-4 times the expected coverage to remove repeated regions" (https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/01_config.sh)
MAX_DEPTH_FACTOR=20
MAX_DEPTH=$(echo "($N_IND * $MAX_DEPTH_FACTOR)" |bc -l)

# -------------------------------------------------------------
# A SINGLE FUNCTION FOR QUALITY-FILTERING AND OBTAINING GENOTYPE LIKELIHOODS:

# Load ANGSD on BluePebble:
module load apps/angsd

# Run ANGSD to generate the Beagle file (which is the input for PCANGSD and NGSadmix below). -doGlf 2 ensures that a beagle file is generated:
angsd -bam Cameroon.AND.SouthAfrica.randomly.selected.nonrelatives.txt \
    -ref $REF  \
    -out ./juncea_PCANGSD_results_for_both_countries_together/my_Angsd_file \
    -remove_bads 1 \
    -only_proper_pairs 1 \
    -minInd $MIN_IND \
    -minMaf $MIN_MAF \
    -setMaxDepth $MAX_DEPTH \
    -setMinDepthInd $MIN_DEPTH \
    -C 50 \
    -baq 1 \
    -minQ 20 \
    -minMapQ 20 \
    -GL 1 \
    -doGlf 2 \
    -doMaf 1 \
    -minmaf 0.05 \
    -doMajorMinor 1 \
    -snp_pval 1e-6 \
    -doCounts 1 \
    -nThreads 8

# Here, we have applied some filters. This is what the tutorial says:
# "These filters will retain only uniquely mapping reads, not tagged as bad, considering only proper pairs, without trimming, and adjusting for indel/mapping (as in samtools). -C 50 reduces the effect of reads with excessive mismatches, while -baq 1 computes base alignment quality as explained here (BAQ) used to rule out false SNPs close to INDELS. Also, you may want to remove reads with low mapping quality and sites with low quality or covered by few reads (low depth). Under these circumstances, the assignment of individual genotypes and SNPs is problematic, and can lead to errors. We may also want to remove sites where a fraction (half?) of the individuals have no data. This is achieved by the -minInd option." (https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial2_genotype_snp_calling/markdowns/snp_calling.md)

	# For minInd, I think we should set this value to half of the samples we have. So you would need to change this to 200, for instance, if looking at 400 individuals in total.

	# CHOOSING THE RIGHT OPTION FOR GENOTYPE LIKELIHOOD FUNCTION (THE GL COMMAND IN THE FUNCTION ABOVE).
	# These are the options:

			#-GL=0: 
			#    1: SAMtools
			#    2: GATK
			#    3: SOAPsnp
			#    4: SYK
			#    5: phys
			#    6: Super simple sample an allele type GL. (1.0,0.5,0.0)
			#    7: outgroup gls

		# For an explanation of the options, see here: http://www.popgen.dk/angsd/index.php/Genotype_Likelihoods

		# Note: "The GATK model refers to the first GATK paper, SAMtools is somehow more sophisticated (non-independence of errors), SOAPsnp requires a reference sequence for recalibration of quality scores, SYK is error-type specific. For most applications and data, GATK and SAMtools models should give similar results." (https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial2_genotype_snp_calling/markdowns/snp_calling.md)

# -------------------------------------------------------------
# PCANGSD:
# Before running PCANGSD, you need to generate the Beagle file using ANGSD (above). The following assumes that you have already completed that step.

# Activate PCANGSD:
		module add lang/python/anaconda/3.8.8-2021.05-2.5
		source activate pcangsd

# See all options:
		pcangsd -h

# -------------------------------------------------------------
# DIFFERENT POTENTIAL ANALYSES THAT CAN BE RUN WITH PCANGSD
# following https://github.com/therkildsen-lab/genomic-data-analysis/blob/master/scripts/run_pcangsd.sh
# -------------------------------------------------------------
# (1) PCA ANALYSIS WITH PCANGSD:

# Report current step:
echo
echo "P: Now about to generate a covariance matrix and neighbour joining tree for subsequent plotting in a PCA plot and tree in R:"
echo

# Make sure we are in the right directory:
		cd /user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_both_countries_together

# Run PCANGSD to generate covariance matrix (and tree data) ready for making the PCA (and tree) in R:
		pcangsd -b my_Angsd_file.beagle.gz -t 4 --tree --tree_samples WaspNameList -o output.for.pca.in.R.pcangsd

# You can now use the output file ('output.for.pca.in.R.pcangsd') to produce a PCA plot in R, following http://www.popgen.dk/software/index.php/PCAngsdTutorial#Plot_the_results_in_R:
# First, download the output (from outside BluePebble).

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# NOTE (OF INTEREST ONLY IF YOU INTEND TO LOOK AT LOCAL-WINDOW PCAs IN THE NEXT SCRIPT):
# The covariance matrix produced by our PCANGSD command above is called 'output.for.pca.in.R.pcangsd.cov'.
# In the following script ('2_PCANGSD_in_genomic_windows.sh'), we use part of a pipeline developed by Merot et al. (2021) 
# to look at PCAs on short windows of the genome. That script calls an R script created by Merot et al. (2021), which
# correlates those short-window PCA results with the global PCA result. In our case, the global PCA result
# is 'output.for.pca.in.R.pcangsd.cov'. The Merot et al. pipeline R script assumes that the global PCA result is
# found within a folder called '04_pca/' and that it has the following filename: 
# all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR".cov
# To enable easy input into that R script from the Merot pipeline in the next script, we therefore
# make a directory with the same name ('04_pca/'), and make a copy of our global PCA result into it with the
# name expected by the Merot pipeline, which contains the MinMaf, percent ind, and max depth factor details used. 
# The resulting file and folder is not used for the rest of this script, but
# is used in the following script ('2_PCANGSD_in_genomic_windows.sh'):
	mkdir 04_pca
 	cp output.for.pca.in.R.pcangsd.cov 04_pca/all_maf"$MIN_MAF"_pctind"$PERCENT_IND"_maxdepth"$MAX_DEPTH_FACTOR".cov

# -------------------------------------------------------------
# (2) ADMIXTURE ANALYSIS USING PCANGSD:
# Following https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial3_ld_popstructure/markdowns/pca_admixture.md#2-alternative-approach-covariance-matrix-estimation-with-pcangsd
# and: https://www.popgen.dk/software/index.php/PCAngsdTutorial#Demo_1:_Allele_Frequencies

# Report current step:
echo
echo "P: Now about to run admixture analysis using PCANGSD:"
echo

# Run PCANGSD to conduct admixture analysis (leaving K unspecified so that PCANGSD will automatically infer the most likely value):
	pcangsd -b my_Angsd_file.beagle.gz --admix -o PCANGSD_admixture_outputs --admix_alpha 50

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

# -------------------------------------------------------------
# (4 - OPTIONAL) ADMIXTURE ANALYSIS USING NGSADMIX:

# NGSADMIX provides a potentially higher-quality analysis than PCANGSD's in-built admixture programme above.

# Report current step:
##echo
##echo "P: Now about to run NGSadmix to generate an admixture plot."
##echo

# You can run NGSadmix as part of ANGSD. I have installed it independently on the cluster (following the commands at http://www.popgen.dk/software/index.php/NgsAdmix). Here is the path to where I have installed it on my BluePebble account:
##NGSADMIX="/user/work/pk14885/MySoftware/NGSadmix"

# This means that we can run NGSadmix just by typing $NGSADMIX. We will run it at several different K (cluster number) values:
##$NGSADMIX -likes my_Angsd_file.beagle.gz -K 4 -minMaf 0.05 -seed 1 -o NGSadmix_K_as_4.output -P 10
##$NGSADMIX -likes my_Angsd_file.beagle.gz -K 5 -minMaf 0.05 -seed 1 -o NGSadmix_K_as_5.output -P 10
##$NGSADMIX -likes my_Angsd_file.beagle.gz -K 6 -minMaf 0.05 -seed 1 -o NGSadmix_K_as_6.output -P 10
##$NGSADMIX -likes my_Angsd_file.beagle.gz -K 7 -minMaf 0.05 -seed 1 -o NGSadmix_K_as_7.output -P 10

# For choosing the maximum likelihood K from the runs above in R, see: https://baylab.github.io/MarineGenomics/week-9-population-structure-using-ngsadmix.html

# We then need to follow the scripts online for plotting this in R. Go to 'Plot the results in R' at http://www.popgen.dk/software/index.php/NgsAdmixTutorial#Plot_the_results_in_R

# -------------------------------------------------------------
# SELECTION ANALYSIS (SUPPRESSED IN THIS SCRIPT, AS SHOULD BE RUN WITHIN A SINGLE COUNTRY):

# Selection analysis with PCANGSD (should only be run within a continuous population, i.e. just one country):
    ##pcangsd -b my_Angsd_file.beagle.gz --selection --minMaf 0.05 -t 64 -o output.selection.pcangsd --sites_save
    
