
#!/bin/bash
#SBATCH --job-name=Three_Loci_Phylogeny
#SBATCH --cpus-per-task=16       # Number of threads
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=Three_loci_tree.out
#SBATCH --error=logs/Three_loci_tree_%j.err
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282

# ---------------------------------------------------------------------------------
# COX1 LOCUS:
                    # -------------------------------------------------------------
                    # EXCLUDE WASPS BELOW A THRESHOLD COVERAGE OF THE COX1 LOCUS:
                    
                    # Navigate to the folder containing the outputs from the A2 script:
                    cd /user/work/pk14885/Samtools_Mito_results
                    
                    # Copy all of the wasps' COX1 genes into one folder called "COX1_Outputs":
                    mkdir -p COX1_Outputs
                    find /user/work/pk14885/Samtools_Mito_results -type f -name "*_COX1_output.fasta" -exec cp {} COX1_Outputs/ \;
                    
                    # -------------------------------------------------------------
                    # COMBINE ALL THE RESULTING SEQUENCES INTO A SINGLE FASTA FILE, TOGETHER WITH GENBANK COMPARISONS:
                    
                    # Navigate to the folder of results above the threshold coverage:
                                cd /user/work/pk14885/Samtools_Mito_results/COX1_Outputs
                    
                    # Concatenate all the wasps' COX1 sequences into a single FASTA file:
                                cat *.fasta > COI_all_samples.fasta
                  
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

# ---------------------------------------------------------------------------------
# cytb LOCUS:
                    # -------------------------------------------------------------
                    # EXCLUDE WASPS BELOW A THRESHOLD COVERAGE OF THE COX1 LOCUS:
                    
                    # Navigate to the folder containing the outputs from the A2 script:
                    cd /user/work/pk14885/Samtools_Mito_results
                    
                    # Copy all of the wasps' cytb genes into one folder called "cytb_Outputs":
                    mkdir -p cytb_Outputs
                    find /user/work/pk14885/Samtools_Mito_results -type f -name "*_cytb_output.fasta" -exec cp {} cytb_Outputs/ \;
                    
                    # -------------------------------------------------------------
                    # COMBINE ALL THE RESULTING SEQUENCES INTO A SINGLE FASTA FILE, TOGETHER WITH GENBANK COMPARISONS:
                    
                    # Navigate to the folder of results above the threshold coverage:
                                cd /user/work/pk14885/Samtools_Mito_results/cytb_Outputs
                    
                    # Concatenate all the wasps' cytb sequences into a single FASTA file:
                                cat *.fasta > cytb_all_samples.fasta
                      
                    # The wasps should all still have their individual wasp IDs as the headers in the file.
                    
                    # -------------------------------------------------------------
                    # ALIGNMENT USING MAFFT:
                    
                    # Load the MAFFT module on BluePebble:
                    module load mafft/7.505-gnbu
                    
                    # Use MAFFT to run alignment:
                    mafft --auto --thread 16 cytb_all_samples.fasta > cytb_aligned.fasta
                    
                    # -------------------------------------------------------------
                    # TRIM REGIONS THAT HAVE POOR ALIGNMENTS:
                    
                    # Load the TrimAL module on BluePebble:
                    module load apps/trimal/1.5
                    
                    # Use TrimAL to trim the output from MAFFT:
                    trimal -in cytb_aligned.fasta -out cytb_trimmed.fasta -automated1

# ---------------------------------------------------------------------------------
# ND5 LOCUS:
                    # -------------------------------------------------------------
                    # EXCLUDE WASPS BELOW A THRESHOLD COVERAGE OF THE COX1 LOCUS:
                    
                    # Navigate to the folder containing the outputs from the A2 script:
                    cd /user/work/pk14885/Samtools_Mito_results
                    
                    # Copy all of the wasps' ND5 genes into one folder called "ND5_Outputs":
                    mkdir -p ND5_Outputs
                    find /user/work/pk14885/Samtools_Mito_results -type f -name "*_ND5_output.fasta" -exec cp {} ND5_Outputs/ \;
                    
                    # -------------------------------------------------------------
                    # COMBINE ALL THE RESULTING SEQUENCES INTO A SINGLE FASTA FILE, TOGETHER WITH GENBANK COMPARISONS:
                    
                    # Navigate to the folder of results above the threshold coverage:
                                cd /user/work/pk14885/Samtools_Mito_results/ND5_Outputs
                    
                    # Concatenate all the wasps' ND5 sequences into a single FASTA file:
                                cat *.fasta > ND5_all_samples.fasta
                      
                    # The wasps should all still have their individual wasp IDs as the headers in the file.
                    
                    # -------------------------------------------------------------
                    # ALIGNMENT USING MAFFT:
                    
                    # Load the MAFFT module on BluePebble:
                    module load mafft/7.505-gnbu
                    
                    # Use MAFFT to run alignment:
                    mafft --auto --thread 16 ND5_all_samples.fasta > ND5_aligned.fasta
                    
                    # -------------------------------------------------------------
                    # TRIM REGIONS THAT HAVE POOR ALIGNMENTS:
                    
                    # Load the TrimAL module on BluePebble:
                    module load apps/trimal/1.5
                    
                    # Use TrimAL to trim the output from MAFFT:
                    trimal -in ND5_aligned.fasta -out ND5_trimmed.fasta -automated1

# ---------------------------------------------------------------------------------
# CONCATENATE THE THREE GENES:

# Navigate back to the main folder:
          cd /user/work/pk14885/Samtools_Mito_results/ND5_Outputs

# Use seqkit to concatenate the genes:
              module load seqkit/2.8.2-qs27
              seqkit concat /user/work/pk14885/Samtools_Mito_results/COX1_Outputs/COX1_trimmed.fasta /user/work/pk14885/Samtools_Mito_results/cytb_Outputs/cytb_trimmed.fasta /user/work/pk14885/Samtools_Mito_results/ND5_Outputs/ND5_trimmed.fasta > three_genes_concatenated.fasta

# The lengths of each gene in the alignment are given by:
      len_COX1=$(grep -v ">" COX1_aligned.fasta | tr -d '\n' | wc -c)
      len_cytb=$(grep -v ">" cytb_aligned.fasta | tr -d '\n' | wc -c)
      len_ND5=$(grep -v ">" ND5_aligned.fasta | tr -d '\n' | wc -c)

# Accordingly, the three genes occupy these positions in the 'three_genes_concatenated.fasta' file: 
      start_cytb=$((len_COX1 + 1))
      end_cytb=$((len_COX1 + len_cytb))
      start_ND5=$((end_cytb + 1))
      end_ND5=$((end_cytb + len_ND5))

# Generate a 'partitions' file, which will allow IQ-TREE to apply different evolutionary models to the three different loci:
      cat <<EOL > partitions.txt
      DNA, COX1 = 1-${len_COX1}
      DNA, cytb = ${start_cytb}-${end_cytb}
      DNA, ND5  = ${start_ND5}-${end_ND5}
      EOL

# -------------------------------------------------------------
# USE IQ-TREE TO MAKE MAXIMUM LIKELIHOOD COX1 TREE:

# Load the IQ-TREE module on BluePebble:
module load apps/iqtree/2.4.0

# Use IQ-TREE to generate the phylogeny:
iqtree2 -s three_genes_concatenated.fasta -p partitions.txt -m MFP+MERGE -bb 2000 -alrt 2000 -nt AUTO
# Here, we use the 'ultrafast' bootstrap mode with 2,000 bootstrap replicates.
# The syntax '-alrt 2000' runs the SH-aLRT test with 2,000 replicates.
# '-m MFP' sets IQ-TREE to use ModelFinderPlus. You can see IQ-TREE's chosen
# model using the .phy.iqtree file.
