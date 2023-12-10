This folder contains the scripts for the pipeline if running on the University of Bristol’s HPC systems (‘BlueCrystal’ or ‘BluePebble’).

BEFORE BLUECRYSTAL/BLUEPEBBLE PIPELINE:

Before doing anything on BlueCrystal (or BluePebble), you should have completed trimming. The script for that is in folder 1a_Main_scripts of the 1_Scripts_if_running_on_own_computer folder. Use ‘Step1_Patrick_trimming_loop’. That will output trimmed files. It is these files that you can then submit to BlueCrystal.

The reference genome should also be indexed prior to starting, but we have already completed this step (it never needs to be run again). For reference, the method is: # bwa index AND THEN DRAG HERE THE REFERENCE GENOME FILE INTO THE TERMINAL WINDOW
(For ANGSD you will also need the .fai file, which you obtain using samtools faidx REFERENCEGENOMEHERE.)

I have already uploaded picard.jar and the bam util to BluePebble (in the /user/work/pk14885 directory).
———————————————

BlueCrystal Pipeline:

2. Prepare the wasps that you would like to use:
	- For each wasp, you should have only the two *val* files. After the trimming step (see above), you should have all the target wasps in the ‘2_Successfully_trimmed_wasps’ folder. You can now run the following lines to move the *val* files to the BlueCrystal Wasps submission folder:

	cd /Volumes/Patricks_LaCie_Genomics_Harddrive/2_Trimmed_sequences/2_Successfully_trimmed_wasps

	for d in *; do
		Echo “I am currently working on wasp $d”
		cd /Volumes/Patricks_LaCie_Genomics_Harddrive/2_Trimmed_sequences/2_Successfully_trimmed_wasps/$d
		cp *val* /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/Wasps
	done

Make a list of all files in the BlueCrystal Wasps submission folder:

	cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/Wasps
	ls > /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/myfilelist.txt

Process the list of files so that we end up with a spreadsheet, in which the first column is the name of the sample, and the other two columns are the forward and reverse files:

cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER
sed -i -e 's/_1_val_1.fq.gz//g' myfilelist.txt
sed -i -e 's/_2_val_2.fq.gz//g' myfilelist.txt
sort -u myfilelist.txt > wasplist.txt
rm myfilelist.txt-e
awk '$2=$1' wasplist.txt > new.txt
awk '$3=$1' new.txt > new1.txt
awk '{print $1 " " $2 "_1_val_1.fq.gz"  " " $3 "_2_val_2.fq.gz" }' new1.txt > myFilesTable.txt
rm new.txt
rm myfilelist.txt
rm new1.txt
rm wasplist.txt

We now have a table: the first column is the name, and the second and third columns are the forward and reverse files for that wasp. We should now follow this approach: https://www.biostars.org/p/338078/

3. Upload the files to BlueCrystal or BluePebble. We will upload it to a folder called ‘Wasps’ on BluePebble:

If using BluePebble:

cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/Wasps
scp -r /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/Wasps pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/

If using BlueCrystal:
	
cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/Wasps
scp -r /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/Wasps pk14885@bc4login.acrc.bris.ac.uk:/user/work/pk14885/

Note that to use ‘scp’ you must not already be logged into BlueCrystal/BluePebble. You need to still be outside BlueCrystal/BluePebble for this to work. To upload a folder (as opposed to a file), make sure you put ‘-r’ after ‘scp’.

It will ask for your password (which is Columbia2022@).

4.  Upload the myFilesTable.txt document to BlueCrystal:

cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/
scp myFilesTable.txt pk14885@bc4login.acrc.bris.ac.uk:/user/work/pk14885/

Or BluePebble:

cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/
scp myFilesTable.txt pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/

4. If you haven’t already, upload the bwa alignment script:

For BlueCrystal:

	cd /Volumes/Patricks_LaCie_Genomics_Harddrive/Scripts/2_Scripts_if_running_on_cluster
	scp 1_Alignment_on_HPC.sh pk14885@bc4login.acrc.bris.ac.uk:/user/work/pk14885 

Or BluePebble:

	cd /Volumes/Patricks_LaCie_Genomics_Harddrive/Scripts/2_Scripts_if_running_on_cluster
	scp 1_Alignment_on_HPC.sh pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/

5. You only need to do this step once. I have already uploaded it. If you haven’t already, upload the reference genome from the 3_Patrick_Indexed_ref_using_BWA folder:

	cd /Volumes/Patricks_LaCie_Genomics_Harddrive/3_Reference_Genome/Complete_reference_genome
	scp -r 3_Patrick_Indexed_ref_using_BWA pk14885@bc4login.acrc.bris.ac.uk:/user/work/pk14885

6. To login to BlueCrystal, use:

	ssh pk14885@bc4login.acrc.bris.ac.uk

Or BluePebble:

	ssh pk14885@bp1-login.acrc.bris.ac.uk

(It will ask for your password.)

7. Run the script!

	sbatch 1_Alignment_on_HPC.sh

8. To check how it is getting on, use:

	sacct -j PUTJOBNUMBERHERE

9. Once it’s finished, you can download the data using this (from the local terminal):

	scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps /Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments

10. Now for ANGSD. We need to decide what we’re going to do about index realignment. This is what I wrote about it before:
 
# -------------------------------------------------------------
# OPTIONAL STEP TO ADD IN IF GOING TO USE ANGSD DOWNSTREAM:

# Apparently this step is optional. This is what the tutorial has to say:
# "Unlike other variant detector programs (like the GATK Haplotype Caller or Freebayes), ANGSD does not realign reads during its analysis. Because it can be difficult to distinguish indels from SNPs at the end of reads if each alignment is considered separately, indels may interfere with genotype likelihood estimation. We therefore recommend running your bam files through a program that realigns reads around indels prior to running ANGSD. The GATK IndelRealigner takes all the aligned sequences from all samples in to account to validate the indels discovered from the mapping process and then realigns each read locally. This is not a mandatory step and tends to be very time-consuming if you have a large dataset, but the code is provided here if you want to give it a try (it takes ~3 minutes). We will not use these output for the rest of this course though." (https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial1_data_processing/markdowns/data_processing.md)

# I will skip indel realignment for now, but you might like to return later and add it in.
 


scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/Cameroon/ANGSD_results /Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments

scp pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/WaspsForPSMC/ForPSMC_BRIS_EF666_2_this_wasp_sequences.before.removal.of.overlaps.bam /Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments


/user/work/pk14885/Wasps/Completed_alignments/WaspsForPSMC/ForPSMC_A5_7_M1_this_wasp_sequences*












	cd /user/work/pk14885/Wasps
	for d in *; do

		# Transfer a copy of the job submission script into this wasp’s folder:
		cp /user/work/pk14885/0_Job_Submission_Script.sh /user/work/pk14885/Wasps/$d
		
		# Transfer a copy of the bwa alignment script into this wasp’s folder:
		cp /user/work/pk14885/1_Alignment_on_HPC.sh /user/work/pk14885/Wasps/$d
		
		# Run the job submission script within that folder:
		my_job_name=$d
		sh “$d/0_Job_Submission_Script.sh"
		
	done

5. 






3. To upload files to BlueCrystal, you use the following lines. 

	cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER
	scp Job_Submission_Script.sh pk14885@bc4login.acrc.bris.ac.uk:/user/work/pk14885

That is obviously for uploading the Job_Submission_Script.sh. If you want to upload something else, you would need to change that bit of the line above.



scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/SouthAfrica/ANGSD_results /Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments/SouthAfricaANGSD



0_Job_Submission_Script
The script for submitting jobs to BlueCrystal. It calls the alignment script below.

1_Alignment_on_HPC.sh
This script will perform the alignments on BlueCrystal, using bwa. It will then convert the sam file to a bam file using samtools.

2_Picard_on_laptop_after_BlueCrystal.sh
At least for now, I will do the Picard steps on the laptop after BlueCrystal has completed the alignments.

