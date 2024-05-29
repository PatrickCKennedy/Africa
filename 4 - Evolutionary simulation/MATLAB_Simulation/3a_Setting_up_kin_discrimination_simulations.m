% In this MATLAB script for the local computer, we generate inputs for 10 simulations: 5 in the Congo Basin and 5 in South Africa. 
% For each country, we run the 'Africa_model_HPC.m' simulation at 5 different levels of kin discrimination. The aim is to predict
% the relatedness that evolves purely by demographic processes when kin discrimination is progressively turned off.

% The input values for temperate South Africa:
        % We will use grid square 163, which is Pretoria.
        % First, run the 'Importing_climate_data_to_MATLAB.m' script, and then
        % find the Pretoria values using:
        PretoriaClimateData = SimulationInputData(163,:)

% The input values for tropical southern Cameroon:
        % We will use grid square 58, which is southern Cameroon east region.
        % First, run the 'Importing_climate_data_to_MATLAB.m' script, and then
        % find the Pretoria values using:
        SouthernCameroonClimateData = SimulationInputData(58,:)

% As a reminder, here is the structure of 'SimulationInputData':
  % SimulationInputData columns:
                % Column 1: Simulation ID number (in sequence starting at 1)
                % Column 2: Location on the downscaled world map of this grid cell (which we will subsequently use for plotting the results)
                % Column 3: EnvState in Phase 1
                % Column 4: EnvState in Phase 2
                % Column 5: EnvState in Phase 3
                % Column 6: EnvState in Phase 4
                % Column 7: EnvState in Phase 5
                % Column 8: EnvState in Phase 6
                % Column 9: IsHibernation in Phase 1
                % Column 10: IsHibernation in Phase 2
                % Column 11: IsHibernation in Phase 3
                % Column 12: IsHibernation in Phase 4
                % Column 13: IsHibernation in Phase 5
                % Column 14: IsHibernation in Phase 6

% To generate the simulation inputs for the 10 simulation runs, therefore, we use:
    % First 5 rows are South Africa; last 5 rows are southern Cameroon.
       [PretoriaClimateData;
        PretoriaClimateData;
        PretoriaClimateData;
        PretoriaClimateData;
        PretoriaClimateData;
        SouthernCameroonClimateData;
        SouthernCameroonClimateData;
        SouthernCameroonClimateData;
        SouthernCameroonClimateData;
        SouthernCameroonClimateData]

% Now 
