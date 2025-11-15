#!/bin/bash
#SBATCH --job-name=Samtools_Mitochondria_NEE_2025
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=1G
#SBATCH --time=0-00:15:00
# "d-hh:mm:ss"
#SBATCH --mail-type=end
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out
#SBATCH --array=1-67
# Update the array range to cover the required number of wasps to include in the sample (e.g., the number 
# of wasps in /user/work/pk14885/MitoZ_NEE_2025/Maroua)

# PK, latest update: 15th November 2025

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Before running this script, do the following:

# (1) Upload the chosen wasps to BluePebble. For each wasp, have a folder
# containing two files: the forward and reverse trimmed files (the '_val_1' and '_val_2' files).
# Upload that wasp's folder (named for the wasp) within /user/work/pk14885/MitoZ_NEE_2025/POPULATION_ID_HERE
# on BluePebble.

# (2) Manually enter the name of the folder of interest within MitoZ_NEE_2025 here:
this_CLIMATE_ZONE=$'South_Africa'
this_POPULATION_NAME=$'TrudiesFarm'

# (3) Before running the array job, generate a text file containing a list of all the target wasps
# (i.e., all wasps in the folder /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME), using:
##        cd /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME
##        ls -d * > Wasps_to_target_with_MitoZ.filelist

# (4) Make sure the array range is set to the right number of wasps in the header (e.g., #SBATCH --array=1-102 above).
# To find the right number of wasps, use:
##        wc -l Wasps_to_target_with_MitoZ.filelist

# ---------------------------------------------------------------------------------
# IDENTIFY THE SPECIFIC WASP TARGETTED FOR THIS INSTANCE OF THE ARRAY SCRIPT:

# Allocate a specific wasp to this particular entry of the array job:
        cd /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME
        this_wasp_to_sample=$(sed -n ${SLURM_ARRAY_TASK_ID}p Wasps_to_target_with_MitoZ.filelist)

# Print the focal wasp's name to the slurm output file:
        echo $this_wasp_to_sample
        echo $this_POPULATION_NAME

# Navigate to the focal wasp's folder (which should contain only its 'val_1' and 'val_2' files):
        cd /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample

# Find the names of the two trimmed 'val' .fq.gz files:
        this_wasp_val_1_FILE=$(ls *val_1*)
        this_wasp_val_2_FILE=$(ls *val_2*)

# ---------------------------------------------------------------------------------
# USE THE COX1 GENE FROM THE REFERENCE MITOCHONDRIAL GENOME:
# We have assembled the reference mitochondrial genome as part of a wider project elsewhere to
# provide the reference genome for Belonogaster juncea (Wyatt et al.). The mitochondrial genome
# from that reference is in the file /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta
# The start and end positions for the COX1 gene are detailed in the GenBank-syle file 'final_mitogenome.gb',
# and are 3417 to 4955.

# Load the modules on HPC:
module load bwa/0.7.17-hnox
module load samtools/1.19.2-737f
module load bcftools/1.19-openblas-5yp2
module load seqtk/1.4-rcyr

# We begin by indexing our reference mitogenome, using bwa index. We only need to run this once, which
# we have done, so it is now hashed out:
    ##bwa index /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta
    ##samtools faidx /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta

# Next, we map raw reads from the adaptor-trimmed files for each wasp from low-coverage whole genome
# sequencing to the reference mitogenome, using bwa mem:
    bwa mem -t 8 /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta $this_wasp_val_1_FILE $this_wasp_val_2_FILE | samtools view -Sb - > /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}.bam

# Next, sort and index the BAM file:
    samtools sort /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/$this_wasp_to_sample.bam -o /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_sorted.bam
    samtools index /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_sorted.bam

# Next, extract the COX1 gene from the reference mitogenome:
    COX1_START=3417
    COX1_END=4955
    HEADER_NAME=$(head -n 1 /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta | sed 's/>//')
    samtools faidx /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta $HEADER_NAME:${COX1_START}-${COX1_END} > /user/work/pk14885/UCL_Genome_MitoHiFi/samtools_reference_COX1.fasta

# Because the COX1 gene in the reference mitogenome is on the complementary strand (as noted in the .gb file for the reference mitogenome), we take the reverse complement using seqtk:
        seqtk seq -r /user/work/pk14885/UCL_Genome_MitoHiFi/samtools_reference_COX1.fasta > /user/work/pk14885/UCL_Genome_MitoHiFi/samtools_reference_COX1_reverse_complement.fasta

# Generate consensus sequence using bcftools:
bcftools mpileup -Ou -f /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta \
    /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_sorted.bam \
    | bcftools call -mv -Oz -o /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}.vcf.gz

# Index VCF:
bcftools index /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}.vcf.gz

# Create consensus FASTA from VCF:
cat /user/work/pk14885/UCL_Genome_MitoHiFi/final_mitogenome.fasta \
    | bcftools consensus /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}.vcf.gz \
    > /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_consensus.fasta

# Extract COX1 gene from consensus:
samtools faidx /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_consensus.fasta $HEADER_NAME:${COX1_START}-${COX1_END} \
    > /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_COX1_raw.fasta

# Reverse complement COX1 gene from consensus:
seqtk seq -r /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_COX1_raw.fasta \
    > /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_POPULATION_NAME}_${this_wasp_to_sample}_COX1_output.fasta

# Calculate depth of coverage over the COX1 gene:
samtools depth -a -r "${HEADER_NAME}:${COX1_START}-${COX1_END}" /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_wasp_to_sample}_sorted.bam \
    | awk -v sample="${this_wasp_to_sample}" '{sum+=$3} END {print sample, "Average coverage:", sum/NR}' \
    >> /user/work/pk14885/MitoZ_NEE_2025/coverage_summary.txt
    
# Replace the fasta header with the name of the wasp (and its population):
awk -v header="${this_POPULATION_NAME}_${this_wasp_to_sample}" 'NR==1{$0=">"header}1' \
    /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_POPULATION_NAME}_${this_wasp_to_sample}_COX1_output.fasta > tmp.fasta && mv tmp.fasta /user/work/pk14885/MitoZ_NEE_2025/$this_CLIMATE_ZONE/$this_POPULATION_NAME/$this_wasp_to_sample/${this_POPULATION_NAME}_${this_wasp_to_sample}_COX1_output.fasta

# ----------------------------------------------------------
# FINALLY, RUN THE FOLLOWING MANUALLY AFTER THE SCRIPT ABOVE HAS FINISHED FOR ALL WASPS IN THE POPULATION OF INTEREST:

# The key file from every wasp is the ${this_wasp_to_sample}_COX1_output.fasta file.
# Manually run the following on HPC to collate all these files from the different wasps:

# Manually enter the name of the folder of interest within MitoZ_NEE_2025 here, e.g.:
##         this_CLIMATE_ZONE=$'South_Africa'
##         this_POPULATION_NAME=$'Pumphouse'

# Collate all of these for the population of interest by manually running the following on HPC:
##        cd /user/work/pk14885/MitoZ_NEE_2025
##        mkdir -p "${this_POPULATION_NAME}_COX1_Results"
##        find "$this_CLIMATE_ZONE/$this_POPULATION_NAME" -type f -name "*_COX1_output.fasta" -exec mv {} "${this_POPULATION_NAME}_COX1_Results/" \;

# The folder (${this_POPULATION_NAME}_COX1_Results) is now ready to be downloaded to the local computer using scp. 
# On the local computer, run:
##         this_CLIMATE_ZONE=$'South_Africa'
##         this_POPULATION_NAME=$'Pumphouse'
##        scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/MitoZ_NEE_2025/${this_POPULATION_NAME}_COX1_Results /Volumes/Social_evolution_in_animals/COX1_genes_extracted_with_Samtools/${this_POPULATION_NAME}_COX1_Results

# The population of interest can now be deleted from the mitochondria folder on BluePebble (make sure it is safe on RDSF within adaptor-trimmed sequences).

