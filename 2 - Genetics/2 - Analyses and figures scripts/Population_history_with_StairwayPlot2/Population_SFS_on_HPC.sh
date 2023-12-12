#!/bin/bash
#SBATCH --job-name=Soa_SFS
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH --mem=100G
#SBATCH --time=0-12:00:00
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out

# --------- SITE FREQUENCY SPECTRUM FOR THIS SPECIFIC POPULATION -----------

# This script uses non-relatives. Before running it, therefore, you must have already run the quick script 'Screening_out_relatives.sh' for this population.

# --------------------------------------------------------------------------

# First, set the working directory to the folder of everyone's BAM files:
	cd /user/work/pk14885/Wasps/Completed_alignments/Cameroon/Soa
 
# --------------------------------------------------------------------------
# KEEP A RECORD OF WHICH POPULATION WE ARE FOCUSING ON:

# Print the following information, so that it is recorded in the SLURM output:
echo
echo "This is the script 'Population_SFS_on_HPC.sh'."
echo "It calculates the folded site frequency spectrum for this population, and should then run the 'stairway_plot' programme to generate the population size history of this population (currently working on that)."
echo
echo "Population:"
this_FOLDER_NAME=$(basename "$PWD")
echo ${this_FOLDER_NAME}
echo
echo "Path to population files:"
pwd
echo
echo "Start time:"
now=$(date)
echo $now
echo

# Before running this script, you should have narrowed it down to non-relatives. Print the wasps involved here:
echo "These are the target wasps:"
    cat ANGSD_results/nonrelatives.bam.filelist.txt
echo
 
# Record the number of bam files:
    file_count=$(wc -l ANGSD_results/nonrelatives.bam.filelist.txt | awk '{ print $1 }')

# --------------------------------------------------------------------------
# GENERATE SFS USING ANGSD:

# Load ANGSD on BluePebble:
module load apps/angsd/0.941

 # Provide the reference genome:
    REF="/user/work/pk14885/3_Patrick_Indexed_ref_using_BWA/B_junceaGenome.FINAL.fasta"
    
# P: We do not have the ancestral state of the population. This means that we cannot obtain an 'unfolded' SFS. We must instead find the 'folded' SFS: "This is done by supplying the -anc with the reference genome and applying -fold 1 to realSFS" (http://www.popgen.dk/angsd/index.php/SFS_Estimation).

# Following the ANGSD guide (http://www.popgen.dk/angsd/index.php/SFS_Estimation), but with -GL 1 rather than 2 (to match the first ANGSD run):

    # Generate the .saf file:
    angsd -bam ANGSD_results/nonrelatives.bam.filelist.txt \
    -doSaf 1 \
    -out ANGSD_results/smallFolded \
    -anc $REF \
    -GL 1 \
    -nThreads 6
    # (I think this angsd command should be run as this separate command (i.e., not part of the one at the top of the file), because: "Generally speaking you shouldn't use any filter that will distort the distribution of allele frequencies or remove monomorphic sites (minMAF and SNP_pval, I'm looking at you). This will hugely distort the SFS." (https://github.com/ANGSD/angsd/issues/259))
    
    # Go back to the ANGSD_results folder (which is where the 'smallFolded' output is):
    cd ANGSD_results

# Now that you have generated the smallFolded file, you can download it from the HPC cluster and run the 'realSFS' function on the local computer (see the next script).



