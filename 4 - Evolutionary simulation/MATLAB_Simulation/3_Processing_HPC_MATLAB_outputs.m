% PK
% PROCESSING GEOGRAPHICAL SIMULATION OUTPUTS FROM HPC

% Once the simulation has run across all the geographical grid cells of interest on the HPC cluster, download 
% the data to the local computer's desktop using this command in the terminal:
%           scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/MATLAB_Simulation/MATLAB_Outputs/ Desktop

% Run the 'Importing_climate_data_to_MATLAB' script again at this point, so that the Workspace contains the 'SimulationInputData' array (and the other information needed for plotting the map, such as 'downscaled_longitude_axis', etc.).
% Column 2 of 'SimulationInputData' contains the location of each grid cell on the world map.
% 'SimulationInputData' and 'Outputs' have corresponding rows (i.e., row 14 in each array contains the information for simulation ID 14, and so on).

% Find the number of simulations in the 'SimulationInputData' file (i.e., the number of rows).
% You can find this using:  size(SimulationInputData,1);
NumberOfSimulationsInInputData = size(SimulationInputData,1);

% The simulation output vector ('this_Simulation_Outputs_Vector') generated in each run of the model contains the most important output summary variables.
% It has ___38____ columns (more can be added to record other variables).
% To see what each column contains, look at the end of the simulation ('Africa_model_HPC.m').
% Set up an empty array to record these outputs:
NumberOfColumnsInSimulationOutputsVectors = 38;
Outputs = nan(NumberOfSimulationsInInputData,NumberOfColumnsInSimulationOutputsVectors+2);

% Extract these summary variables from the MAT files:
for z=1:NumberOfSimulationsInInputData
    filename = ['/Users/pk14885/Downloads/MATLAB_Simulation/MATLAB_Output_SimulationID_"', num2str(z),'"'];
    try
        load(filename);
        Outputs(z,1:NumberOfColumnsInSimulationOutputsVectors) = this_Simulation_Outputs_Vector;

        % Calculate weighted average of within-phase relatednesses during this simulation run (weighted by number of foundress groups) to find average annual relatedness:
                    % Focus on the final 20% of phases:
                    temp_table = [relatedness_tracker foundations_Radius relatedness_tracker.*foundations_Radius];
                    % Remove 'NaN' values (i.e., where there are no foundations):
                    temp_table = temp_table(~isnan(temp_table(:,3)),:);
                    temp_table = temp_table(round(0.8*size(temp_table,1)):size(temp_table,1),:);
                    temp_table = temp_table(temp_table(:,1)<1,:); % Remove small number of phases in which regression for relatedness produces greater than 1 (typically due to only one or very few foundations in the population) 
                    temp_table = temp_table(temp_table(:,1)>-1,:); % As above, but for those in which regression is less than -1.  
                    this_Simulation_weighted_relatedness = sum(temp_table(:,3))/sum(temp_table(:,2));
                    % Add this as column 39 to the outputs:
                    Outputs(z,39) = this_Simulation_weighted_relatedness;
                    % Note: To plot the relationship between number of foundress nests and within-phase relatedness for this 
                    % simulation run, use:      scatter(temp_table(:,2),temp_table(:,1), 2,'MarkerFaceColor','red','MarkerFaceAlpha',1,'MarkerEdgeAlpha',.0)      

        % Find average new worker body condition (AvNWBC) in each phase for this simulation:
                    AvNWBC_P1 = mean(NewWorkerAverageCondition(YearlyPhasesList == 1));
                    AvNWBC_P2 = mean(NewWorkerAverageCondition(YearlyPhasesList == 2));
                    AvNWBC_P3 = mean(NewWorkerAverageCondition(YearlyPhasesList == 3));
                    AvNWBC_P4 = mean(NewWorkerAverageCondition(YearlyPhasesList == 4));
                    AvNWBC_P5 = mean(NewWorkerAverageCondition(YearlyPhasesList == 5));
                    AvNWBC_P6 = mean(NewWorkerAverageCondition(YearlyPhasesList == 6));
                    AverageNewWorkerBodyConditionAcrossTheYear = [AvNWBC_P1 AvNWBC_P2 AvNWBC_P3 AvNWBC_P4 AvNWBC_P5 AvNWBC_P6];
                    AverageNewWorkerBodyConditionAcrossTheYear = AverageNewWorkerBodyConditionAcrossTheYear(~isnan(AverageNewWorkerBodyConditionAcrossTheYear)); % drop any phases where no workers are being produced at all, which are just 'NaN'.
                    % Calculate coefficient of variation in new worker body condition over the year:
                    AverageNewWorkerBodyCondition_SeasonalCV = std(AverageNewWorkerBodyConditionAcrossTheYear)/mean(AverageNewWorkerBodyConditionAcrossTheYear);
                    % Add this as column 40 to the outputs:
                    Outputs(z,40) = AverageNewWorkerBodyCondition_SeasonalCV;         

    catch
    end%%sister_nest_tracker
    clearvars -except NumberOfColumnsInSimulationOutputsVectors Outputs z SimulationInputData NumberOfSimulationsInInputData EnvStatesGrid downscaled_longitude_axis downscaled_latitude_axis coastlat coastlon
    z
end

% Save and export the output to a MAT file so that they can be rapidly opened later without needing to re-run the loop above:        
save('MATLAB_Simulation_Outputs_Collated.mat')

% ---------------------------------------------------------------------------------------------
% PLOTTING ANNUAL MEAN RELATEDNESS OUTPUT:

% Set up empty array to hold the output data on the world map grid:
AnnualMeanRelatednessGrid = nan(size(EnvStatesGrid));
% Fill in the positions with the WEIGHTED annual mean relatedness output (column 39 of 'Outputs'):
AnnualMeanRelatednessGrid(SimulationInputData(:,2)) = Outputs(:,39);

% Plot annual mean relatedness predictions using the weighted average calculated above :
                figure(101); worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, AnnualMeanRelatednessGrid)
                load coastlines; plotm(coastlat,coastlon,'k');
                colormap(cool); mlabel off; plabel off; gridm off; framem('FlineWidth',0.2,'FEdgeColor','white'); set(gcf,'color','w');
                    a = colorbar; a.Label.String = 'Relatedness'; a.Label.Rotation = 270; a.Label.Position(1) = 3; a.Label.FontSize=16; a.FontSize = 16
                    set(a,'position',[.25 .25 .02 .2]); % colourbar position and size

% Plot annual mean relatedness predictions using previous method:
% Set up empty array to hold the output data on the world map grid:
OLD_AnnualMeanRelatednessGrid = nan(size(EnvStatesGrid));
% Fill in the positions with the annual mean relatedness output (column 2 of 'Outputs'):
OLD_AnnualMeanRelatednessGrid(SimulationInputData(:,2)) = Outputs(:,2);
                figure(102); worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, OLD_AnnualMeanRelatednessGrid)
                load coastlines; plotm(coastlat,coastlon,'k');
                colormap(cool); mlabel off; plabel off; gridm off; framem('FlineWidth',0.2,'FEdgeColor','white'); set(gcf,'color','w');
                    a = colorbar; a.Label.String = 'Relatedness'; a.Label.Rotation = 270; a.Label.Position(1) = 3; a.Label.FontSize=16; a.FontSize = 16
                    set(a,'position',[.25 .25 .02 .2]); % colourbar position and size

% Scatter plot of annual mean relatedness against seasonality:
    % Define rainfall seasonality as the variance in rainfall over the 6 phases in rainfall:
    rainfall_seasonal_variance = var(SimulationInputData(:,3:8)')';
    rainfall_seasonal_variance = var(SimulationInputData(:,3:8)')';
    rainfall_mean = mean(SimulationInputData(:,3:8)')';
    rainfall_coefficients_of_variation = sqrt(rainfall_seasonal_variance)./rainfall_mean;

% To colour-code scatter by habitat type (year-round, includes hibernation, or includes torpor):
hibernation_phases_count = double(sum(SimulationInputData(:,9:14)')' > 0);
unlivable_phases_count = double(sum((SimulationInputData(:,3:8) == 0)')' > 0);
% Give grid cell a '1' if it involves hibernation:
habitat_type = hibernation_phases_count;
% Give grid cell a '2' if it involves torpor (unlivable state without hibernation):
habitat_type(unlivable_phases_count == 1 & hibernation_phases_count == 0) = 2;
% Give grid cell a '3' if it does not involve hibernation or torpor:
habitat_type(unlivable_phases_count == 0 & hibernation_phases_count == 0) = 3;


    figure(123);
    pointsize = 15;
    scatter(rainfall_coefficients_of_variation, Outputs(:,39), pointsize,habitat_type,'filled', 'MarkerFaceAlpha',.9,'MarkerEdgeAlpha',1); set(gcf,'color','w');
    xlabel('Rainfall seasonality (CoV)');
    ylabel('Predicted evolved relatedness'); ylim([0 1]);
    groupColors = [0 0 0; 1 0.7 0.0; 0.9 0.9 0.9]; colormap(groupColors)

% ---------------------------------------------------------------------------------------------
% PLOTTING PROBABILITY THAT DOMINANT IS A SISTER:

     mean(sister_nest_tracker,'Omitnan')

% ---------------------------------------------------------------------------------------------
% PLOTTING SOCIAL SYNCHRONY:

% Set up empty array to hold the output data on the world map grid:
SocialSynchronyGrid = nan(size(EnvStatesGrid));
% Fill in the positions with the variance in the number of foundress nests each season (columns 15 to 20 of 'Outputs'):
        % But first, 'Nan' values in 'Outputs' need to be interpretted as zeros, as they are arising due to hibernation or torpor states:
        Outputs_copy = Outputs; % make a copy of 'Outputs' to use.
        Outputs_copy(isnan(Outputs_copy)) = 0; % set all 'NaN' to zero.
        CoefficientOfVariationInNestFoundationPhases = sqrt(var(Outputs_copy,0,2))./mean(Outputs_copy,2);
SocialSynchronyGrid(SimulationInputData(:,2)) = CoefficientOfVariationInNestFoundationPhases 

% Plot social synchrony:
                figure(5); worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, SocialSynchronyGrid)
                load coastlines; plotm(coastlat,coastlon,'k');
                colormap(cool); mlabel off; plabel off; gridm off; framem('FlineWidth',0.2,'FEdgeColor','white'); set(gcf,'color','w');
                    a = colorbar; 
                    clim([2.5 5]); 
                    a.Label.String = 'Social synchrony'; a.Label.Rotation = 270; a.Label.Position(1) = 4; a.Label.FontSize=16; a.FontSize = 16
                    set(a,'position',[.25 .25 .02 .2]); cbarrow % colourbar position and size


% Scatter plot of annual mean relatedness against seasonality:
    % Define rainfall seasonality as the variance in rainfall over the 6 phases in rainfall:
    rainfall_seasonal_variance = var(SimulationInputData(:,3:8)')';
    rainfall_seasonal_variance = var(SimulationInputData(:,3:8)')';
    rainfall_mean = mean(SimulationInputData(:,3:8)')';
    rainfall_coefficients_of_variation = sqrt(rainfall_seasonal_variance)./rainfall_mean;

% To colour-code scatter by habitat type (year-round, includes hibernation, or includes torpor):
hibernation_phases_count = double(sum(SimulationInputData(:,9:14)')' > 0);
unlivable_phases_count = double(sum((SimulationInputData(:,3:8) == 0)')' > 0);
% Give grid cell a '1' if it involves hibernation:
habitat_type = hibernation_phases_count;
% Give grid cell a '2' if it involves torpor (unlivable state without hibernation):
habitat_type(unlivable_phases_count == 1 & hibernation_phases_count == 0) = 2;
% Give grid cell a '3' if it does not involve hibernation or torpor:
habitat_type(unlivable_phases_count == 0 & hibernation_phases_count == 0) = 3;


    figure(123); subplot(1,2,1)
    pointsize = 15;
    scatter(rainfall_mean, CoefficientOfVariationInNestFoundationPhases, pointsize,habitat_type,'filled', 'MarkerFaceAlpha',.9,'MarkerEdgeAlpha',1); set(gcf,'color','w');
    xlabel('Mean annual rainfall');
    ylabel('Social synchrony (CoV)'); 
    groupColors = [0 0 0; 1 0.7 0.0; 0.9 0.9 0.9]; colormap(groupColors)
    axis square

    figure(123); subplot(1,2,2)
    pointsize = 15;
    scatter(rainfall_coefficients_of_variation, CoefficientOfVariationInNestFoundationPhases, pointsize,habitat_type,'filled', 'MarkerFaceAlpha',.9,'MarkerEdgeAlpha',1); set(gcf,'color','w');
    xlabel('Rainfall seasonality (CoV)');
    ylabel('Social synchrony (CoV)'); 
    groupColors = [0 0 0; 1 0.7 0.0; 0.9 0.9 0.9]; colormap(groupColors)
    axis square

% ---------------------------------------------------------------------------------------------
% PLOT BETWEEN-SEASON (I.E. BETWEEN-PHASE) VARIATION IN NEW WORKER BODY CONDITION:

figure(98); scatter(YearlyPhasesList,NewWorkerAverageCondition)
figure(99); scatter(YearlyPhasesList,NewHopefulLeadFounderAverageCondition)


% Set up empty array to hold the output data on the world map grid:
NewWorkerBodyConditionCV_Grid = nan(size(EnvStatesGrid));
NewWorkerBodyConditionCV_Grid(SimulationInputData(:,2)) = Outputs(:,40); 

% Plot coefficient of variation in new worker body condition between phases in which workers are produced:
                figure(50); worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, NewWorkerBodyConditionCV_Grid)
                load coastlines; plotm(coastlat,coastlon,'k');
                colormap(cool); mlabel off; plabel off; gridm off; framem('FlineWidth',0.2,'FEdgeColor','white'); set(gcf,'color','w');
                    a = colorbar; 
                    clim([0.2 0.6]); 
                    a.Label.String = 'Seasonal variation'; a.Label.Rotation = 270; a.Label.Position(1) = 4; a.Label.FontSize=16; a.FontSize = 16
                    set(a,'position',[.25 .25 .02 .2]); cbarrow % colourbar position and size



% ---------------------------------------------------------------------------------------------
% PLOTTING NUMBER OF FOUNDATIONS BY PHASE:

% Set up empty array to hold the output data on the world map grid:
foundations_density_Grid = nan(size(EnvStatesGrid));
% Fill in the positions with the annual mean relatedness output (column 1 of 'SimulationInputData'):

for Phase = 1:6
    foundations_density_Grid(SimulationInputData(:,2)) = Outputs(:,15+Phase-1);
                figure(200); worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, foundations_density_Grid)
                load coastlines; plotm(coastlat,coastlon,'k');
                colormap(flipud(bone))
                clim([0 3]); mlabel off; plabel off; gridm off; framem('FlineWidth',0.2,'FEdgeColor','white'); set(gcf,'color','w');
                htext = textm(-30,0,num2str(Phase));
 % Note: The code below exports the rainfall data as an animated gif, using the 'gif' function created by Chad Greene, and manually downloaded to the local path via the MATLAB 'Add-On' manager.
                if Phase == 1
                    a = colorbar;
                    a.Label.String = 'Foundress nest density'; a.Label.Rotation = 270; a.Label.Position(1) = 3;
                    set(a,'position',[.25 .3 .02 .1]); % colourbar position and size
                    gif('my_foundation_density.gif','DelayTime',0.3)
                else
                    gif
                end
end

 % To play the gif from MATLAB, use:
        web('my_foundation_density.gif')

% ---------------------------------------------------------------------------------------------
% PLOTTING LOWER CONDITION NEW WASP CHOICES:

% Set up empty array to hold the output data on the world map grid:
LowerCondition_Grid = nan(size(EnvStatesGrid));

for Phase = 1:6
    LowerCondition_Grid(SimulationInputData(:,2)) = Outputs(:,9+Phase-1);
                figure(400); worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, LowerCondition_Grid)
                load coastlines; plotm(coastlat,coastlon,'k');
                colormap(flipud(bone))
                clim([0 1]); mlabel off; plabel off; gridm off; framem('FlineWidth',0.2,'FEdgeColor','white'); set(gcf,'color','w');
                htext = textm(-30,0,num2str(Phase));
 % Note: The code below exports the rainfall data as an animated gif, using the 'gif' function created by Chad Greene, and manually downloaded to the local path via the MATLAB 'Add-On' manager.
                if Phase == 1
                    a = colorbar;
                    a.Label.String = ''; a.Label.Rotation = 270; a.Label.Position(1) = 3;
                    set(a,'position',[.25 .3 .02 .1]); % colourbar position and size
                    gif('lower_condition.gif','DelayTime',0.3)
                else
                    gif
                end
end

 % To play the gif from MATLAB, use:
        web('lower_condition.gif')

% ---------------------------------------------------------------------------------------------
% PLOTTING HIGHER CONDITION NEW WASP CHOICES:

% Set up empty array to hold the output data on the world map grid:
HigherCondition_Grid = nan(size(EnvStatesGrid));

for Phase = 1:6
    HigherCondition_Grid(SimulationInputData(:,2)) = Outputs(:,3+Phase-1);
                figure(500); worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, HigherCondition_Grid)
                load coastlines; plotm(coastlat,coastlon,'k');
                colormap(flipud(bone))
                clim([0 1]); mlabel off; plabel off; gridm off; framem('FlineWidth',0.2,'FEdgeColor','white'); set(gcf,'color','w');
                htext = textm(-30,0,num2str(Phase));
 % Note: The code below exports the rainfall data as an animated gif, using the 'gif' function created by Chad Greene, and manually downloaded to the local path via the MATLAB 'Add-On' manager.
                if Phase == 1
                    a = colorbar;
                    a.Label.String = ''; a.Label.Rotation = 270; a.Label.Position(1) = 3;
                    set(a,'position',[.25 .3 .02 .1]); % colourbar position and size
                    gif('higher_condition.gif','DelayTime',0.3)
                else
                    gif
                end
end

 % To play the gif from MATLAB, use:
        web('higher_condition.gif')

% ---------------------------------------------------------------------------------------------
% PLOTTING DIFFERENCE IN STRATEGY BETWEEN HIGHER AND LOWER CONDITION WASPS:

% Set up empty array to hold the output data on the world map grid:
ConditionDifference_Grid = nan(size(EnvStatesGrid));

for Phase = 1:6
    condition_difference_list(:,Phase) =  Outputs(:,3+Phase-1) - Outputs(:,9+Phase-1);
    ConditionDifference_Grid(SimulationInputData(:,2)) = Outputs(:,3+Phase-1) - Outputs(:,9+Phase-1);
                figure(400); worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, ConditionDifference_Grid)
                load coastlines; plotm(coastlat,coastlon,'k');
                colormap(flipud(bone))
                clim([0 0.5]); mlabel off; plabel off; gridm off; framem('FlineWidth',0.2,'FEdgeColor','white'); set(gcf,'color','w');
                htext = textm(-30,0,num2str(Phase));
 % Note: The code below exports the rainfall data as an animated gif, using the 'gif' function created by Chad Greene, and manually downloaded to the local path via the MATLAB 'Add-On' manager.
                if Phase == 1
                    a = colorbar;
                    a.Label.String = ''; a.Label.Rotation = 270; a.Label.Position(1) = 3;
                    set(a,'position',[.25 .3 .02 .1]); % colourbar position and size
                    gif('condition_difference.gif','DelayTime',0.3)
                else
                    gif
                end
end

 % To play the gif from MATLAB, use:
        web('condition_difference.gif')

  figure(234);
    pointsize = 15;
    scatter(rainfall_coefficients_of_variation, mean(condition_difference_list','Omitnan'), pointsize,habitat_type,'filled', 'MarkerFaceAlpha',.9,'MarkerEdgeAlpha',1); set(gcf,'color','w');
    xlabel('Rainfall seasonality (CoV)');
    ylabel('Relative condition importance'); ylim([0 1]);
    groupColors = [0 0 0; 1 0.7 0.0; 0.9 0.9 0.9]; colormap(groupColors)


% ------------------------------------------------------------------------------------------------------------------------------
% EXTRACTING CIRCULAR LIFECYCLE DIAGRAMS FOR SPECIFIC COORDINATES IN AFRICA:

% Manually choose which simulation ID (one coordinate pixel's data) to plot:
chosen_SimID_to_plot_specifically = 44; %e.g., 163 and 44

% See where this is in Africa (and revise the number in the line above until you find exactly the right place):
    EmptyGrid = nan(size(EnvStatesGrid));
    EmptyGrid(SimulationInputData(chosen_SimID_to_plot_specifically,2)) = 1;
    figure(666); subplot(1,4,4); worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
    h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, EmptyGrid)
    load coastlines; plotm(coastlat,coastlon,'k');
    colormap(hot); mlabel off; plabel off; gridm off; framem('FlineWidth',0.2,'FEdgeColor','white'); set(gcf,'color','w');
                    
% Extract the data for this point in Africa:
filename = ['/Users/pk14885/Desktop/MATLAB_Outputs/MATLAB_Output_SimulationID_', num2str(chosen_SimID_to_plot_specifically)];
load(filename);

        figure(666)
        subplot(1,4,1) % PLOT OF NUMBER OF MEAN SURVIVING FOUNDRESS NESTS PER SITE:
             % First, shade the different sectors according to harshness (harsher is darker):
                my_transparency_baseline = 0;       my_face_color = [0.5,0.5,0.5];      my_radius_max = 100;
                Jan_to_Mar_theta = deg2rad(repelem(360,my_radius_max)); polarhistogram(Jan_to_Mar_theta,1,'BinLimits',deg2rad([330 390]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(1));
                    hold on
                Mar_to_May_theta = deg2rad(repelem(30,my_radius_max)); polarhistogram(Mar_to_May_theta,1,'BinLimits',deg2rad([30 90]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(2));
                May_to_Jul_theta = deg2rad(repelem(90,my_radius_max)); polarhistogram(May_to_Jul_theta,1,'BinLimits',deg2rad([90 150]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(3));
                Jul_to_Sep_theta = deg2rad(repelem(150,my_radius_max)); polarhistogram(Jul_to_Sep_theta,1,'BinLimits',deg2rad([150 210]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(4));
                Sep_to_Nov_theta = deg2rad(repelem(210,my_radius_max)); polarhistogram(Sep_to_Nov_theta,1,'BinLimits',deg2rad([210 270]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(5));
                Nov_to_Dec_theta = deg2rad(repelem(270,my_radius_max)); polarhistogram(Nov_to_Dec_theta,1,'BinLimits',deg2rad([270 330]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(6));
                % Smooth interpolated curve:
                    set(gcf,'color','w'); angle_increments = ((-(1.0472)/2):1.0472:((Phase-1)*1.0472))'; theta_new = linspace(0, max(angle_increments), 360*(Phase/6)); theta_new = (0:0.05:((Phase-1)*1.0472))'; r_new1 = interp1(angle_increments(1:Phase), foundations_Radius(1:Phase), theta_new, 'linear', 'extrap');
                        polarplot(theta_new,r_new1, Color =[0,1,1, 0.1]); % The last value is the transparency.
                        thetaticks(30:60:390); thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'}); rlim([0 max(foundations_Radius((Phase-6):Phase))]);
                        ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                        ax.RAxisLocation = -30; set(gca, 'GridColor', "black", 'GridAlpha', 1); ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    % Add point markers:
                       th = angle_increments((end-5):end); r = foundations_Radius((end-5):end); polarscatter(th,r,'filled','MarkerFaceColor',[0,1,1])
                    rtickangle(60)
                    hold off
               
        subplot(1,4,2) % Average condition of new workers, new hopeful founders, and new instant cooperators:
                % First, shade the different sectors according to harshness (harsher is darker):
                    my_transparency_baseline = 0; my_face_color = [0.5,0.5,0.5]; my_radius_max = 100;
                    Jan_to_Mar_theta = deg2rad(repelem(360,my_radius_max)); polarhistogram(Jan_to_Mar_theta,1,'BinLimits',deg2rad([330 390]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(1) == 0));
                        hold on
                    Mar_to_May_theta = deg2rad(repelem(30,my_radius_max)); polarhistogram(Mar_to_May_theta,1,'BinLimits',deg2rad([30 90]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(2) == 0));
                    May_to_Jul_theta = deg2rad(repelem(90,my_radius_max)); polarhistogram(May_to_Jul_theta,1,'BinLimits',deg2rad([90 150]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(3) == 0));
                    Jul_to_Sep_theta = deg2rad(repelem(150,my_radius_max)); polarhistogram(Jul_to_Sep_theta,1,'BinLimits',deg2rad([150 210]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(4) == 0));
                    Sep_to_Nov_theta = deg2rad(repelem(210,my_radius_max)); polarhistogram(Sep_to_Nov_theta,1,'BinLimits',deg2rad([210 270]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(5) == 0));
                    Nov_to_Dec_theta = deg2rad(repelem(270,my_radius_max)); polarhistogram(Nov_to_Dec_theta,1,'BinLimits',deg2rad([270 330]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(6) == 0));
                angle_increments = ((-(1.0472)/2):1.0472:((Phase-1)*1.0472))'; theta_new = linspace(0, max(angle_increments), 360*(Phase/6)); theta_new = (0:0.05:((Phase-1)*1.0472))';   
                    hold on; r_new_higher = interp1(angle_increments(1:Phase), NewWorkerAverageCondition(1:Phase), theta_new, 'linear', 'extrap');
                        polarplot(theta_new,r_new_higher, Color =[0,0,0, 0.01]); % The last value is the transparency.
                        rlim([0 max(NewHopefulLeadFounderAverageCondition(1:Phase))])
                    % Add point markers:
                       th = angle_increments((end-5):end); r = NewWorkerAverageCondition((end-5):end); polarscatter(th,r,'filled','MarkerFaceColor',[0,0,0])
                    r_new_higher = interp1(angle_increments(1:Phase), NewHopefulLeadFounderAverageCondition(1:Phase), theta_new, 'linear', 'extrap');
                        polarplot(theta_new,r_new_higher, Color =[1, 165/255, 0, 0.01]); % The last value is the transparency.
                    % Add point markers:
                       th = angle_increments((end-5):end); r = NewHopefulLeadFounderAverageCondition((end-5):end); polarscatter(th,r,'filled','MarkerFaceColor',[1, 165/255, 0])
                    r_new_higher = interp1(angle_increments(1:Phase), NewInstantCooperatorAverageCondition(1:Phase), theta_new, 'linear', 'extrap');
                        polarplot(theta_new,r_new_higher, Color =[0,1,1, 0.01]); thetaticks(30:60:390); thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'}); ax = gca; ax.RAxisLocation = -30; set(gca, 'GridColor', "black", 'GridAlpha', 1); ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    % Add point markers:
                       th = angle_increments((end-5):end); r = NewInstantCooperatorAverageCondition((end-5):end); polarscatter(th,r,'filled','MarkerFaceColor',[0,1,1])
                    rticks([0 round(max(cat(1,NewHopefulLeadFounderAverageCondition,NewInstantCooperatorAverageCondition, NewWorkerAverageCondition)),1)])
                    rtickangle(60)
                    hold off
    
            subplot(1,4,3) % Probability of becoming a foundress for high and low condition new wasps:
                % First, shade the different sectors according to harshness (harsher is darker):
                    my_transparency_baseline = 0;       my_face_color = [0.5,0.5,0.5];      my_radius_max = 100;
                    Jan_to_Mar_theta = deg2rad(repelem(360,my_radius_max)); polarhistogram(Jan_to_Mar_theta,1,'BinLimits',deg2rad([330 390]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(1) == 0));
                        hold on
                    Mar_to_May_theta = deg2rad(repelem(30,my_radius_max)); polarhistogram(Mar_to_May_theta,1,'BinLimits',deg2rad([30 90]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(2) == 0));
                    May_to_Jul_theta = deg2rad(repelem(90,my_radius_max)); polarhistogram(May_to_Jul_theta,1,'BinLimits',deg2rad([90 150]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(3) == 0));
                    Jul_to_Sep_theta = deg2rad(repelem(150,my_radius_max)); polarhistogram(Jul_to_Sep_theta,1,'BinLimits',deg2rad([150 210]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(4) == 0));
                    Sep_to_Nov_theta = deg2rad(repelem(210,my_radius_max)); polarhistogram(Sep_to_Nov_theta,1,'BinLimits',deg2rad([210 270]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(5) == 0));
                    Nov_to_Dec_theta = deg2rad(repelem(270,my_radius_max)); polarhistogram(Nov_to_Dec_theta,1,'BinLimits',deg2rad([270 330]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(6) == 0));
                    r_new_higher = interp1(angle_increments(1:Phase), HigherConditionFoundressPhenotype(1:Phase), theta_new, 'linear', 'extrap');
                        polarplot(theta_new,r_new_higher, Color =[0,1,1, 0.05]); ax = gca; ax.RAxisLocation = -30; set(gca, 'GridColor', "black", 'GridAlpha', 1); ax.RGrid = "off"; rlim([0 1])
                    % Add point markers:
                       th = angle_increments((end-5):end); r = HigherConditionFoundressPhenotype((end-5):end); polarscatter(th,r,'filled','MarkerFaceColor',[0,1,1])
                    r_new_higher = interp1(angle_increments(1:Phase), LowerConditionFoundressPhenotype(1:Phase), theta_new, 'linear', 'extrap');
                        polarplot(theta_new,r_new_higher, Color =[1,0,1, 0.05]); % The last value is the transparency.
                       % Add point markers:
                       th = angle_increments((end-5):end); r = LowerConditionFoundressPhenotype((end-5):end); polarscatter(th,r,'filled','MarkerFaceColor',[1,0,1])
                    thetaticks(30:60:390); thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'}); ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30; set(gca, 'GridColor', "black", 'GridAlpha', 1); ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    rticks([0 0.5 1.0])
                    rtickangle(60)
                    rlim([0 1]);
                    % Plot the final points:
                    hold off
                















