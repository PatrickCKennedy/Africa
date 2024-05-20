% PK
% Empirical climate data for parameterising Belonogaster simulation:

% ----------------------------------------------------------------------------------------
% USING CRU (CLIMATIC RESEARCH UNIT) HIGH-RESOLUTION DATA ("CRU CL v1.1 1961-1990 Climatology (revised 2022/3)" at https://crudata.uea.ac.uk/cru/data/hrg/cru_cl_1.1/)

% OBTAIN PRECIPITATION DATA FROM CRU:
    source = "https://crudata.uea.ac.uk/cru/data/hrg/cru_cl_1.1/cru_cl_1.1.6190.pre.dat" % this is the precipitation data. Go to https://crudata.uea.ac.uk/cru/data/hrg/cru_cl_1.1/ for the other data (e.g., temperature).
    rain_data_downloaded = readtable(source);
    rain_data = table2array(rain_data_downloaded);
    
    % Set all ocean data (which comes as '-999' to 'NaN':
    rain_data(rain_data == -999) = NaN;

    % Longitude runs from 180 E to 180 W (there are 360 degrees), and latitude runs from 90 N to 90 S (there are 180 degrees).
    % The CRU data comes in units of 0.5 degrees latitude and longitude.
    % You can quickly plot the CRU data using: imagesc(test1)
    % To plot alongside the outline of Africa, use:
            figure(1);
                test4 = rain_data(1:360,:); % focus on the first month
                worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                longitude_axis = [-180:0.5:179.5] % These whole-world axis values are also used in the figures below.
                latitude_axis = [-90:0.5:89.5] % These whole-world axis values are also used in the figures below.
                pcolorm(latitude_axis,longitude_axis,test4)
                load coastlines % Using the 'Mapping' MATLAB add-in.
                plotm(coastlat,coastlon) % Using the 'Mapping' MATLAB add-in.

    % A brief animation of precipitation throughout the year:
    figure(2);
    worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
    load coastlines % Using the 'Mapping' MATLAB add-in.
    plotm(coastlat,coastlon) % Using the 'Mapping' MATLAB add-in.
    for month = 1:12
            figure(2);
                test4 = rain_data(((month-1)*360)+(1:360),:); 
                pcolorm(latitude_axis,longitude_axis,test4) % longitude and latitude axes are set above.
                colormap(flipud(pink))
                colorbar
    end
    
    % The data is currently in the high resolution provided by the CRU (0.5 degrees).
    % This is too high a resolution for the simulations: we want to average over larger areas.
    my_downscaling_factor = 5; % manually set the chosen downscaling factor for both precipitation and temperature data.
           
    % Downscaling step (spatially downscaling each month's precipitation data to the same new grid):
    precipitation_by_month_full_dataset = nan(360,size(rain_data,2),12); % make empty array to store monthly precipitation data for the downscaled grid (these will form the simulation inputs).
    precipitation_by_month_downscaled = nan(360/my_downscaling_factor,size(rain_data,2)/my_downscaling_factor,12); % make empty array to store monthly precipitation data for the downscaled grid (these will form the simulation inputs).
    for month = 1:12
        precipitation_by_month_full_dataset(:,:,month) = rain_data(((month-1)*360)+(1:360),:); 
        precipitation_by_month_downscaled(:,:,month) = nanimresize(precipitation_by_month_full_dataset(:,:,month) ,[360/my_downscaling_factor NaN]); 
    end

    % Note: the downscaling step uses the 'nanimresize' function developed by Chad Greene, and manually downloaded from the Add-On Explorer to the local path.
% -------------------------------------------------------------------------------------------
% MAPPING EMPIRICAL RAINFALL DATA TO 'HARSHNESS' IN THE SIMULATION MODEL:

% Choices have to be made about the appropriate mapping from the rainfall and temperature data to the 
% climate variables in the simulation model.

% For simplicity, we assume that higher precipitation represents increasingly benign climates:
            % Maximally benign states (point at and above which EnvState = 1):
            RainfallMeetsMaxBenign = 1000; % Manually choose the level of precipitation (mm in a month) at which the environment is assumed to be fully benign. e.g., we can set this to 1000, and any climates with 1000 or more mm in a month receive a '1' for EnvState in that month. Note that some parts of Africa receive extreme rainfall, much higher than 1000.
            % Maximally harsh states (point at and below which EnvState = 0):
            RainfallMeetsMaxHarsh = 40; % Manually choose the level of precipitation (mm in a month) at which the environment is assumed to be fully harsh. e.g., we can set this to 200, and any climates with 200 or below mm in a month receive a '0' for EnvState in that month.
            % We assume a linear relationship between harshness and rainfall between these two points.
            % The relationship is: (value_of_interest-RainfallMeetsMaxHarsh)/(RainfallMeetsMaxBenign-RainfallMeetsMaxHarsh);

% For the paper, we could write something like this:
% ALL P: In the wet humid zones of tropical West and Central Africa, Belonogaster are active year-round. By contrast, in the cold dry seasons (winters) of temperate South Africa, hopeful foundresses hibernate in hibernacula (crevices
% away from the parental nest), and all other wasps die. In parts of Africa with very hot dry seasons, the data on Belonogaster behaviour are extremely sparse. In Somalia, for instance, Pardi & 
% Piccioli (1981 [the fourth paper], p.140) report wasps as 'completely inactive' and in 'constant rest on the old nest' during 
% the intense dry season (implying a state of torpor). Similarly, we have observed completely inactive wasps on the remains of post-emergence nest at the end of the intense dry
% season on the margins of the Sahel in Far-North Cameroon (PK, pers. obs., Maroua). However, we have also found large and active brood-rearing nests during the dry season in Kenya (PK & DRR, pers. obs., Laikipia County),
% which implies that wasps avoid torpor except when there is extreme dryness. Accordingly, in simulations we have assumed obligatory torpor when 
% monthly rainfall falls below an extreme threshold (here, 40mm); immediately above 40mm, simulated environments are harsh but viable for brood-rearing.

% -------------------------------------------------------------------------------------------
% PLOT RAINFALL DATA ACROSS THE DOWNSCALED GRID CELLS FOR SIMULATION:

    % Plot the resulting downscaled rainfall data:
    figure(3);
    set(gcf,'Position',[100 100 500 500])
    worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
    downscaled_longitude_axis = [-180:(0.5*my_downscaling_factor):179.5]; % These whole-world axis values are also used in the figures below.
    downscaled_latitude_axis = [-90:(0.5*my_downscaling_factor):89.5]; % These whole-world axis values are also used in the figures below.
        for month = 1:12
        figure(3)
            %month = 6; % choose which month to plot (1->12).
            h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, precipitation_by_month_downscaled(:,:,month) )
                % Set any values in the sea to zero:
                my_mask = precipitation_by_month_downscaled(:,:,month) > -20;
                set(h,  'alphadata',my_mask, ...
                        'alphadatamapping','none',...
                        'facealpha','flat','edgealpha','flat',...
                        'edgecolor','none');
                load coastlines % Using the 'Mapping' MATLAB add-in.
                plotm(coastlat,coastlon,'k') % Using the 'Mapping' MATLAB add-in.
                %colormap(flipud(bone))
                %clim([0 4000]) % set the sea (which has values of -999) to white (if using a colormap that has white as the lowest value)
                %colormap(cool)
                load Patrick_white_cyan_purple; colormap(Patrick_white_cyan_purple) % use custom-made colormap (made with MATLAB's 'colormapeditor' and saved as 'Patrick_white_cyan_purple').
                clim([-20 RainfallMeetsMaxBenign]); % Note that rainfall goes much higher than 2000mm in a month in some parts of Africa
                mlabel off; % longitude labels
                plabel off; % latitude labels
                gridm off; % remove background latitude/longitude grid
                framem('FlineWidth',0.2,'FEdgeColor','white') % remove border around plot
                set(gcf,'color','w'); % set background to white
                
                % Note: The code below exports the rainfall data as an animated gif, using the 'gif' function created by Chad Greene, and manually downloaded to the local path via the MATLAB 'Add-On' manager.
                if month == 1
                    
                    a = colorbar;
                    a.Label.String = 'Monthly rainfall (mm)'; a.Label.Rotation = 270; a.Label.Position(1) = 3;
                    set(a,'position',[.25 .3 .02 .1]); % colourbar position and size
                
                    gif('my_rainfall_gif.gif','DelayTime',0.2)
                else
                    gif
                end
        end
        % To play the gif from MATLAB, use:
        web('my_rainfall_gif.gif')

% ------------------------------------------------------------------------------                
% TRANSLATE RAINFALL DATA INTO ENVSTATE VARIABLE FOR SIMULATION:

% First, average the rain data into 6 phases. The simulation involves 6 phases of the year (each is 2 months long). We therefore need to average over months in the rainfall data:
rainfall_phase_mean = nan(  size(precipitation_by_month_downscaled(:,:,1),1),   size(precipitation_by_month_downscaled(:,:,1),2), 6 );
    % Phase 1: Average over January and February:
    rainfall_phase_mean(:,:,1) = (precipitation_by_month_downscaled(:,:,1) + precipitation_by_month_downscaled(:,:,2))/2;
    % Phase 2: Average over March and April:
    rainfall_phase_mean(:,:,2) = (precipitation_by_month_downscaled(:,:,3) + precipitation_by_month_downscaled(:,:,4))/2;
    % Phase 3: Average over May and June:
    rainfall_phase_mean(:,:,3) = (precipitation_by_month_downscaled(:,:,5) + precipitation_by_month_downscaled(:,:,6))/2;
    % Phase 4: Average over July and August:
    rainfall_phase_mean(:,:,4) = (precipitation_by_month_downscaled(:,:,7) + precipitation_by_month_downscaled(:,:,8))/2;
    % Phase 5: Average over September and October:
    rainfall_phase_mean(:,:,5) = (precipitation_by_month_downscaled(:,:,9) + precipitation_by_month_downscaled(:,:,10))/2;
    % Phase 6: Average over November and December:
    rainfall_phase_mean(:,:,6) = (precipitation_by_month_downscaled(:,:,11) + precipitation_by_month_downscaled(:,:,12))/2;

% Second, apply the assumed transformation from rainfall into 'EnvState' 
EnvState_Grid_phase = (rainfall_phase_mean-RainfallMeetsMaxHarsh)/(RainfallMeetsMaxBenign-RainfallMeetsMaxHarsh); % (dimensions: longitude, latitude, and phase, as in 'rainfall_phase_mean').
EnvState_Grid_phase(rainfall_phase_mean <= RainfallMeetsMaxHarsh) = 0; % assumed maximally harsh states
EnvState_Grid_phase(rainfall_phase_mean >= RainfallMeetsMaxBenign) = 1; % assumed maximally benign states

% Plot the resulting downscaled EnvState data:
    figure(4);
    worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
    for repeat_visualisation = 1:10
        for Phase = 1:6
        figure(4); h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, EnvState_Grid_phase(:,:,Phase) )
                plotm(coastlat,coastlon,'k') % Using the 'Mapping' MATLAB add-in.
                load Patrick_white_cyan_purple; colormap(Patrick_white_cyan_purple) % use custom-made colormap (made with MATLAB's 'colormapeditor' and saved as 'Patrick_white_cyan_purple').
                clim([0 1]); colorbar; % Note that rainfall goes much higher than 2000mm in a month in some parts of Africa
                mlabel off; plabel on; gridm on; framem('FlineWidth',1,'FEdgeColor','black'); set(gcf,'color','w');
        end
    end

% Plot highlighting areas interpretted as EnvState = 0 due to low rainfall alone (not yet including areas that are EnvState = 0 due to low temperature):
% Plot the resulting downscaled EnvState data:
    figure(5);
    worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
    for repeat_visualisation = 1:10
        for Phase = 1:6
        figure(5); h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, double(EnvState_Grid_phase(:,:,Phase) == 0) )
                set(h,'alphadata',my_mask,'alphadatamapping','none','facealpha','flat','edgealpha','flat','edgecolor','none');
                plotm(coastlat,coastlon,'k') % Using the 'Mapping' MATLAB add-in.
                load Patrick_white_cyan_purple; colormap(Patrick_white_cyan_purple) % use custom-made colormap (made with MATLAB's 'colormapeditor' and saved as 'Patrick_white_cyan_purple').
                clim([0 1]); colorbar; % Note that rainfall goes much higher than 2000mm in a month in some parts of Africa
                mlabel off; plabel on; gridm on; framem('FlineWidth',1,'FEdgeColor','black'); set(gcf,'color','w');
        end
    end
% ------------------------------------------------------------------------------                
% TO IDENTIFY HIBERNATION ZONES, OBTAIN TEMPERATURE DATA FROM CRU (using the same dataset as for precipitation: Climatic Research Unit dataset "CRU CL v1.1 1961-1990 Climatology (revised 2022/3)")
    temperature_source = "https://crudata.uea.ac.uk/cru/data/hrg/cru_cl_1.1/cru_cl_1.1.6190.tmp.dat" % this is the TEMPERATURE data.
    temperature_data = readtable(temperature_source);
    temperature_data = table2array(temperature_data);

    % Set ocean data to 'NaN':
    temperature_data(temperature_data == -999) = NaN;

    % A brief animation of temperature throughout the year:
        figure;
        for month = 1:12
            temperature_focus_on_Africa = temperature_data(((month-1)*360)+(100:260),320:470);
            imagesc(temperature_focus_on_Africa); set(gca,'YDir','normal'); colormap(flipud(pink)); clim([0 300]); colorbar; pause(0.5); 
        end

    % What is the threshold for assuming that hibernation occurs?
    hibernation_temperature_threshold = 120; % Manually set assumed hibernation threshold to 12* C.
    
    % Identify zones below the assumed hibernation temperature theshold:
    temperature_focus_on_Africa(temperature_focus_on_Africa < -990) = 99999;
    imagesc(temperature_focus_on_Africa > hibernation_temperature_threshold)
    
    % A brief animation of areas that drop below the assumed hibernation threshold temperature throughout the year:
        for repeat_visualisation = 1:3
            for month = 1:12
            temperature_focus_on_Africa = temperature_data(((month-1)*360)+(100:260),320:470);
            % Identify zones below the assumed hibernation temperature theshold:
                temperature_focus_on_Africa(temperature_focus_on_Africa < -990) = 99999;
                areas_above_threshold = (temperature_focus_on_Africa > hibernation_temperature_threshold);            
            figure(1)
                imagesc(areas_above_threshold); set(gca,'YDir','normal'); pause(0.5)
            end
        end

    % Downscale the data to the same resolution as the precipitation data, so that every pixel corresponds exactly:
    temperature_by_month_full_dataset = nan(360,size(temperature_data,2),12); % make empty array to store monthly precipitation data for the downscaled grid (these will form the simulation inputs).
    temperature_by_month_downscaled = nan(360/my_downscaling_factor,size(temperature_data,2)/my_downscaling_factor,12); % make empty array to store monthly precipitation data for the downscaled grid (these will form the simulation inputs).
    for month = 1:12
        temperature_by_month_full_dataset(:,:,month) = temperature_data(((month-1)*360)+(1:360),:); 
        temperature_by_month_downscaled(:,:,month) = nanimresize(temperature_by_month_full_dataset(:,:,month) ,[360/my_downscaling_factor NaN]); 
    end
    % Note: as for rainfall, the temperature downscaling step uses the 'nanimresize' function developed by Chad Greene, and manually downloaded from the Add-On Explorer to the local path.

    % Plot the resulting downscaled temperature data to highlight areas below the 'hibernation_temperature_threshold' set above:
           for repeat_visualisation = 1:10
               for month = 1:12
                %month = 6; % choose which month to plot (1->12).
                figure(4);
                worldmap('Africa') % Using the 'Mapping' MATLAB add-in.
                %downscaled_longitude_axis is set above
                %downscaled_latitude_axis is set above
                h = pcolorm(downscaled_latitude_axis,downscaled_longitude_axis, temperature_by_month_downscaled(:,:,month))
                % Set any values in the sea to zero:
                my_mask = temperature_by_month_downscaled(:,:,month) < hibernation_temperature_threshold;
                set(h,  'alphadata',my_mask, ...
                        'alphadatamapping','none',...
                        'facealpha','flat','edgealpha','flat',...
                        'edgecolor','none');
                load coastlines % Using the 'Mapping' MATLAB add-in.
                plotm(coastlat,coastlon,'k') % Using the 'Mapping' MATLAB add-in.
                %colormap(flipud(bone))
                %clim([0 4000]) % set the sea (which has values of -999) to white (if using a colormap that has white as the lowest value)
                colormap(cool)
                clim([0 hibernation_temperature_threshold])
                colorbar
                mlabel off; % remove longitude labels
                plabel on; % latitude labels
                gridm on; % remove background latitude/longitude grid
                framem('FlineWidth',1,'FEdgeColor','black') % remove border around plot
                set(gcf,'color','w'); % set background to white
               end
           end

% ---------------------------------------------------------------------------------------------
% TRANSLATE TEMPERATURE DATA INTO ISHIBERNATION INPUTS FOR SIMULATION:

% Make hibernation 'yes/no' map:
IsHibernation_by_month_downscaled = temperature_by_month_downscaled < hibernation_temperature_threshold;

% First, average the rain data into 6 phases. The simulation involves 6 phases of the year (each is 2 months long). We therefore need to average over months in the rainfall data:
IsHibernation_by_phase = nan(  size(temperature_by_month_downscaled(:,:,1),1),   size(temperature_by_month_downscaled(:,:,1),2), 6 );
    % Phase 1: Hibernation in January and February:
    IsHibernation_by_phase(:,:,1) = (IsHibernation_by_month_downscaled(:,:,1) + IsHibernation_by_month_downscaled(:,:,2))/2;
    % Phase 2: Hibernation in March and April:
    IsHibernation_by_phase(:,:,2) = (IsHibernation_by_month_downscaled(:,:,3) + IsHibernation_by_month_downscaled(:,:,4))/2;
    % Phase 3: Hibernation in May and June:
    IsHibernation_by_phase(:,:,3) = (IsHibernation_by_month_downscaled(:,:,5) + IsHibernation_by_month_downscaled(:,:,6))/2;
    % Phase 4: Hibernation in July and August:
    IsHibernation_by_phase(:,:,4) = (IsHibernation_by_month_downscaled(:,:,7) + IsHibernation_by_month_downscaled(:,:,8))/2;
    % Phase 5: Hibernation in September and October:
    IsHibernation_by_phase(:,:,5) = (IsHibernation_by_month_downscaled(:,:,9) + IsHibernation_by_month_downscaled(:,:,10))/2;
    % Phase 6: Hibernation in November and December:
    IsHibernation_by_phase(:,:,6) = (IsHibernation_by_month_downscaled(:,:,11) + IsHibernation_by_month_downscaled(:,:,12))/2;

% Some phases now have a value of 0.5 (i.e., hibernation only occurs in one of the two months). Change these values to '1' (i.e., hibernation is binary for the phase as a whole in the simulation):
IsHibernation_by_phase = IsHibernation_by_phase > 0;

% Set all hibernating grid cells to EnvState=0 in the EnvState map:
EnvState_Grid_phase(IsHibernation_by_phase == 1) = 0;

% ---------------------------------------------------------------------------------------------
% IDENTIFY AND NUMBER THE FULL SET OF GRID CELLS TO SUBMIT FOR SIMULATION:

% First, exclude any area that is in the sea:
cells_to_simulate = ones(size(temperature_by_month_downscaled(:,:,1)));
cells_to_simulate(isnan(temperature_by_month_downscaled(:,:,1))) = NaN;
 
% First, exclude all world locations outside of sub-Saharan Africa:
        % Set all grid cells west of 30*W to 'NaN':
        cells_to_simulate(:,linspace(180,-180,720/my_downscaling_factor) > 30) = NaN;
        % Set all grid cells east of 60*E to 'NaN':
        cells_to_simulate(:,linspace(180,-180,720/my_downscaling_factor) < -60) = NaN;
        % Set all grid cells north of 15*N to 'NaN':
        cells_to_simulate(linspace(-90,90,360/my_downscaling_factor) > 15,:) = NaN;
        % Set all grid cells south of 40*S to 'NaN':
        cells_to_simulate(linspace(-90,90,360/my_downscaling_factor) < -40,:) = NaN;
        figure; imagesc(cells_to_simulate); set(gca,'YDir','normal');

% The total number of cells to simulate is then:
total_to_simulate = sum(sum(cells_to_simulate,'omitnan'))

% Extract the indices (location on the downscaled whole-world map) of each cell to simulate:    
idx = find(~isnan(cells_to_simulate));

% Give each one a simulation ID number:
SimulationNumber = (1:size(idx,1))';

% Initialise simulation inputs dataframe:
SimulationInputData = [SimulationNumber idx];

% Obtain the EnvState (precipitation) data for this phase in each grid cell:
        for Phase = 1:6      
           EnvStatesGrid = EnvState_Grid_phase(:,:,Phase);
           SimulationInputData = [SimulationInputData EnvStatesGrid(idx)];
        end
  
% Obtain the IsHibernation (temperature) data for this phase in each grid cell:
        for Phase = 1:6
            IsHibernationGrid = IsHibernation_by_phase(:,:,Phase);
            SimulationInputData = [SimulationInputData IsHibernationGrid(idx)];
        end

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

% Write the simulation input data to a CSV file ready for BluePebble:
%writematrix(SimulationInputData,'SimulationInputData.csv') 
writematrix(SimulationInputData,'SimulationInputData.txt','Delimiter','\t')

% Now upload the CSV file to HPC from a local Bash terminal, e.g.:
%  cd Documents
%  scp SimulationInputData.txt pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/MATLAB_Simulation/Input_data/

