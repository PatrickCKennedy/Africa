# PK
# BATCH ANALYSIS OF MANY WASPS' MITOCHONDRIAL SEQUENCES ON THE LOCAL COMPUTER
# following https://github.com/linzhi2013/MitoZ/wiki/Batch-processing-of-many-samples

# On the Desktop of the local computer, there is a folder called 
# 'Batch_running_of_MitoZ'. Transfer to this folder any wasps that you
# would like to include in the batch run to the folder 'Place_input_wasps_here'
# inside this folder. Inside this folder, you should place a folder for each
# chosen wasp, with the wasp's name as the folder name. Inside each wasp's folder,
# you should then place a copy of its 'val_1' and 'val_2' trimmed files.

# -----------------------------------------------------------------------------
# On local computer, navigate to the folder:
            cd /Users/pk14885/Desktop/Batch_running_Mitoz

cd Test_batch

# Loop through each of the wasps, running MitoZ on each:
for d in */ ; do
    echo "$d"
    cd "$d"
    
    this_wasp_val_1_file=$(ls *val_1*)
    this_wasp_val_2_file=$(ls *val_2*)
    this_wasp_name=$(basename $PWD)

    docker run -v $PWD:$PWD -w $PWD --rm guanliangmeng/mitoz:3.6  mitoz all \
    --fq1 $PWD/$this_wasp_val_1_file \
    --fq2 $PWD/$this_wasp_val_2_file \
    --outprefix $this_wasp_name \
    --genetic_code 5 \
    --clade Arthropoda \
    --fastq_read_length 150 \
    --data_size_for_mt_assembly 0 \
    --assembler megahit \
    --thread_number 8 \
    --requiring_taxa Arthropoda
    
    cd ..
    
done

# It can take about half an hour per wasp.
      
    # Record the wasp's name (the name of its folder), which we will use below
    # in the output file name:
    this_wasp_name=$(basename $PWD)
      

# -----------------------------------------------------
# OPTION 1: IF RUNNING ON JUST A SINGLE WASP OF INTEREST:

# Navigate to the folder containing the (adaptor-trimmed) fastq files for the wasp of interest:
cd /Users/pk14885/Desktop/Testing_MitoZ_again_on_L9_a

# Automatically detect the (adaptor-trimmed) forward file:
this_wasp_val_1_file=$(ls *val_1*)

# Automatically detect the (adaptor-trimmed) reverse file:
this_wasp_val_2_file=$(ls *val_2*)

# Run MitoZ in Docker (the current directory is given by $PWD): 
docker run -v $PWD:$PWD -w $PWD --rm guanliangmeng/mitoz:3.6  mitoz all \
--fq1 $PWD/$this_wasp_val_1_file \
--fq2 $PWD/$this_wasp_val_2_file \
--outprefix Patrick_MitoZ_ \
--clade Arthropoda \
--fastq_read_length 151 \
--assembler megahit \
--requiring_taxa Arthropoda
























# Enter today's date (we will use this to create a folder to store the outputs of today's analysis):
            projectID="Outputs_on_1st_March_2024"

# Make a folder to contain the outputs for the current run (change the title to whichever date
# you are running this analysis on):
            mkdir $projectID
            cd $projectID

# Make a file containing a table, where the first column is the 'val_1' file and the second is the 'val_2' file:
            ls /Users/pk14885/Desktop/Batch_running_Mitoz/Place_input_wasps_here/*val*.fq.gz | awk 'NR%2{printf "%s ",$0;next;}1' > sample_fq.list

# The code below requires Docker to be running. You therefore must open the Docker daemon on the laptop first.

# Run MitoZ on the wasps in this batch by running the following perl block of code (adapted [i.e., Docker added] following https://github.com/linzhi2013/MitoZ/wiki/Batch-processing-of-many-samples):
            cat sample_fq.list | perl -ne '
            chomp; 
            my @a=split /\s+/; # to split the path of fq1 and fq2 into array @a
            my $b=(split /\//, $a[0])[-1];  # to get the basename of fq1, e.g. sampleID_1.1.fq.gz
            my $sample=(split /\./, $b)[0];  # to extract the sample ID, e.g. sampleID_1. You might need to change this.
            
            mkdir $sample; 
            chdir $sample;
            
            `echo "docker run -v $PWD:$PWD -w $PWD --rm guanliangmeng/mitoz:3.6 mitoz all \
            --fq1 $a[0] \
            --fq2 $a[1] \
            --outprefix $sample \
            --thread_number 8 \
            --clade Arthropoda \
            --genetic_code 5 \
            --fastq_read_length 150 \
            --assembler mitoassemble \
            --kmers 51,71,91 \
            --requiring_taxa Arthropoda" `
          
            chdir "../" ; '








            
# Run MitoZ in Docker (the current directory is given by $PWD): 
docker run -v $PWD:$PWD -w $PWD --rm guanliangmeng/mitoz:3.6  mitoz all \
--fq1 $PWD/$this_wasp_val_1_file \
--fq2 $PWD/$this_wasp_val_2_file \
--outprefix Patrick_MitoZ_ \
--clade Arthropoda \
--fastq_read_length 151 \
--assembler megahit \
--requiring_taxa Arthropoda
    

