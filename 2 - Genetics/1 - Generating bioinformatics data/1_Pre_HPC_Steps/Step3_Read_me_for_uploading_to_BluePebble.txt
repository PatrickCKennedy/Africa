# PK
# Process for uploading to University of Bristol's HPC system 'BluePebble' (or 'BlueCrystal')

# 1. Complete trimming on local computer.

# 2. Ensure that picard.jar and the bam util have been uploaded to your work directory on BluePebble.

# 3. Ensure that the reference genome has been indexed (this only needs to be run once). Indexing uses bwa index [reference genome here]. For ANGSD, you will also need the .fai file, using samtools faidex [reference genome here].

# 4. After trimming, move the two *val* files for each wasp to the submission folder on the local computer:

cd /Volumes/Patricks_LaCie_Genomics_Harddrive/2_Trimmed_sequences/2_Successfully_trimmed_wasps

	for d in *; do
		Echo “I am currently working on wasp $d”
		cd /Volumes/Patricks_LaCie_Genomics_Harddrive/2_Trimmed_sequences/2_Successfully_trimmed_wasps/$d
		cp *val* /Volumes/Patricks_LaCie_Genomics_Harddrive/BluePebble_SUBMISSION_FOLDER/Wasps
	done

# 5. Make a list of all files in the BlueCrystal Wasps submission folder:

	cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/Wasps
	ls > /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/myfilelist.txt

# Process the list of files so that we end up with a spreadsheet, in which the first column is the name of the sample, and the other two columns are the forward and reverse files:

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

# We now have a table: the first column is the name, and the second and third columns are the forward and reverse files for that wasp. We should now follow this approach: https://www.biostars.org/p/338078/

# 3. Upload the files to BluePebble. We will upload it to a folder called ‘Wasps’ on BluePebble:

cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/Wasps
scp -r /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/Wasps pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/

# Note that to use ‘scp’ you must not already be logged into BlueCrystal/BluePebble. You need to still be outside BlueCrystal/BluePebble for this to work. To upload a folder (as opposed to a file), make sure you put ‘-r’ after ‘scp’.

# It will ask for your password.

# 4.  Upload the myFilesTable.txt document:

cd /Volumes/Patricks_LaCie_Genomics_Harddrive/BlueCrystal_SUBMISSION_FOLDER/
scp myFilesTable.txt pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/

# 4. If you haven’t already, upload the bwa alignment script:

	cd /Volumes/Patricks_LaCie_Genomics_Harddrive/Scripts/2_Scripts_if_running_on_cluster
	scp 1_Alignment_on_HPC.sh pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/

# 5. If you haven’t already, upload the reference genome from the 3_Patrick_Indexed_ref_using_BWA folder:

	cd /Volumes/Patricks_LaCie_Genomics_Harddrive/3_Reference_Genome/Complete_reference_genome
	scp -r 3_Patrick_Indexed_ref_using_BWA pk14885@bc4login.acrc.bris.ac.uk:/user/work/pk14885

# 6. To login to BluePebble:

	ssh pk14885@bp1-login.acrc.bris.ac.uk

# (It will ask for your password.)

# 7. Run the script!

	sbatch 1_Alignment_on_HPC.sh

# 8. To check how it is getting on, use:

	sacct -j PUTJOBNUMBERHERE

 
