#!/bin/bash

#SBATCH --job-name=MATLAB_KinDiscrimination
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --time=2-00:00:00
#SBATCH --mem=6G
#SBATCH --account=BISC020282
#SBATCH --array 1-10

# NOTE: As soon as the 269 current Africa grid map simulations have finished, replace 'Africa_model_HPC.m' with the very slightly
# updated version here on GitHub, which has ARRAYINPUT_KIN_DISCRIM_VALUE. That will then be the new version used for all
# scripts. Then you can run this submission script to generate the kin discrimination plot.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# ARRAY JOB SUBMISSION SCRIPT FOR RUNNING THE SIMULATION AT DIFFERENT LEVELS OF KIN DISCRIMINATION
# This HPC submission script runs 'Africa_model_HPC.m' across 5 different levels of kin discrimination
# (0, 0.25, 0.5, 0.75, 1) in each of two climates (southern Cameroon and Pretoria), so 10 jobs in total. 
# The climate data that you need to supply for these two input climates are produced in the local computer MATLAB script
# '3a_Setting_up_kin_discrimination_simulations.m', which produces the text file 
# 'KinDiscriminationSimulationInputData.txt'. Upload this to the 
# MATLAB_Simulation/KinDiscriminationSimulations/Input_data on BluePebble, by running the following
# command in the local computer's terminal:
            ## scp /Users/pk14885/Documents/KinDiscriminationSimulationInputData.txt pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/MATLAB_Simulation/KinDiscriminationSimulations/Input_data/

# The script below runs the standard MATLAB script ('Africa_model_HPC.sh'), which is identical to that used
# in the grid map of Africa array job.

# -------------------------------------------------------------------
# START THE LOOP THROUGH THE DIFFERENT MATLAB SIMULATIONS:

# Each simulation corresponds to a single geographical grid cell:
SimID=${SLURM_ARRAY_TASK_ID}

# --------------------------------------------------------------------------------------------
# READ IN THE ENVSTATE INPUTS FOR EACH SIMULATION IN THE LOOP:

# Set working directory to the folder on BluePebble containing the input data (in the textfile 'KinDiscriminationSimulationInputData.txt', generated already in MATLAB on the local computer and uploaded to the cluster):
cd /user/work/pk14885/MATLAB_Simulation/KinDiscriminationSimulations/Input_data

# Env1: For EnvState in Phase 1 (stored in column 3 of 'KinDiscriminationSimulationInputData'):
Env1=$(awk '//{print $3 }' SimulationInputData.txt)
Env1_in_this_simulation=$(echo $Env1 | awk '{print $'$SimID'}'); echo $Env1_in_this_simulation

# Env2: For EnvState in Phase 2 (stored in column 4 of 'KinDiscriminationSimulationInputData'):
Env2=$(awk '//{print $4 }' SimulationInputData.txt)
Env2_in_this_simulation=$(echo $Env2 | awk '{print $'$SimID'}'); echo $Env2_in_this_simulation

# Env3: For EnvState in Phase 2 (stored in column 5 of 'KinDiscriminationSimulationInputData'):
Env3=$(awk '//{print $5 }' SimulationInputData.txt)
Env3_in_this_simulation=$(echo $Env3 | awk '{print $'$SimID'}'); echo $Env3_in_this_simulation

# Env4: For EnvState in Phase 2 (stored in column 6 of 'KinDiscriminationSimulationInputData'):
Env4=$(awk '//{print $6 }' SimulationInputData.txt)
Env4_in_this_simulation=$(echo $Env4 | awk '{print $'$SimID'}'); echo $Env4_in_this_simulation

# Env5: For EnvState in Phase 2 (stored in column 7 of 'KinDiscriminationSimulationInputData'):
Env5=$(awk '//{print $7 }' SimulationInputData.txt)
Env5_in_this_simulation=$(echo $Env5 | awk '{print $'$SimID'}'); echo $Env5_in_this_simulation

# Env6: For EnvState in Phase 2 (stored in column 8 of 'KinDiscriminationSimulationInputData'):
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
# READ IN THE LEVEL OF KIN DISCRIMINATION FOR THIS SIMULATION:

# KinDiscrimValue: stored in column 15 of 'SimulationInputData':
KinDiscrimValue=$(awk '//{print $15 }' SimulationInputData.txt)
KinDiscrimValue_in_this_simulation=$(echo $KinDiscrimValue | awk '{print $'$SimID'}'); echo $KinDiscrimValue_in_this_simulation

# --------------------------------------------------------------------------------------------
# CREATE A MATLAB SCRIPT FOR THIS SPECIFIC SIMULATED GRID CELL:

# Set working directory to the main MATLAB_Simulation/KinDiscriminationSimulations folder:
cd /user/work/pk14885/MATLAB_Simulation/KinDiscriminationSimulations

# Create a new MATLAB script, using the standard 'Africa_model_HPC.m' script that we have already uploaded:
cp /user/work/pk14885/MATLAB_Simulation/Africa_model_HPC.m Africa_model_HPC_${SimID}.m

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

# Insert the level of kin discrimination parameter into the MATLAB (.m) script file:
sed -i "s/ARRAYINPUT_KIN_DISCRIM_VALUE/${KinDiscrimValue_in_this_simulation}/g" Africa_model_HPC_${SimID}.m

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

# Now that this specific simulation run has completed, delete its corresponding MATLAB script from BluePebble:
rm Africa_model_HPC_${SimID}.m
# --------------------------------------------------------------------------------------------
