# PK
# k-mer estimation for genome size prediction using the 'RESPECT' algorithm
# Citation: https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009449
# Software on GitHub: https://github.com/shahab-sarmashghi/RESPECT

# I am following the instructions at that GitHub link.
# I am currently on number 4 - getting a Gurobi academic licence. 
# I've registered on the Gurobi website. To be issued a licence, I
# just need to be connected to the university internet I make the request on
# the website. My licence details:
# My licence key: grbgetkey 00374c27-4011-420d-949b-a56e80009d15 (written to the local computer)
# Licence number: 2453295
# I have installed Python version 3.7.1 in a virtual environment called 'myenv' on the
# laptop, following vincedjango's answer here: https://stackoverflow.com/questions/51125013/how-can-i-install-a-previous-version-of-python-3-in-macos-using-homebrew
# i.e.:
    ##conda init
    ##conda create -n myenv python=3.7.1
# To activate this environment, use:
    ##conda activate myenv
# To deactivate, use:
    ##conda deactivate
# After activating the 'myenv' environment, I installed RESPECT using 'python setup.py install' (https://github.com/shahab-sarmashghi/RESPECT)

conda activate myenv
respect -i /Volumes/Patricks_LaCie_Genomics_Harddrive/test_folder/A2_7_2_Cameroon_EKDL230052137-1A_22GGMJLT3_L7_1_val_1.fq.gz --debug


# The outputs can be found in:     /Users/pk14885/tmp


respect -i --debug






# Set working directory to folder on BluePebble containing the read files for the wasp of interest:
cd /user/work/pk14885/Wasps_Dec2023

myForwardRead="A4_2_3_Cameroon_EKDL230052137-1A_22GGMJLT3_L7_1_val_1.fq.gz"
myReverseRead="A4_2_3_Cameroon_EKDL230052137-1A_22GGMJLT3_L7_2_val_2.fq.gz"
