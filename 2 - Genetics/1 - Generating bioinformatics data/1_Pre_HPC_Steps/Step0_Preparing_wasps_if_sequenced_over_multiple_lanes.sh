#!/bin/bash
cd "${0%/*}"

# This script is only used for wasps that were sequenced over multiple lanes or wells.

# -------------------------------------------------------------
# MERGE THE FILES FOR THE FOCAL WASP:

	# Find and concatenate all the forward ("_1.fq.gz") data:
		cat `find . -maxdepth 1 -name "*_1.fq.gz*" -print` > this_wasp_sequences_1.fastq.gz

	# Find and concatenate all the reverse ("_2.fq.gz") data:
		cat `find . -maxdepth 1 -name "*_2.fq.gz*" -print` > this_wasp_sequences_2.fastq.gz

	# And now remove the original files:
		rm `find . -maxdepth 1 -name "*_1.fq.gz*" -print`
		rm `find . -maxdepth 1 -name "*_2.fq.gz*" -print`
  
# -------------------------------------------------------------

