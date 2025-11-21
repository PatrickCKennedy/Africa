#!/bin/bash
#SBATCH --job-name=COX1_Phylogeny
#SBATCH --cpus-per-task=16       # Number of threads
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=COI_Phylogeny.out
#SBATCH --error=logs/COI_tree_%j.err
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282

# -------------------------------------------------------------
# EXCLUDE WASPS BELOW A THRESHOLD COVERAGE OF THE COX1 LOCUS:

# Navigate to the folder containing the outputs from the A2 script:
cd /user/work/pk14885/Samtools_Mito_results

# Copy all of the wasps' COX1 genes into one folder called "COX1_Outputs":
mkdir -p COX1_Outputs
find /user/work/pk14885/Samtools_Mito_results -type f -name "*_COX1_output.fasta" -exec cp {} COX1_Outputs/ \;

# To find the average coverage across the COX1 region across all the samples use the 'coverage_summary.txt' that we
# generated in the previous script (A2):
    awk '{sum+=$NF; sumsq+=$NF*$NF; n++} END {mean=sum/n; sd=sqrt(sumsq/n - mean^2); print "Mean:", mean, "SD:", sd}' /user/work/pk14885/Samtools_Mito_coverage_summary.txt

# To focus on high-quality data, we will exclude from the phylogeny all wasps that have an average depth of coverage across the COX1 region of less than 20X, using the 'Samtools_Mito_coverage_summary.txt' file.

# Set the threshold depth of coverage of interest:
            my_THRESHOLD_COVERAGE=20

# Copy those individuals into a new folder called COX1_Outputs_Above_${my_THRESHOLD_COVERAGE}X:
            cd /user/work/pk14885/Samtools_Mito_results/COX1_Outputs
            mkdir /user/work/pk14885/Samtools_Mito_results/COX1_Outputs_Above_${my_THRESHOLD_COVERAGE}X
            awk -v t="$my_THRESHOLD_COVERAGE" '$NF >= t {print $1}' /user/work/pk14885/Samtools_Mito_coverage_summary.txt | while read prefix; do
                cp *"${prefix}"* /user/work/pk14885/Samtools_Mito_results/COX1_Outputs_Above_${my_THRESHOLD_COVERAGE}X/
            done

# Count how many individuals meet this threshold:
            awk -v t="$my_THRESHOLD_COVERAGE" '$NF >= t {count++} END {print count}' /user/work/pk14885/Samtools_Mito_coverage_summary.txt

# Find the average coverage among wasps retained after excluding all wasps below the threshold:
            awk -v threshold="$my_THRESHOLD_COVERAGE" -F'Average coverage:' '{if ($2 >= threshold) print $0}' /user/work/pk14885/Samtools_Mito_coverage_summary.txt > /user/work/pk14885/Samtools_Mito_coverage_filtered.txt
            awk '{sum+=$NF; sumsq+=$NF*$NF; n++} END {mean=sum/n; sd=sqrt(sumsq/n - mean^2); print "Mean:", mean, "SD:", sd}' /user/work/pk14885/Samtools_Mito_coverage_filtered.txt

# -------------------------------------------------------------
# COMBINE ALL THE RESULTING SEQUENCES INTO A SINGLE FASTA FILE, TOGETHER WITH GENBANK COMPARISONS:

# Navigate to the folder of results above the threshold coverage:
            cd /user/work/pk14885/Samtools_Mito_results/COX1_Outputs_Above_${my_THRESHOLD_COVERAGE}X

# Concatenate all the wasps' COX1 sequences into a single FASTA file:
            cat *.fasta > concatenated.fasta

# Concatenate it with published Belonogaster sequences from GenBank to provide comparisons:
            cat concatenated.fasta /user/work/pk14885/1_Other_Belonogaster_COI_sequences_previously_on_Genbank_to_provide_context.fasta > concatenated_plus_Belono_Genbanks.fasta

# Concatenate this with the Ropalidia marginata COX1 sequence from GenBank:
            cat concatenated_plus_Belono_Genbanks.fasta /user/work/pk14885/2_Ropalidia_marginata_COX1_Genbank.fasta > COI_all_samples.fasta
             
# The wasps should all still have their individual wasp IDs as the headers in the file.

# -------------------------------------------------------------
# ALIGNMENT USING MAFFT:

# Load the MAFFT module on BluePebble:
module load mafft/7.505-gnbu

# Use MAFFT to run alignment:
mafft --auto --thread 16 COI_all_samples.fasta > COI_aligned.fasta

# -------------------------------------------------------------
# TRIM REGIONS THAT HAVE POOR ALIGNMENTS:

# Load the TrimAL module on BluePebble:
module load apps/trimal/1.5

# Use TrimAL to trim the output from MAFFT:
trimal -in COI_aligned.fasta -out COI_trimmed.fasta -automated1

# -------------------------------------------------------------
# USE IQ-TREE TO MAKE MAXIMUM LIKELIHOOD COX1 TREE:

# Load the IQ-TREE module on BluePebble:
module load apps/iqtree/2.4.0

# Use IQ-TREE to generate the phylogeny:
iqtree2 -s COI_trimmed.fasta -m MFP -bb 1000 -alrt 1000 -nt AUTO
# Here, we use the 'ultrafast' bootstrap mode with 1,000 bootstrap replicates.
# The syntax '-alrt 1000' runs the SH-aLRT test with 1,000 replicates.
# '-m MFP' sets IQ-TREE to use ModelFinderPlus. You can see IQ-TREE's chosen
# model using the .phy.iqtree file.
