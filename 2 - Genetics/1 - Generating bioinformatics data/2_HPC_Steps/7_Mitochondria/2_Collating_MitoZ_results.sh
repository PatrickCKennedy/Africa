#!/bin/bash
#SBATCH --job-name=Collating_MitoZ
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=500M
#SBATCH --partition=short
#SBATCH --time=0-00:10:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
# Update the array range to the required number of wasps to include in the sample (i.e., the number 
# of wasps in /user/work/pk14885/Input_wasps_for_Mitoz)

# ---------------------------------------------------------------------------------
# COLLATING MITOZ RESULTS FROM TARGET WASPS

# Enter today's date manually:
ADD_TODAYS_DATE_HERE="5_MARCH_2024"

# Make a directory to store all the results in (give it today's date):
mkdir 1_COLLATED_RESULTS_$ADD_TODAYS_DATE_HERE

# Move the outputs for each wasp to the relevant '1_COLLATED_RESULTS' folder:
        cd /user/work/pk14885/Input_wasps_for_Mitoz/
        cp -r */*.result /user/work/pk14885/Input_wasps_for_Mitoz/1_COLLATED_RESULTS_$ADD_TODAYS_DATE_HERE/

# ---------------------------------------------------------------------------------
# MAKE A SEPARATE FILE FOR EACH GENE, COLLATING ALL THE TARGET WASPS TOGETHER:
# following https://github.com/linzhi2013/MitoZ/wiki/The--mitoz-tools--group_seq_by_gene--command

# Make a text file that contains the sample name in the first column and the path to the fasta
# file in the second column:
        # Make sure there are no 'temp' files left over from a previous run:
                rm temp*
        # Make a list of all folders in this 1_COLLATED_RESULTS folder (each one is for a separate wasp):
                ls -d *result > temp1.txt
        # Remove the '.result' from each line, so that it is just the wasp's name:
                sed 's/.result//' temp1.txt > temp2.txt
        # Duplicate the column:
                awk '$2=$1' temp2.txt > temp3.txt
        # Use an 'awk' function to fill out the path to the fasta file in the second column:
                awk -v todays_date_here=$ADD_TODAYS_DATE_HERE -F' ' -vOFS='\t' '{ $2 = "/user/work/pk14885/Input_wasps_for_Mitoz/1_COLLATED_RESULTS_" todays_date_here "/" $2 ".result/" $2 "." $2 ".megahit.mitogenome.fa.result/" $2 "_" $2 ".megahit.mitogenome.fa_mitoscaf.fa.gbf.gene.fasta" }1' < temp3.txt > temp4.txt
                # Explanation of this 'awk' function (awk -F'\t' -vOFS='\t' '{ $9 = "test=" $9 ";" }1') from StackExchange: "-F'\t' tells it to use tab-separated fields. -vOFS='\t' tells it to use tabs in the output too. The actual body of it is the last argument: it's a little program that says for every line to change the value of $9 (the ninth field) to the concatenation of "test=", its original value, and ";". We leave all the other fields intact, The final 1 is to tell awk to print the new line out even though we did something to it." (https://unix.stackexchange.com/questions/148114/how-to-add-words-to-an-existing-column)
        # Put the resulting table in a file called 'gene_f_list':
                cat temp4.txt > gene_f_list
        # Remove all temporary files:
                rm temp*

# ---------------------------------------------------------------------------------
# USE THE 'group_seq_by_gene' FUNCTION IN MITOZ

# For convenience, we will use the MitoZ university-wide installation on BluePebble by Callum Wright:

# Start the correct Miniconda module:
      module add lang/python/miniconda/3.12.2.inc-perl-5.30.0

# Activate the environment installed by Callum Wright:
     source activate mitozEnv

# Check the installation:
     which circos 
# It should print:  /sw/lang/miniconda.3.12.2/envs/mitozEnv/bin/circos

# Run 'mitoz-tools' from inside the 'mitozEnz' environment:
mitoz-tools  group_seq_by_gene -r gene_f_list -d '_' -p MitoZ

# Move all the results (they all start with the prefix 'MitoZ', as that's what we set in the line above with the '-p' option).
# to a single folder:
mkdir Grouped_by_gene
mv MitoZ* Grouped_by_gene/


# ---------------------------------------------------------------------------------
# DOWNLOAD THE RESULTING FILES TO THE LOCAL COMPUTER, AND RUN MAFFT IN GENEIOUS:

# (1) Download the 'Grouped_by_gene' folder to the local computer (using 'scp').

# (2) Import to Geneious

# (3) Use MAFFT plugin in Geneious for multiple alignment

# (4) Make bootstrapped tree, and plot consensus










