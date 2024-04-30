#!/bin/bash
#SBATCH --job-name=SouthAfrica_SFS
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --time=0-5:00:00
# "d-hh:mm:ss"
#SBATCH --account=BISC020282
#SBATCH --output=slurm-%x.%j.out

# Navigate to the folder in which we have downloaded StairwayPlot2 on BluePebble:
cd /user/work/pk14885/stairway_plot_v2.1.1

# Generate the bash file (i.e., a '.sh' file with the same name as the blueprint file):
java -cp stairway_plot_es Stairbuilder ${this_FOLDER_NAME}.blueprint

# Now run the newly-created bash file:
bash ${this_FOLDER_NAME}.blueprint.sh
