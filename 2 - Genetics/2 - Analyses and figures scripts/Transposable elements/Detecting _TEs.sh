% PK
% Script for detecting transposable elements in low-coverage whole genome data

% Using 'dnaPipeTE' (Goubert, 2023)
% Goubert, C. (2023). Assembly-Free Detection and Quantification of Transposable Elements with dnaPipeTE. In: Branco, M.R., de Mendoza Soler, A. (eds) Transposable Elements. Methods in Molecular Biology, vol 2607. Humana, New York, NY. https://doi.org/10.1007/978-1-0716-2883-6_2

% Following the guide here: https://tehub.org/en/tutorials/docs/dnaPipeTE

% First, install dnaPipeTE using Docker.

% Once dnaPipeTE has been installed,

% NOTE: "Idealy, short read data should be cleaned from non-nuclear host DNA. At the very least, mtDNA should be removed by aligning the raw reads to the mithocondrial genome of the target species.
For this tutorial, we have prepared a toy dataset that has already been filtered using bwa mem.
If no mithochondrial genome available for your species of interest, dnaPipeTE can be run on the raw read set to assemble the mtDNA genome. It can be easily recovered in the outputs as one of the largest (in bp) and most abundant repeat (see post-processing section)" (https://tehub.org/en/tutorials/docs/dnaPipeTE)

% Before starting, you should install 'RepeatMasker' from here: https://www.repeatmasker.org/RepeatMasker/
% e.g., I have installed 'RepeatMasker' on the local computer, within 'pk14885'. RepeatMasker comes with 
% a library of TEs, which is found in: /Users/pk14885/RepeatMasker/Libraries/Dfam.h5
% We will give this library the following name (i.e., you can replace it with a different library if required):

my_DFAM_library="/Users/pk14885/RepeatMasker/Libraries/Dfam.h5"

% ---------------------------------------------------------------------------------------------------------
% GENERATE A FASTQ FILE FROM THE POST-ALIGNMENT BAM FILE FOR YOUR WASP OF INTEREST:

% For this step, I am using the BAM files before the removal of the overlaps by BAMUTIL.

% In the normal pipeline used for alignments, we produced a BAM file for each wasp (using bwa mem, etc.). 
% We now need to generate a FASTQ file from that BAM file (similar to page 29 in the chapter 'TE Analysis with dnaPipeTE'). 
% To do so, we use samtools:

            % Point to the BAM file for the wasp of interest:
            my_wasp_to_process="/Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments/Wasps/Completed_alignments_without_bamutil_stage/SOM2_3_TARSUS_CKDL220030023-1A_HK7J7DSX5.before.removal.of.overlaps.bam"

            % First use samtools to sort the read pairs by name (in order to prevent bedtools complaining that the pairs are not next to each other):
            samtools sort -n $my_wasp_to_process sorted.by.name 
             
            % Now use samtools fastq to generate the FASTQ files:
            samtools fastq -@ 8 sorted.by.name.bam -1 SAMPLE_R1.fastq.gz -2 SAMPLE_R2.fastq.gz -0 /dev/null -s /dev/null -n

            % Next, we will use the newly-produced 'SAMPLE_R1.fastq.gz' file (for dnaPipeTE, you only use one of the R1 or R2 files):
            my_wasp_to_process="/Users/pk14885/SAMPLE_R1.fastq.gz"

% --------------------------------------------------------------------------------
% MOVE THE INPUT FILE TO A NEW FOLDER CALLED 'PROJECT' (following https://tehub.org/tutorials/docs/dnaPipeTE):

mkdir ~/Project
cd ~/Project
mkdir data
mv $my_wasp_to_process data

% --------------------------------------------------------------------------------
% CHECK THAT dnaPipeTE IS WORKING PROPERLY:

% To check that dnaPipeTE is working, we can now start to run dnaPipeTE through 'Docker':
docker run --platform linux/amd64 -it clemgoub/dnapipete:latest
# "within the container (the prompt will be "(dnaPipeTE/opt/dnaPipeTE)#")" (https://tehub.org/tutorials/docs/dnaPipeTE)
python3 dnaPipeTE.py -h # "this will display the help screen"
exit # "return to the host machine shell"

% --------------------------------------------------------------------------------
% INITIATE dnaPipeTE:

% Start the dnaPipeTE container:
sudo docker run --platform linux/amd64 -it -v ~/Project:/mnt clemgoub/dnapipete:latest

% We need to supply the TE library file. I downloaded it as part of the 'noarch/repeatmasker-4.1.5-pl5321hdfd78af_1.tar.bz2' download at https://anaconda.org/bioconda/repeatmasker/files (it is inside the 'Libraries' folder once you've downloaded RepeatMasker):
myRMlibrary="/Users/pk14885/Downloads/noarch_repeatmasker-4.1.5-pl5321hdfd78af_1/share/RepeatMasker/Libraries/RepeatMasker.lib"

python3 dnaPipeTE.py -input /mnt/data/SAMPLE_R1.fastq.gz -output /mnt/output -RM_lib $myRMlibrary -genome_size 407000000 -genome_coverage 0.1 -sample_number 2 -RM_t 0.2 -cpu 2

% CITATIONS ARE REQUIRED FOR USING RepeatMasker.lib:
% General References apply to all applications of Repbase, also known as Repbase Update, to data analysis (e.g. to sequence annotations using CENSOR, RepeatMasker or XBLAST). If you use Repbase in your work please cite one of the following papers:
    % Bao, W., Kojima, K.K., Kohany, O. Repbase Update, a database of repetitive elements in eukaryotic genomes. Mob DNA, 2015;6:11
    % Jurka, J., Kapitonov, V.V., Pavlicek, A., Klonowski, P., Kohany, O., Walichiewicz, J. (2005) Repbase Update, a database of eukaryotic repetitive elements. Cytogentic and Genome Research 110:462-467
    % Jurka, J. Repbase Update: a database and an electronic journal of repetitive elements. Trends Genet.9:418-420 (2000)
    % Jurka, J. Repeats in genomic DNA: mining and meaning. Curr. Opin. Struct. Biol.8:333-337 (1998).

python3 dnaPipeTE.py \
-input /mnt/data/SAMPLE_R1.fastq.gz \
-output /mnt/PatrickTest \
-sample_size 100000 \
-sample_number 2 \
-RM_lib /opt/RepeatMasker/Libraries/RepeatLibrary.lib \
-RM_t 0.25 \
-cpu 8


python3 dnaPipeTE.py \
-input /mnt/data/SAMPLE_R1.fastq.gz \
-output /mnt/Patrick_27Nov2023 \
-sample_size 1000 \
-sample_number 2 \
-RM_lib ../RepeatMasker/Libraries/RepeatMasker.lib \
-RM_t 0.25 \
-cpu 8



% P: You can either supply a genome size and coverage (e.g., -genome_size 407000000 -genome_coverage 0.15) or a sample size (e.g., -sample_size 500000) but not both.
% An example: https://littlebioinformatician.wordpress.com/scripts/dnapipete/
% In the run above, I have used a small sample size of 100000 as a test. If it works, we can increase it.

% P: When running on the local computer, it can hang at a given percent progress. However, if you kill the task (using Cntl+C) and then restart it, it resumes at the same point, which is good news - and can break the deadlock.

python3 dnaPipeTE.py -input /mnt/reads_input.fastq -output /mnt/output -RM_lib ../RepeatMasker/Libraries/RepeatMasker.lib -genome_size 170000000 -genome_coverage 0.1 -sample_number 2 -RM_t 0.2 -cpu 2

