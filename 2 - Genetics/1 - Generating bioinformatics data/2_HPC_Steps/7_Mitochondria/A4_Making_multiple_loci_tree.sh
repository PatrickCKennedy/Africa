#!/bin/bash
#SBATCH --job-name=Multiple_Loci_Phylogeny
#SBATCH --cpus-per-task=16       # Number of threads
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=Multiple_loci_tree.out
#SBATCH --error=logs/Multiple_loci_tree_%j.err
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282

# Load the MAFFT module on BluePebble:
module load mafft/7.505-gnbu

# Load the TrimAL module on BluePebble:
module load apps/trimal/1.5

# ---------------------------------------------------------------------------------
# COX1 LOCUS:
                    # -------------------------------------------------------------
                    # EXCLUDE WASPS BELOW A THRESHOLD COVERAGE OF THE COX1 LOCUS:

                    # Navigate to the folder containing the outputs from the A2 script:
                    cd /user/work/pk14885/Samtools_Mito_results
                    
                    # Copy all of the wasps' COX1 genes into one folder called "COX1_Outputs":
                    mkdir -p COX1_Outputs
                    find /user/work/pk14885/Samtools_Mito_results -type f -name "*_COX1_output.fasta" -exec cp {} COX1_Outputs/ \;
                    
                    # To find the average coverage across the COX1 region across all the samples use the 'Samtools_Mito_coverage_summary.txt' that we
                    # generated in the previous script (A2):
                        awk '{sum+=$NF; sumsq+=$NF*$NF; n++} END {mean=sum/n; sd=sqrt(sumsq/n - mean^2); print "Mean:", mean, "SD:", sd}' /user/work/pk14885/Samtools_Mito_coverage_summary.txt
                    # Note that the average depth values in the coverage summary textfile only apply to COX1.
                    
                    # To focus on high-quality data, we will exclude from the phylogeny all wasps that have an average depth of coverage across the COX1 region of less than 20X, using the 'Samtools_Mito_coverage_summary.txt' file.
                    
                    # Set the threshold depth of coverage of interest:
                                my_THRESHOLD_COVERAGE=20
                    
                    # Count how many individuals meet this threshold:
                                awk -v t="$my_THRESHOLD_COVERAGE" '$NF >= t {count++} END {print count}' /user/work/pk14885/Samtools_Mito_coverage_summary.txt
                    
                    # Find the average COX1 depth of coverage among wasps retained after excluding all wasps below the threshold:
                                awk -v threshold="$my_THRESHOLD_COVERAGE" -F'Average coverage:' '{if ($2 >= threshold) print $0}' /user/work/pk14885/Samtools_Mito_coverage_summary.txt > /user/work/pk14885/Samtools_Mito_coverage_filtered.txt
                                awk '{sum+=$NF; sumsq+=$NF*$NF; n++} END {mean=sum/n; sd=sqrt(sumsq/n - mean^2); print "Mean:", mean, "SD:", sd}' /user/work/pk14885/Samtools_Mito_coverage_filtered.txt

                    # Copy those individuals into a new folder called COX1_Outputs_Above_${my_THRESHOLD_COVERAGE}X:
                                cd /user/work/pk14885/Samtools_Mito_results
                                mkdir COX1_Outputs_Above_${my_THRESHOLD_COVERAGE}X
                                cd /user/work/pk14885/Samtools_Mito_results/COX1_Outputs
                                awk -v t="$my_THRESHOLD_COVERAGE" '$NF >= t {print $1}' /user/work/pk14885/Samtools_Mito_coverage_filtered.txt | while read prefix; do
                                    cp *"_${prefix}_COX1_output.fasta"* /user/work/pk14885/Samtools_Mito_results/COX1_Outputs_Above_${my_THRESHOLD_COVERAGE}X/
                                done
                    
                    # -------------------------------------------------------------
                    # COMBINE ALL THE RESULTING SEQUENCES INTO A SINGLE FASTA FILE, TOGETHER WITH GENBANK COX1 COMPARISONS:
                    
                    # Navigate to the folder of results above the threshold coverage:
                                cd /user/work/pk14885/Samtools_Mito_results/COX1_Outputs_Above_${my_THRESHOLD_COVERAGE}X
                    
                    # Concatenate all the wasps' COX1 sequences into a single FASTA file:
                                cat *.fasta > COX1_all_samples.fasta
                  
                    # The wasps should all still have their individual wasp IDs as the headers in the file.
                    
                    # -------------------------------------------------------------
                    # ALIGNMENT USING MAFFT:
                    
                    # Use MAFFT to run alignment:
                    mafft --auto --thread 16 COX1_all_samples.fasta > COX1_aligned.fasta
                    
                    # -------------------------------------------------------------
                    # TRIM REGIONS THAT HAVE POOR ALIGNMENTS:
                    
                    # Use TrimAL to trim the output from MAFFT:
                    trimal -in COX1_aligned.fasta -out COX1_trimmed.fasta -automated1

# ---------------------------------------------------------------------------------
# NOW COMPLETE THE EXTRACTION AND ALIGNMENT OF THE OTHER SEVEN GENES OF INTEREST:

# Manually choose the threshold depth (evaluated over the COX1 locus) below which we will exclude this wasp entirely:
my_THRESHOLD_COVERAGE=20

# Base directory:
BASE_DIR="/user/work/pk14885/Samtools_Mito_results"

# my_genes_of_interest to process:
my_genes_of_interest=("cytb" "COX2" "ND2" "ND4" "ND5" "ATP6" "rrnL")

# Coverage summary file:
my_COX1_coverage_file="${BASE_DIR}/Samtools_Mito_coverage_summary.txt"

for gene in "${my_genes_of_interest[@]}"; do
    echo "Processing gene: $gene"

    # Create output folder for all sequences of this gene:
    cd ${BASE_DIR}
    mkdir -p "${gene}_Outputs"
    find "${BASE_DIR}" -type f -name "*_${gene}_output.fasta" -exec cp {} "${BASE_DIR}/${gene}_Outputs/" \;

    # Create folder for sequences above the depth threshold using average depth over the COX1 locus as the criterion:
    cd ${BASE_DIR}
    mkdir -p "${gene}_Outputs_for_wasps_with_COX1_above_${my_THRESHOLD_COVERAGE}X"

    # Copy over those sequences for this gene that correspond to wasps that pass the COX1 threshold:
    cd "${BASE_DIR}/${gene}_Outputs"
    awk -v t="$my_THRESHOLD_COVERAGE" '$NF >= t {print $1}' /user/work/pk14885/Samtools_Mito_coverage_filtered.txt | while read prefix; do
        cp *"${prefix}"* "${BASE_DIR}/${gene}_Outputs_for_wasps_with_COX1_above_${my_THRESHOLD_COVERAGE}X"
    done

    # Combine all the sequences of the this gene (across all the wasps) into one FASTA file:
    cd "${BASE_DIR}/${gene}_Outputs_for_wasps_with_COX1_above_${my_THRESHOLD_COVERAGE}X"
    cat *.fasta > "${gene}_all_samples.fasta"

    # Run alignment of this gene using MAFFT:
    mafft --auto --thread 16 "${gene}_all_samples.fasta" > "${gene}_aligned.fasta"

    # Trim the alignment using TrimAL:
    trimal -in "${gene}_aligned.fasta" -out "${gene}_trimmed.fasta" -automated1

    echo "Finished processing $gene"
done

# ---------------------------------------------------------------------------------
# MOVE THE EIGHT _trimmed.fasta FILES TO THE MAIN FOLDER:

# Move the COX1 results over:
      mv /user/work/pk14885/Samtools_Mito_results/COX1_Outputs_Above_20X/COX1_trimmed.fasta /user/work/pk14885/Samtools_Mito_results

# Move the other seven genes' results over:
for gene in cytb COX2 ND2 ND4 ND5 ATP6 rrnL; do
      mv /user/work/pk14885/Samtools_Mito_results/${gene}_Outputs_for_wasps_with_COX1_above_${my_THRESHOLD_COVERAGE}X/${gene}_trimmed.fasta /user/work/pk14885/Samtools_Mito_results
done

# ---------------------------------------------------------------------------------
# CONCATENATE THE EIGHT GENES:

# Navigate back to the main folder:
          cd /user/work/pk14885/Samtools_Mito_results/

# Use seqkit to concatenate the genes:
              module load seqkit/2.8.2-qs27
              seqkit concat /user/work/pk14885/Samtools_Mito_results/COX1_trimmed.fasta \
              /user/work/pk14885/Samtools_Mito_results/cytb_trimmed.fasta \
              /user/work/pk14885/Samtools_Mito_results/COX2_trimmed.fasta \
              /user/work/pk14885/Samtools_Mito_results/ND2_trimmed.fasta \
              /user/work/pk14885/Samtools_Mito_results/ND4_trimmed.fasta \
              /user/work/pk14885/Samtools_Mito_results/ND5_trimmed.fasta \
              /user/work/pk14885/Samtools_Mito_results/ATP6_trimmed.fasta \
              /user/work/pk14885/Samtools_Mito_results/rrnL_trimmed.fasta \
              > eight_genes_concatenated.fasta

# The lengths of each gene in the alignment are given by:
      len_COX1=$(awk '/^>/ {if(seq) exit; seq=1; next} seq {len+=length($0)} END {print len}' COX1_trimmed.fasta)
      len_cytb=$(awk '/^>/ {if(seq) exit; seq=1; next} seq {len+=length($0)} END {print len}' cytb_trimmed.fasta)
      len_COX2=$(awk '/^>/ {if(seq) exit; seq=1; next} seq {len+=length($0)} END {print len}' COX2_trimmed.fasta)
      len_ND2=$(awk '/^>/ {if(seq) exit; seq=1; next} seq {len+=length($0)} END {print len}' ND2_trimmed.fasta)
      len_ND4=$(awk '/^>/ {if(seq) exit; seq=1; next} seq {len+=length($0)} END {print len}' ND4_trimmed.fasta)
      len_ND5=$(awk '/^>/ {if(seq) exit; seq=1; next} seq {len+=length($0)} END {print len}' ND5_trimmed.fasta)
      len_ATP6=$(awk '/^>/ {if(seq) exit; seq=1; next} seq {len+=length($0)} END {print len}' ATP6_trimmed.fasta)
      len_rrnL=$(awk '/^>/ {if(seq) exit; seq=1; next} seq {len+=length($0)} END {print len}' rrnL_trimmed.fasta)

# Accordingly, the different genes occupy these positions in the 'eight_genes_concatenated.fasta' file: 
      start_cytb=$((len_COX1 + 1))
      end_cytb=$((len_COX1 + len_cytb))
      
      start_COX2=$((end_cytb + 1))
      end_COX2=$((end_cytb + len_COX2))
      
      start_ND2=$((end_COX2 + 1))
      end_ND2=$((end_COX2 + len_ND2))

      start_ND4=$((end_ND2 + 1))
      end_ND4=$((end_ND2 + len_ND4))

      start_ND5=$((end_ND4 + 1))
      end_ND5=$((end_ND4 + len_ND5))

      start_ATP6=$((end_ND5 + 1))
      end_ATP6=$((end_ND5 + len_ATP6))

      start_rrnL=$((end_ATP6 + 1))
      end_rrnL=$((end_ATP6 + len_rrnL))

# Generate a 'partitions' file, which will allow IQ-TREE to apply different evolutionary models to the eight different loci:
cat <<EOL > partitions.txt
DNA, COX1 = 1-${len_COX1}
DNA, cytb = ${start_cytb}-${end_cytb}
DNA, COX2  = ${start_COX2}-${end_COX2}
DNA, ND2  = ${start_ND2}-${end_ND2}
DNA, ND4  = ${start_ND4}-${end_ND4}
DNA, ND5  = ${start_ND5}-${end_ND5}
DNA, ATP6  = ${start_ATP6}-${end_ATP6}
DNA, rrnL  = ${start_rrnL}-${end_rrnL}
EOL

# -------------------------------------------------------------
# REMOVE FROM THE CONCATENATED ALIGNMENTS ANY WASP WITH <50% COVERAGE ACROSS THE 8 LOCI:

# First, identify which wasps have locus coverage of less than 50% of nucleotides (as the number of nucleotides
# for which we have a read divided by the total number of nucleotide spaces, which includes the gap characters marked '-' or 'n',
# which are excluded in the gsub with the term [^-N?]):
          seqkit fx2tab eight_genes_concatenated.fasta | \
          awk -v total_len=$(awk '/^>/{if(seq) exit; seq=1; next} seq {len+=length($0)} END {print len}' eight_genes_concatenated.fasta) \
          '{
              seq=$2;
              realbases=gsub(/[^ATGC]/,"",seq);  # Count only A,T,G,C (exclude -, N, ?)
              coverage=(realbases/total_len)*100;
              if (coverage >= 50) print $1
          }' > wasps_to_keep.txt

# We now cut these wasps out of the file:
        seqkit grep -f wasps_to_keep.txt eight_genes_concatenated.fasta > filtered_alignment.fasta

# -------------------------------------------------------------
# USE IQ-TREE TO MAKE MAXIMUM LIKELIHOOD COX1 TREE:

# Load the IQ-TREE module on BluePebble:
module load apps/iqtree/2.4.0

# Use IQ-TREE to generate the phylogeny:
iqtree2 -s filtered_alignment.fasta -p partitions.txt -m MFP+MERGE -bb 1000 -alrt 1000 -nt AUTO
# Here, we use the 'ultrafast' bootstrap mode with 1,000 bootstrap replicates.
# The syntax '-alrt 1000' runs the SH-aLRT test with 1,000 replicates.
# '-m MFP' sets IQ-TREE to use ModelFinderPlus. You can see IQ-TREE's chosen
# model using the .phy.iqtree file.
