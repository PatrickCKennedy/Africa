# PK
# Script for setting up TE library for use in dnaPipeTE.


# This might be what we need: https://github.com/nat2bee/repetitive_elements_pipeline


# ------------------------------------------------------------
# EDTA on BluePebble:


    # Another option: https://github.com/ellenbell/FasTE
    # Following that pipeline here:
        # I have downloaded the EDTA Singularity container on BluePebble (in the work directory), following https://github.com/oushujun/EDTA#quick-installation-using-singularity-good-for-hpc-users
    
    cd /user/work/pk14885/Running_EDTA
    module load apps/singularity/1.1.3
    export PYTHONNOUSERSITE=1
    singularity exec /user/work/pk14885/EDTA.sif EDTA.pl --genome B_junceaGenome.FINAL.fasta --species others --sensitive 1 --threads 42 


singularity shell -B/user/work/pk14885/Running_EDTA:/mnt /user/work/pk14885/EDTA.sif
EDTA.pl --genome /mnt/B_junceaGenome.FINAL.fasta --species others --sensitive 1 --threads 42 

# This leads to the following error: "Error: The RMblast engine is not installed in RepeatMasker!"
# But this thread (https://github.com/oushujun/EDTA/issues/11) says you can solve this by
# pointing to your own installation of RepeatMasker:














singularity exec /user/work/pk14885/EDTA.sif EDTA.pl --genome opt/B_junceaGenome.FINAL.fasta --species others --sensitive 1 --threads 42 


singularity shell --cleanenv \
    -B/user/work/pk14885/Project:/mnt \
    /user/work/pk14885/dnaPipeTE/dnapipete.img <<EOF
cd /opt/dnaPipeTE
python3 /opt/dnaPipeTE/dnaPipeTE.py -input /mnt/data/${my_wasp_name_manual_entry}.SAMPLE_R1.fastq.gz -output /mnt/output_${my_wasp_name_manual_entry} -genome_size 407000000 -genome_coverage 0.5 -sample_number 2 -RM_t 0.2 -cpu 8
EOF


<<EOF
cd /opt/dnaPipeTE
python3 /opt/dnaPipeTE/dnaPipeTE.py -input /mnt/data/${my_wasp_name_manual_entry}.SAMPLE_R1.fastq.gz -output /mnt/output_${my_wasp_name_manual_entry} -genome_size 407000000 -genome_coverage 0.5 -sample_number 2 -RM_t 0.2 -cpu 8
EOF


# ------------------------------------------------------------
# EDTA on the local computer:

# I have installed EDTA as a Docker container on the laptop.

# To run it on the laptop:
cd /Users/pk14885/Downloads/
docker run --platform linux/amd64 -v $PWD:/in -w /in oushujun/edta:2.0.0 EDTA.pl --genome B_junceaGenome.FINAL1.fa --species others --sensitive 1 --threads 4

# As above, this leads to the error "Error: The RMblast engine is not installed in RepeatMasker!"
# We can try solving this by pointing to our own version of RepeatMasker (https://github.com/oushujun/EDTA/issues/11):
docker run --platform linux/amd64 -v $PWD:/in -w /in oushujun/edta:2.0.0 EDTA.pl --genome B_junceaGenome.FINAL1.fa --species others --sensitive 1 --threads 4 --repeatmasker /Users/pk14885/Downloads/RepeatMasker

docker run -it clemgoub/dnapipete:latest


# ------------------------------------------------------------














# On the local computer:

# Enter the Docker container for dnaPipeTE (which includes RepeatMasker):
sudo docker run --platform linux/amd64 -it -v ~/Project:/mnt clemgoub/dnapipete:latest

# Run famdb.py (following https://tehub.org/tutorials/docs/dnaPipeTE):
famdb.py -i <Dfam.h5> families -f fasta_name -a <taxa> --include-class-in-name > library.fasta

# Following this website (https://oligo.readthedocs.io/en/latest/overview.html):
famdb.py -i /opt/RepeatMasker/Libraries/Dfam.h5 families --format hmm 'Mus musculus' --include-class-in-name > Patrick_test_mouse.hmm
famdb.py -i /opt/RepeatMasker/Libraries/Dfam.h5 families --format hmm 'Drosophila' --include-class-in-name > Patrick_test_Drosophila.hmm
famdb.py -i /opt/RepeatMasker/Libraries/Dfam.h5 families --format hmm 'hymenopterans' --include-class-in-name > Patrick_test_hymenopterans.hmm



# Following this website (https://www.rcac.purdue.edu/knowledge/biocontainers/repeatmasker?all=true):
famdb.py -i /opt/RepeatMasker/Libraries/Dfam.h5 names mammal

hymenopterans



# Currently, RepBase is subscription only.
# However, the older versions of the RepBase database are available here:
# https://github.com/yjx1217/RMRB?search=1
# From there, I have downloaded: RepBaseRepeatMaskerEdition-20181026.tar.gz
# I then opened this, which created this folder on the local computer:  /Users/pk14885/Downloads/Libraries 
# That folder contains a file called 'RMRBSeqs.embl'

