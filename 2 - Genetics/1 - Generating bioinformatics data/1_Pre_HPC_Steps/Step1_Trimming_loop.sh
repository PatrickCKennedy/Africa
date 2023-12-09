#!/bin/bash

# Place all the files for the wasps of interest in the folder '2_Trimmed_sequences/1_Place_wasps_to_be_trimmed_here' and then run this script. The result will be adaptor-trimmed sequences for all wasps, which will then be the starting point for all subsequent analyses. By doing trimming here, we avoid having to redo it every time we redo an alignment: we only need to do it once for each finalized wasp. The successfully trimmed wasps will then appear in the folder '2_Successfully_trimmed_wasps' within '2_Trimmed_sequences'.

# -----------------------------------------
# SET PATH TO TRIMGALORE ON M1 LAPTOP:

myTRIMGALORE="/Users/pk14885/TrimGalore-0.6.6/trim_galore"
# Trim galore is a wrapper for cutadapt and fastqc, which I have installed already. For some reason, you might have to add the cutadapt location to the PATH:
export PATH="$HOME/.local/bin:$PATH"
# This was following this site: https://linuxize.com/post/how-to-add-directory-to-path-in-linux/ Apparently "this change is only temporary and valid only in the current shell session." (Also note: I got the directory address from here: https://cutadapt.readthedocs.io/en/v3.1/installation.html)
# You can check that it can find cutadapt now by running: cutadapt --version

# -----------------------------------------

# Set working directory to the folder containing wasps of interest to be trimmed:

cd /Volumes/Patricks_LaCie_Genomics_Harddrive/2_Trimmed_sequences/1_Place_wasps_to_be_trimmed_here

# Start the for-loop:

for d in *; do
echo "I am currently working on wasp $d"
cd /Volumes/Patricks_LaCie_Genomics_Harddrive/2_Trimmed_sequences/1_Place_wasps_to_be_trimmed_here/$d
$myTRIMGALORE --paired `find . -maxdepth 1 -name "*.fq.gz*" -print` -q 0
cd /Volumes/Patricks_LaCie_Genomics_Harddrive/2_Trimmed_sequences/1_Place_wasps_to_be_trimmed_here
mv /Volumes/Patricks_LaCie_Genomics_Harddrive/2_Trimmed_sequences/1_Place_wasps_to_be_trimmed_here/$d /Volumes/Patricks_LaCie_Genomics_Harddrive/2_Trimmed_sequences/2_Successfully_trimmed_wasps
done
