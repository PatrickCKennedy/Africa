# PK
# Script for setting up TE library for use in dnaPipeTE.


# This might be what we need: https://github.com/nat2bee/repetitive_elements_pipeline























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

