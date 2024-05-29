#!/bin/bash

#SBATCH --job-name=MATLAB_KinDiscrimination
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --time=2-00:00:00
#SBATCH --mem=6G
#SBATCH --account=BISC020282
#SBATCH --array 1-269

# ARRAY JOB SUBMISSION SCRIPT FOR RUNNING THE SIMULATION AT DIFFERENT LEVELS OF KIN DISCRIMINATION
# This HPC submission script runs 'Africa_model_HPC.m' across real-world climate data on a grid of Africa, which 
# you set up by first running the 'Importing_climate_data.m' script in MATLAB on the local computer and uploading
# the resulting 'SimulationInputData.txt' file to the MATLAB_Simulation/Input_data folder on BluePebble.

# Manually add the correct number of grid cells to simulate above (e.g., --array 1-269 if there are 269 simulations to run).

# The MATLAB script ('Africa_model_HPC.sh') and this script should be uploaded to the relevant folder on HPC ('MATLAB_Simulation'). The input data ('SimulationDataInput.txt') should be uploaded to 'MATLAB_Simulation/Input_data'.

# -------------------------------------------------------------------
# START THE LOOP THROUGH THE DIFFERENT MATLAB SIMULATIONS:

# Each simulation corresponds to a single geographical grid cell:
SimID=${SLURM_ARRAY_TASK_ID}

# --------------------------------------------------------------------------------------------
# READ IN THE ENVSTATE INPUTS FOR EACH SIMULATION IN THE LOOP:

# Set working directory to the folder on BluePebble containing the input data (in the textfile 'SimulationInputData.txt', generated already in MATLAB on the local computer and uploaded to the cluster):
cd /user/work/pk14885/MATLAB_Simulation/Input_data

# Env1: For EnvState in Phase 1 (stored in column 3 of 'SimulationInputData'):
Env1=$(awk '//{print $3 }' SimulationInputData.txt)
Env1_in_this_simulation=$(echo $Env1 | awk '{print $'$SimID'}'); echo $Env1_in_this_simulation

# Env2: For EnvState in Phase 2 (stored in column 4 of 'SimulationInputData'):
Env2=$(awk '//{print $4 }' SimulationInputData.txt)
Env2_in_this_simulation=$(echo $Env2 | awk '{print $'$SimID'}'); echo $Env2_in_this_simulation

# Env3: For EnvState in Phase 2 (stored in column 5 of 'SimulationInputData'):
Env3=$(awk '//{print $5 }' SimulationInputData.txt)
Env3_in_this_simulation=$(echo $Env3 | awk '{print $'$SimID'}'); echo $Env3_in_this_simulation

# Env4: For EnvState in Phase 2 (stored in column 6 of 'SimulationInputData'):
Env4=$(awk '//{print $6 }' SimulationInputData.txt)
Env4_in_this_simulation=$(echo $Env4 | awk '{print $'$SimID'}'); echo $Env4_in_this_simulation

# Env5: For EnvState in Phase 2 (stored in column 7 of 'SimulationInputData'):
Env5=$(awk '//{print $7 }' SimulationInputData.txt)
Env5_in_this_simulation=$(echo $Env5 | awk '{print $'$SimID'}'); echo $Env5_in_this_simulation

# Env6: For EnvState in Phase 2 (stored in column 8 of 'SimulationInputData'):
Env6=$(awk '//{print $8 }' SimulationInputData.txt)
Env6_in_this_simulation=$(echo $Env6 | awk '{print $'$SimID'}'); echo $Env6_in_this_simulation

# --------------------------------------------------------------------------------------------
# READ IN THE ISHIBERNATION INPUTS FOR THIS SIMULATION:

# Hib1: For IsHibernation in Phase 1 (stored in column 9 of 'SimulationInputData'):
Hib1=$(awk '//{print $9 }' SimulationInputData.txt)
Hib1_in_this_simulation=$(echo $Hib1 | awk '{print $'$SimID'}'); echo $Hib1_in_this_simulation

# Hib2: For IsHibernation in Phase 1 (stored in column 10 of 'SimulationInputData'):
Hib2=$(awk '//{print $10 }' SimulationInputData.txt)
Hib2_in_this_simulation=$(echo $Hib2 | awk '{print $'$SimID'}'); echo $Hib2_in_this_simulation

# Hib3: For IsHibernation in Phase 1 (stored in column 11 of 'SimulationInputData'):
Hib3=$(awk '//{print $11 }' SimulationInputData.txt)
Hib3_in_this_simulation=$(echo $Hib3 | awk '{print $'$SimID'}'); echo $Hib3_in_this_simulation

# Hib4: For IsHibernation in Phase 1 (stored in column 12 of 'SimulationInputData'):
Hib4=$(awk '//{print $12 }' SimulationInputData.txt)
Hib4_in_this_simulation=$(echo $Hib4 | awk '{print $'$SimID'}'); echo $Hib4_in_this_simulation

# Hib5: For IsHibernation in Phase 1 (stored in column 13 of 'SimulationInputData'):
Hib5=$(awk '//{print $13 }' SimulationInputData.txt)
Hib5_in_this_simulation=$(echo $Hib5 | awk '{print $'$SimID'}'); echo $Hib5_in_this_simulation

# Hib6: For IsHibernation in Phase 1 (stored in column 14 of 'SimulationInputData'):
Hib6=$(awk '//{print $14 }' SimulationInputData.txt)
Hib6_in_this_simulation=$(echo $Hib6 | awk '{print $'$SimID'}'); echo $Hib6_in_this_simulation

# --------------------------------------------------------------------------------------------
# CREATE A MATLAB SCRIPT FOR THIS SPECIFIC SIMULATED GRID CELL:

# Set working directory to the main MATLAB_Simulation folder:
cd /user/work/pk14885/MATLAB_Simulation

# Create a new MATLAB script:
cp Africa_model_HPC.m Africa_model_HPC_${SimID}.m

# Number the output file that will be produced by the MATLAB script:
sed -i "s/SimID/${SimID}/g" Africa_model_HPC_${SimID}.m

# --------------------------------------------------------------------------------------------
# INSERT THE SPECIFIC CLIMATE INPUT DATA INTO THE NEW MATLAB FILE:

# Insert the EnvState parameters into the MATLAB (.m) script file:
sed -i "s/ARRAYINPUT_ENVSTATE_PHASE1/${Env1_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ENVSTATE_PHASE2/${Env2_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ENVSTATE_PHASE3/${Env3_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ENVSTATE_PHASE4/${Env4_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ENVSTATE_PHASE5/${Env5_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ENVSTATE_PHASE6/${Env6_in_this_simulation}/g" Africa_model_HPC_${SimID}.m

# Insert the IsHibernation parameters into the MATLAB (.m) script file:
sed -i "s/ARRAYINPUT_ISHIBERNATION_PHASE1/${Hib1_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ISHIBERNATION_PHASE2/${Hib2_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ISHIBERNATION_PHASE3/${Hib3_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ISHIBERNATION_PHASE4/${Hib4_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ISHIBERNATION_PHASE5/${Hib5_in_this_simulation}/g" Africa_model_HPC_${SimID}.m
sed -i "s/ARRAYINPUT_ISHIBERNATION_PHASE6/${Hib6_in_this_simulation}/g" Africa_model_HPC_${SimID}.m

# --------------------------------------------------------------------------------------------
# INITIALISE THIS SIMULATION RUN:

# Load MATLAB on BluePebble:
module load apps/matlab/r2021a

# Run this simulation in MATLAB on BluePebble:
matlab -nodisplay -nodesktop -nosplash < Africa_model_HPC_${SimID}.m

# --------------------------------------------------------------------------------------------
# MOVE THE RESULTS TO THE RESULTS FOLDER:

# The MATLAB script produces a MAT file containing the output variables, called 'MATLAB_Output_${SimID}.m'. Move this to the results folder:

# Make a folder to store the outputs (if it does not already exist):
mkdir MATLAB_Outputs

# Move the output file into the folder:
mv MATLAB_Output_SimulationID_${SimID}.mat MATLAB_Outputs

# Now that this specific simulated grid cell has completed, delete its corresponding MATLAB script from BluePebble:
rm Africa_model_HPC_${SimID}.m
# --------------------------------------------------------------------------------------------
