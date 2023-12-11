#!/bin/bash

#SBATCH --job-name=array_job
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=5
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G
#SBATCH --array=1-177
#SBATCH --time=2-00:00:00
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
# BISC020282 is the project code in ACRC ("Social evolution of animal altruism").

# -------------------------------------------------------------
# LOAD THE MODULES ON THE CLUSTER:

# If running on BluePebble:
module load apps/bwa/0.7.17
module load apps/samtools/1.16
module load apps/picard/2.27.5

# -------------------------------------------------------------
# READ IN THE SPREADSHEET LISTING THE WASPS AND THEIR READ FILES:
# The first column in 'myFilesTable.txt' should be the sample name. The second column should contain the val_1 file after running trim_galore. The third column should be the val_2 file. The columns should be separated by a space. Each row is a separate sample.
samplesheet="myFilesTable.txt"

name=`sed -n "${SLURM_ARRAY_TASK_ID}p" $samplesheet |  awk '{print $1}'`
r1=`sed -n "${SLURM_ARRAY_TASK_ID}p" $samplesheet |  awk '{print $2}'`
r2=`sed -n "${SLURM_ARRAY_TASK_ID}p" $samplesheet |  awk '{print $3}'`

# -------------------------------------------------------------
# Print sample information to the SLURM output file:
echo
echo "Sample name:"
echo $name
echo
echo "Read 1 file:"
echo $r1
echo
echo "Read 2 file:"
echo $r2
echo
# -------------------------------------------------------------
# BWA ALIGNMENT

# Set the working directory to the folder containing the uploaded wasps:
cd /user/work/pk14885/Wasps_Dec2023

bwa mem -t $SLURM_JOB_CPUS_PER_NODE /user/work/pk14885/3_Patrick_Indexed_ref_using_BWA/B_junceaGenome.FINAL.fasta ${r1} ${r2} > ${name}.output.sam

# -------------------------------------------------------------
# SAMTOOLS

# Now that the alignment has been completed by BWA, we can convert the resulting sam file into a bam file:
    
    #brew install samtools
    samtools view -f 2 -b ${name}.output.sam > ${name}.output.bam
#NOTE ON MONDAY 9TH JAN: I'VE BEEN HAVING PROBLEMS, AS THE PICARD MARKDUPLICATES FUNCTION BELOW SEEMS TO PRODUCE FILES THAT LEAD TO A SUBSEQUENT ERROR (ERROR:MATE_NOT_FOUND IN picard VALIDATESAMFILE). IT'S POSSIBLE THAT THIS IS DUE TO ORPHANED READS (SEPARATED FROM THEIR MATE IN THE PAIR). I THINK THAT WE CAN POSSIBLY GET RID OF THESE PROBLEM PAIRS AT THIS STAGE, BY ADD '-f 2'. I HAVE ADDED IT ABOVE. TAKE IT OUT AGAIN IF IT DOES NOT SOLVE THE PROBLEM.

# Remove the sam file, which we no longer need:
    rm ${name}.output.sam

# Sort the output:
    samtools sort -o ${name}.sorted.bam ${name}.output.bam
 
# -------------------------------------------------------------
# SPECIFY 'READ GROUP' INFO IN PICARD:

java -Xmx16g -jar /sw/apps/picard/picard.jar AddOrReplaceReadGroups I=${name}.sorted.bam O=${name}.hasreadgroups.bam RGID=Patrick RGLB=WaspLibraries RGPL=ILLUMINA RGPU=unit1 RGSM=${name}

# -------------------------------------------------------------
# DEAL WITH DUPLICATES IN PICARD

# The programme 'picard' allows us to mark and remove PCR duplicates. We therefore run this line:
    java -Xmx16g -jar /sw/apps/picard/picard.jar MarkDuplicates I=${name}.hasreadgroups.bam O=${name}.before.removal.of.overlaps.bam M=${name}.marked_dup_metrics.txt REMOVE_DUPLICATES=true
    
# Remove the output files that are no longer needed:
    rm ${name}.output.bam
    rm ${name}.sorted.bam
    rm ${name}.hasreadgroups.bam

# -------------------------------------------------------------
# LOAD BAMUTILS MODULE FROM BLUEPEBBLE:

module load apps/bamutil/1.0.15

# -------------------------------------------------------------
# CLIPPING OF OVERLAPPING READ PAIRS USING BAMUTIL, FOLLOWING https://github.com/nt246/physalia-lcwgs/blob/main/day_1/markdowns/data_processing.md#deduplicate-and-clip-overlapping-read-pairs

# Now run the bamutil programme to remove overlaps:
bam clipOverlap --in ${name}.before.removal.of.overlaps.bam --out ${name}.no.overlaps.bam --stats

# -------------------------------------------------------------
# ...AND NOW BACK TO SAMTOOLS

# Next, index the sorted and Picard'd bam file:
    samtools index ${name}.no.overlaps.bam

# This produces a .bai file.

# To obtain quality-control info, run this:
    samtools flagstat ${name}.no.overlaps.bam

# The % next to 'mapped' in the resulting output tells you how many reads mapped to the reference genome, apparently.

# -------------------------------------------------------------
# YOU CAN NOW VIEW THE ALIGNMENTS IN IGV OR GENEIOUS

# To view alignments in IGV: if the reference genome is not already unzipped, unzip it in the terminal using gzip -d DRAG-THE-fa.gz-FILE-HERE. Load unzipped reference genome to IGV using "Load genome from file". Load the wasp alignment using File->Load from file and selecting the .bam file in the folder. Leave the .bai file in the folder (it is used automatically in this process, apparently). Now you can zoom in on the genome.

# -------------------------------------------------------------
# ESTIMATE READ DEPTH IN YOUR BAM FILES

# Run this samtools function:

    samtools depth -aa ${name}.no.overlaps.bam | cut -f 3 | gzip > ${name}.no.overlaps.bam.depth.gz

# To read the resulting data, open up RStudio, and run the R script '1. Summarise read depths in a bam file'.

# -------------------------------------------------------------
# TO SAVE SPACE ON THE CLUSTER, NOW REMOVE THE RAW READ FILES FOR THIS WASP FROM BLUEPEBBLE (i.e. THE TRIMMED 'VAL' FILES):

###rm ${r1}
###rm ${r2}

# -------------------------------------------------------------
# MOVE THE FILES TO OUTPUT FOLDERS:

# Make directories to store the separate outputs in if they do not already exist (that's that the '-p' command is for):

cd /user/work/pk14885/Wasps
mkdir -p Completed_alignments
mkdir -p Depth_records
mkdir -p Duplicate_metrics

# Move the files to the respective folders:
mv ${name}.no.overlaps.bam Completed_alignments
mv ${name}.no.overlaps.bam.depth.gz Depth_records
mv ${name}.marked_dup_metrics.txt Duplicate_metrics

# -------------------------------------------------------------

# The key output of this entire script is a bam file for this wasp with overlaps removed (${name}.no.overlaps.bam), which can now be analyzed using either GATK or ANGSD. I have developed scripts for each option. However, I have also included the file before the removal of overlaps (${name}.before.removal.of.overlaps.bam), because the bamutil does generate some odd warnings/errors. Basically, these seem to be because one of the mates in many of the mate pairs gets clipped (that's the point of the clipOverlap function), but this means the CIGAR strings are mismatched for the mates. I've run a practice with two wasps and it seems to work in ANGSD fine, but just in case you need files that haven't been through bamutil, I have included the ${name}.before.removal.of.overlaps.bam files. To use them, you'll just need to run them through the finishing steps above (i.e. samtools index to generate the corresponding .bai file), and then they should be good to go. But hopefully the overlap-clipped files will be fine.
