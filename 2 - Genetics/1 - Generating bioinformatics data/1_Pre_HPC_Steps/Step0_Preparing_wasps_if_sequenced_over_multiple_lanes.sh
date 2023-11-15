#!/bin/bash
cd "${0%/*}"

# This script is only used for wasps that were sequenced over multiple lanes. For instance, the SixWaspLibrary wasps were sequenced on two lanes. We therefore need to merge the outputs before proceeding. For wasps sequenced on just one lane, this script should be ignored.

# -------------------------------------------------------------
# IF THIS WASP WAS SEQUENCED OVER MULTIPLE LANES, MERGE THE FILES:

# For some wasps, there may be data from multiple lanes. For instance, Novogene decided to run the SixWaspLibrary again to reach the contracted amount of sequencing, which means the wasps in the SixWaspLibrary have four files (two forwards, two reverse).  

# Before continuing, we should concatenate the forward files, and separately concatenate the reverse files (in the same order):

	# Find and concatenate all the forward ("_1.fq.gz") data:
		cat `find . -maxdepth 1 -name "*_1.fq.gz*" -print` > this_wasp_sequences_1.fastq.gz

	# Find and concatenate all the reverse ("_2.fq.gz") data:
		cat `find . -maxdepth 1 -name "*_2.fq.gz*" -print` > this_wasp_sequences_2.fastq.gz

	# And now remove the original files:
		rm `find . -maxdepth 1 -name "*_1.fq.gz*" -print`
		rm `find . -maxdepth 1 -name "*_2.fq.gz*" -print`

# See here: https://www.biostars.org/p/9481993/

# However, see here: https://gatk.broadinstitute.org/hc/en-us/articles/360035889471?id=3060
# and also here: https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial1_data_processing/markdowns/data_processing.md#merge-samples-that-were-sequenced-in-multiple-batches

# THESE LAST TWO SUGGEST THAT YOU SHOULD DO THE MERGING AFTER THE MAPPING TO REFERENCE GENOME STEP - I THINK WE SHOULD UPDATE THE CODE TO ALLOW THIS - TO DO. actually, i'm not sure if it's necessary. it seems to be a good idea if you want to keep track of different lanes in case you want to troubleshoot them later. but we could always just go back to the raw files and check if we need to do that.

