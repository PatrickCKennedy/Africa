#!/bin/bash

# -------------------------------------------------------------
# Before this script, you should have successfully completed alignments for this high-coverage wasp, using exactly the same script as for the low-coverage wasps ('1_Alignment_on_HPC.sh'), which uses BWA-MEM. The output of that should be the .bam and .bai files for the focal wasp in question. Those two files should be in the WaspsForPSMC folder within the Completed_alignments folder on BluePebble. Use the 'before.removal.of.overlaps.bam' file.

# -------------------------------------------------------------
# MANUALLY ENTER THE NAME OF THE WASP HERE:

# Because there are so few PSMC wasps, it is easiest just to change the name manually here in the script. So, here, write the name of the wasp (e.g., "ForPSMC_A5_7_M1". Don't include the _this_wasp_sequences.no.overlaps.bam part):
#thiswaspname="ForPSMC_A5_7_M1"
thiswaspname="LOUW19PETIO"

# -------------------------------------------------------------
# NOTE ABOUT VERSIONS OF SAMTOOLS AND BCFTOOLS:

# Using bioconda, I downloaded old versions of samtools and bcftools (1.1 and 1.2, respectively), as the newer versions no longer have the commands needed for the PSMC pipeline (especially the vcfutils.pl part). I used:
#conda install -c bioconda samtools=1.1
#conda install -c bioconda bcftools=1.2

# -------------------------------------------------------------
# STEP 1: GENERATE CONSENSUS FILE FOR THIS WASP:

# Set the working directory on the laptop to the folder containing the target wasp:
cd /Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments/PSMC/$thiswaspname/

REFERENCE="/Volumes/Patricks_LaCie_Genomics_Harddrive/3_Reference_Genome/Complete_reference_genome/3_Patrick_Indexed_ref_using_BWA/B_junceaGenome.FINAL.fasta"

# Run the pipeline to prepare the wasp for PSMC (this is the pipeline recommended here [https://github.com/lh3/psmc], but with 'view' changed to 'call' [following the bit under 'Consensus calling' here: https://github.com/samtools/bcftools/wiki/HOWTOs#consensus-calling] because apparently 'view' was superceded by 'call' in versions of bcftools higher than 1.0):
samtools mpileup -uf $REFERENCE ${thiswaspname}.mergedbams.bam | bcftools call -c | vcfutils.pl vcf2fq -d 10 -D 100 | gzip > diploid.fq.gz
# That is the time-consuming step. Leave it to run overnight.

# -------------------------------------------------------------
# STEP 2: USE THE PROGRAMME 'fq2psmcfa':

# This is the next step in the PSMC pipeline [https://github.com/lh3/psmc and http://bmpvieira.github.io/labjolly14a/#/32]: it generates a 'fasta-like' file that can then be read by PSMC:
fq2psmcfa -q20 diploid.fq.gz > diploid.psmcfa

# Now run PSMC:
psmc -N30 -t5 -r1 -p "28*2+3+5" -o my_diploid.psmc diploid.psmcfa
# e.g., https://www.biorxiv.org/content/10.1101/2019.12.20.884403v1.full.pdf uses  -p "28*2+3+5"
    
# Plot the result:
psmc_plot.pl -g 1 -u 3.6e-09 diploid my_diploid.psmc
# -g is the 'number of years per generation'. For South Africa, this should be 1, I guess. For Cameroon, what should it be? Tindo et al. (2002) found a mean colony cycle of 7 months. So perhaps we should assume a generation time of 7 months, assuming most reproductives are produced at the end of the colony cycle. So that would be 7/12=0.583 years per generation... So almost twice as fast as the generation time in South Africa.
# For mutation rate ('-u'): in bumblebees, mutuation rate is "3.6 × 10−9 per haploid genome per generation" (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5854123/).

# Periods in climate history that might be worth annotating on the plot:
# ARIDITY IN AFRICA between 23,000 and 14,500 years ago: see the "Last Glacial Aridity Maximum" section here (https://www.esd.ornl.gov/projects/qen/nercAFRICA.html). The map seems to imply that the Congo Basin was extensive savanna during this period.
# That website also seems to imply that forests were extensive in the preceding period (a thin sliver of time 28-22,000 14C years ago [what is this in actual years?!]). However, conditions were not as warm as today - it mentions Cameroon.

# -------------------------------------------------------------
# PLOT 100 ROUNDS OF BOOTSTRAPPING:

# Split the chromosomes into shorter sequences (from which the bootstrapping will later randomly resample):
splitfa diploid.psmcfa > split.psmcfa

# Perform 100 rounds of bootstrapping:
for myBOOTSTRAPnumber in {1..100}
do
( psmc -N30 -t5 -r1 -b -p "28*2+3+5" -o round-${myBOOTSTRAPnumber}.psmc split.psmcfa ) &
done
wait

# You need to give the bootstrapping some time to run. The 100 files seem to run in parallel, finally edging up to a size of around 120 KB each.
        
# Plot the results:
        
cat my_diploid.psmc round-*.psmc > combined.psmc
psmc_plot.pl -g 1 -u 3.6e-09 combined combined.psmc
# Make sure you put in the right generation time for the population! i.e. I think g=1 for South Africa but g=0.583 (7 months?) for Cameroon?

# ----------------------------------------------
# So, we have now generated a combined plot for this sample (i.e., the main line plus its 100 bootstraps). However, we would like to be able to merge this with plots for other samples. To do that, we need to prepare it for plotting in R. Run the following (with the right generation times!):

psmc_plot.pl -g 1 -u 3.6e-09 -R primary_psmc my_diploid.psmc
cat round-*.psmc > bootstraps.psmc
psmc_plot.pl -g 1 -u 3.6e-09 -R bootstraplines bootstraps.psmc

# Following this website (https://openwetware.org/wiki/Schumer_lab:_Commonly_used_workflows#Demographic_Inference_with_PSMC), "add 2 columns noting your population and if it was a bootstrap or not" (i.e., write "primary" or "bootstrap"):

        # First, the primary line:
        awk '{print $0, "\t", "Magaliesberg_Petio","\t", "primary"}' primary_psmc.0.txt > species_nonbootstrap.txt

        # Second, the bootstrap lines:
        for i in `ls bootstraplines*txt`; do awk '{print $0, "\t", "Magaliesberg_Petio bootstrap", "\t", FILENAME}' $i; done > species_bootstrap.txt
        #"for all your bootstrap files, add 2 columns noting your species (or population) + if it was a bootstrap and the name of your file. FILENAME is a variable that awk recognizes and can be left as is."

        cat species_nonbootstrap.txt species_bootstrap.txt > PSMC_R_plotting_file.txt #"concatenate your modified psmc output files. now ready for plotting in R"
        
# ----------------------------------------------------------------
# SCRIPT TO RUN IN R:
    # Next, open R, and run the following in R (not in the terminal!). But make sure that where it says INSERTPOPULATIONHERE (at three points below), you write the correct name in! (e.g. Magaliesberg or Yaounde)
    
#Navigate to the relevant folder for each population (i.e., set the working directory to each in turn) to read the corresponding file for that population into R:
PSMC_data_Yaounde <- read.csv("PSMC_R_plotting_file.txt", header=FALSE, sep = "\t")

PSMC_data_Magaliesberg <- read.csv("PSMC_R_plotting_file.txt", header=FALSE, sep = "\t")

library(ggplot2)
    
YaoundePlot <- ggplot() +
    geom_step(data=subset(PSMC_data_Yaounde, PSMC_data_Yaounde$V6==" Yaounde bootstrap "),
              aes(x=V1, y=V2*10, group=V7), color="turquoise", alpha=0.17) +
    geom_step(data=subset(PSMC_data_Yaounde, PSMC_data_Yaounde$V6==" Yaounde "),
              aes(x=V1, y=V2*10, group=V7), color="navy", alpha = 0.5) +
    scale_x_log10( #set limits, breaks, labels however you please
        limits=c(11000, 1000000),
        breaks = c(10000,100000,1000000),
        labels = c("10,000","100,000","1 million")
    ) +
    scale_y_continuous(
        #  expand=c(0,0), limits = c(0,1250), breaks = c(seq(0,1250,250)) #set limits, breaks, labels however you please
    ) +
    theme_classic(base_size = 12) +
    theme(axis.title.x = element_text(size = 12,family = "Helvetica"),
          axis.title.y = element_text(size = 12),
          axis.text.y = element_text(size = 12,color = "black"),
          axis.text = element_text(size = 12,color = "black"),
          axis.line = element_line(colour = 'black', linewidth = 0),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          legend.position = "none") +
    xlab("Years ago") +
    ylab(expression(paste("Effective population size (N"[e], " x", 10^{3}, ")",sep=" "))) + #can change scaling so 10^4, 10^6 etc, just also modify the scaling factor in geom_step(). psmc plot automatically outputs 10^4
    annotation_logticks(side = "b") + theme(panel.border = element_rect(color = "black",fill = NA,size = 1))
p1 <- YaoundePlot + geom_step(data=subset(
    PSMC_data_Magaliesberg,
    PSMC_data_Magaliesberg$V6==" Magaliesberg bootstrap "),
    aes(x=V1, y=V2*10, group=V7),
    color="pink", alpha=0.26) +
    geom_step(data=subset(
        PSMC_data_Magaliesberg,
        PSMC_data_Magaliesberg$V6==" Magaliesberg "),
        aes(x=V1, y=V2*10, group=V7),
        color="red")

# Show the plot:
p1

# Add boxes to show climatic episodes:
p2 <- p1 +
    geom_rect(aes(xmin = 14500, xmax = 22000, ymin = -Inf, ymax = Inf),fill = "#86DBDB", alpha = 0.2) +
    geom_rect(aes(xmin = 194000, xmax = 135000, ymin = -Inf, ymax = Inf),fill = "#86DBDB", alpha = 0.2)
p2

# Add text annotations:
annotation <- data.frame(
    x = c(17900,163000),
    y = c(70,70),
    label = c("Last\nGlacial\nAridity\nMax",
              "Penultimate\nGlacial\nPeriod")
)

p3 <- p2 + geom_text(data=annotation, aes( x=x, y=y, label=label),
              color="black",
              size=3.5 )

# Add text to label populations:
pop_annotation <- data.frame(
    x = c(400000,700000),
    y = c(215,100),
    label = c("Yaounde,\nCameroon",
              "Magaliesberg,\nSouth Africa")
)

p3 + geom_text(data=pop_annotation, aes( x=x, y=y, label=label),
               color=(c("turquoise","pink")),
               size=4, hjust = 0.5, alpha = 1)





















# -------------------------------------------------------------
# STEP 1: CONSENSUS-CALLING

# I followed this video (https://www.youtube.com/watch?v=EJGz3yryrPo) to install bcftools. To point to where it is installed, we then use the 'alias' command:
alias bcftools=/Users/pk14885/apps/bcftools/bin/bcftools


# Using: http://samtools.github.io/bcftools/howtos/consensus-sequence.html

# call variants
bcftools mpileup -Ou -f $REFERENCE ${thiswaspname}_this_wasp_sequences.no.overlaps.bam | bcftools call -mv -Oz -o calls.vcf.gz

bcftools index calls.vcf.gz

# normalize indels
bcftools norm -f $REFERENCE calls.vcf.gz -Ob -o calls.norm.bcf

# filter adjacent indels within 5bp
bcftools filter --IndelGap 5 calls.norm.bcf -Ob -o calls.norm.flt-indels.bcf

# apply variants to create consensus sequence
cat $REFERENCE | bcftools consensus calls.vcf.gz > consensus.fa

# -------------------------------------------------------------
# STEP 2: RUNNING PSMC

# I download PSMC using 'conda' (https://anaconda.org/genomedk/psmc). So now we should be able to run psmc just by typing 'psmc'.
















#
