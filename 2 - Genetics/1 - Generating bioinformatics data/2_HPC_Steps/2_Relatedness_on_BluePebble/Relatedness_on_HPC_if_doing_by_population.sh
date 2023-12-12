#!/bin/bash
#SBATCH --job-name=Petiolata_Pop_Relatedness
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=100G
#SBATCH --time=0-12:00:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out

# -------------------- RELATEDNESS ----------------------------

# WHAT THIS SCRIPT DOES:

# This HPC script uses ANGSD and ngsRelate to find the pairwise relatednesses between each individual in the chosen population.

# Choose the population here (e.g., 'Mbouda' or 'AfricanLaboratory'):
cd /user/work/pk14885/Wasps/Completed_alignments/SouthAfrica/PetiolataLouwsFarm

# -------------------------------------------------------------
# KEEP A RECORD OF WHICH POPULATION WE ARE FOCUSING ON:

# Print the following information, so that it is recorded in the SLURM output:
echo
echo "This is the script 'Relatedness_on_HPC_if_doing_by_population.sh'."
echo "It calculates relatedness between all wasps within the chosen population of interest. A different (but very similar) script is available if running on the whole country of interest."
echo
echo "Population:"
this_FOLDER_NAME=$(basename "$PWD")
echo $this_FOLDER_NAME
echo
echo "Path to population files:"
pwd
echo
echo "Start time:"
now=$(date)
echo $now
echo

# -------------------------------------------------------------
# PREPARE THE FILES FOR ANGSD:

# Generate a text file containing a list of all the bam files in the folder:
	ls *.bam > bam.filelist
 
# We can look inside that list using:
echo "These are the target wasps:"
	cat bam.filelist
echo
 
# Record the number of bam files:
    file_count=$(ls *.bam --file-type | grep -v '/$' | wc -l)

# We will use this below, when we set -minInd in the angsd function to discard sites if fewer than half the individuals have data for it:
    my_minInd=$(($file_count/2))

# Make a folder for this wasp called 'ANGSD_results':
	mkdir ANGSD_results
 
# Provide the reference genome:
REF="/user/work/pk14885/3_Patrick_Indexed_ref_using_BWA/B_junceaGenome.FINAL.fasta"

# -------------------------------------------------------------
# A SINGLE FUNCTION FOR QUALITY-FILTERING AND OBTAINING GENOTYPE LIKELIHOODS

# Load the ANGSD module on BluePebble:
    module load apps/angsd/0.941

# Run the 'angsd' command:
	angsd -bam bam.filelist \
	-ref $REF  \
	-out ./ANGSD_results/my_Angsd_file \
	-uniqueOnly 1 \
	-remove_bads 1 \
	-only_proper_pairs 1 \
	-trim 0 \
	-C 50 \
	-baq 1 \
	-minQ 20 \
	-minInd $my_minInd \
	-doCounts 1 \
	-GL 1 \
	-doGlf 3 \
	-doPost 1 \
	-doMaf 1 \
	-minmaf 0.05 \
	-doMajorMinor 1 \
	-snp_pval 1e-6 \
	-nThreads 8
    
  # REMOVED:     -uniqueOnly 1 \ and -doPost changed from 2 to 1.
 
  # NOTE: For running ngsRELATE on the output, you need to generate the right file type for output. That's why it is set to -doGlf 3 above. However, for PCANGSD on the output, you need the output in a different format (-doGlf 2) [Beagle]. The second run (for generating PCANGSD inputs) takes place in the PCANGSD_on_HPC.sh file, not here.

# See here for a description of the filter options: https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial2_genotype_snp_calling/markdowns/snp_calling.md

# Here, we use the SAMtools option for calculating genotype likelihoods (-GL 1). For an explanation of the options, see here: http://www.popgen.dk/angsd/index.php/Genotype_Likelihoods

# -------------------------------------------------------------
# RELATEDNESS USING ngsRelate
# Following the guide at https://github.com/ANGSD/NgsRelate
# ngsRelate takes its input from the files produced in the ANGSD function in the previous section.

# If running on laptop:
	#NGSRELATE="/Users/pk14885/ngsRelate/ngsRelate"
# If running on BluePebble:
    module load apps/ngsrelate/2.0.0

# Set the current directory to the folder containing the outputs from the angsd function in the previous section:
   
# "Extract the frequency column from the allele frequency file and remove the header (to make it in the format NgsRelate needs)" (https://github.com/ANGSD/NgsRelate). That site uses this command, but with zcat rather than gzcat. zcat wouldn't work, but it works when you change it to gzcat (https://kiwix.ounapuu.ee/serverfault.com_en_all_2019-02/A/question/570024.html): 
	zcat ANGSD_results/my_Angsd_file.mafs.gz | cut -f6 |sed 1d >freq

# Move the 'freq' file to the ANGSD_results folder:
    mv freq ANGSD_results

# Note: The line above is supposed to extract the allele frequency (presumably the population allele frequency) column and put it in a file of its own. The version on the website has 'cut -f5', but when I did this the next step doesn't work. So I opened up the .mafs.gz file and it turns out our frequency info (with the header 'knownEM') is actually in column 6, not column 5. This seems to be because there is a column containing the reference genome allele (btw, how come there is only one allele, rather than two, for the reference? Anyway). So I have tweaked the command to 'cut -f6', and that seems to solve the problem: the next command now works.

# We can now run ngsRelate:
    ngsRelate -g ANGSD_results/my_Angsd_file.glf.gz -n $file_count -f ANGSD_results/freq -O ANGSD_results/newres -z bam.filelist

 # The 'newres' file is the relatedness output, which you can open in Excel. You can download it from BluePebble by running this command on the laptop: scp pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/Cameroon/Mbouda/ANGSD_results newres
 

 
