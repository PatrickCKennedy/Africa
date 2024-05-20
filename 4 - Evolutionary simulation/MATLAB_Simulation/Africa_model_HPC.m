
% PREPARED FOR HPC CLUSTER

clear all
% SYNCHRONICITY DETERMINES KINSHIP AND COOPERATION
% PARAMETER SETUP SECTION:
%%
% -----------------------------------------------------------------------------------------------    
% SETTING THE SIMULATION INPUTS:
% Divide the year into 6 2-month periods (m), corresponding to phases in which a focal individual may develop from an egg to adult. For each period, evolve two traits: y_m: Prob of developing as a foundress if you have high absolute body condition. x_m: Prob of developing as a foundress if you have low absolute body condition. The year is fully flexible: you can set the 6 period to whichever climate factors you would like to explore. There is a single variable - "EnvState" - that defines the period. In practice, this could be linked to the WorldClim variables by projecting it as a simple function of temperature and rainfall, based on what we know about the distribution of Belonogaster in Africa (e.g., the region of the 2-dimensional temp-rainfall plot corresponding to the South African winter would be "harsh". The harshness of each period is given by the variable "EnvState". It varies between 0 and 1. At 0, the environment is unsurvivable. At 1, it is maximally benign. The scale is arbitrary, and affects various aspects of fitness (e.g., nest-founding success for foundresses of different body-conditions, stochastic failure rates, landscape fragmentation, body condition achieved during development, etc.):

% Use either the HPC parallel option (many climate zones, either directly from the map grid or as part of a systematic variation of parameters) or the local computer (single climate zone) options.
% Comment out the option that you are not using.

% IF USING HPC ARRAYS (REPLICATING IN PARALLEL ACROSS MULTIPLE CLIMATE LOCATIONS):
    
    % Print the SimID number to the Slurm output file if running on HPC:
    ThisSimulationNumber = SimID

    % Receive EnvState values from Slurm input if running on HPC:
    EnvState = nan(1,6);
    EnvState(1) = ARRAYINPUT_ENVSTATE_PHASE1;
    EnvState(2) = ARRAYINPUT_ENVSTATE_PHASE2;
    EnvState(3) = ARRAYINPUT_ENVSTATE_PHASE3;
    EnvState(4) = ARRAYINPUT_ENVSTATE_PHASE4;
    EnvState(5) = ARRAYINPUT_ENVSTATE_PHASE5;
    EnvState(6) = ARRAYINPUT_ENVSTATE_PHASE6;

    % Print EnvState:
    EnvState

    % Receive IsHibernation values from Slurm input if running on HPC:
    IsHibernation = nan(1,6);
    IsHibernation(1) = ARRAYINPUT_ISHIBERNATION_PHASE1;
    IsHibernation(2) = ARRAYINPUT_ISHIBERNATION_PHASE2;
    IsHibernation(3) = ARRAYINPUT_ISHIBERNATION_PHASE3;
    IsHibernation(4) = ARRAYINPUT_ISHIBERNATION_PHASE4;
    IsHibernation(5) = ARRAYINPUT_ISHIBERNATION_PHASE5;
    IsHibernation(6) = ARRAYINPUT_ISHIBERNATION_PHASE6;

    % Print IsHibernation:
    IsHibernation

% IF RUNNING ON THE LOCAL COMPUTER (A SINGLE CLIMATE LOCATION), ENTER THE ENVSTATE AND ISHIBERNATION VALUES FOR THIS SPECIFIC CLIMATE:
    %EnvState    =      [1.0;       0.7;        0.0;        0.0;        1.0;        1.0];
    % Harshness:        Jan-Feb     Mar-Apr     May-June    July-Aug    Sept-Oct    Nov-Dec
% Are any of the '0' states hibernation (as opposed to torpor)? Set to '1' for all hibernations:
    %IsHibernation =    [0           0           1           1           0           0];

% Note: if running on the local computer, comment out the "quit" line at the end of the whole script.

% -----------------------------------------------------------------------------------------------    
% EVERYTHING BELOW CAN NOW BE RUN ON EITHER HPC OR A LOCAL COMPUTER:
% -----------------------------------------------------------------------------------------------    

% Choose whether or not to plot and show figures (useful if running on local computer, not if on HPC):
FiguresOnOrOff = 0; % set '1' to plot figures, '0' otherwise.

% Sex ratio is not explicit in the model: instead, a common sex ratio is assumed across reproductives, and a reproductive's male output scales in proportion to her female output once the nest is mature (non-foundress). Foundress nests are assumed to produce daughters only. The resulting offspring develop during the period, and become fully-fledged adults at the end of the period. They can then participate in adult social interactions in the next period (and the next, and so on, if they survive that far). All males enter a pure lottery competition. Females gain a certain body condition, depending on (1) adult helping effort during their development, (2) environmental state during their development.
% How many offspring are produced? We assume that the number of offspring depends on the maturity (age) of the nest. In its first period (foundress phase), it produces g_1 offspring. In its second period (matrifilial phase 1), it produces g_2 offspring. In its third period (matrifilial phase 2), it produces g_3 offspring. In its fourth period, g_4. And so on. The probability of a nest surviving for that long becomes ever lower with time. Nest death within a period p is a function of harshness during that period; if a nest dies, all of the offspring currently in development die. We also assume that all adults on the nest die, rather than refounding.
% What does the landscape look like? The landscape consists of a circular lattice with n sites (potential demes). Sites can be empty: in harsh landscapes, many sites will be uninhabited.
    nSites = 1000; % Set the number of sites on the circular lattice.
% How big is each site? The carrying capacity (number of nests that a site can sustain) is determined by the harshness of the environment during the current phase. We assume that it varies between 0 and ___ nests:
    max_NestCarryingCapacity = 30; % Therefore, the carrying capacity in any given phase is set by Harshness*MaxCarryingCapacity. A site does not have to fill its theoretical carrying capacity. For instance, there may only be 20 foundresses surviving to spring on a deme, despite the theoretical carrying capacity in the spring being 200. In a harsh environment, however, a certain fraction of sites are inhospitable (carrying capacity goes to zero), generating a fragmented distribution across the landscape. The proportion of sites that are hospitable is directly given by the harshness. When harshness is 0, no sites are hospitable. When harshness is 1, all sites are hospitable. Sites are either hospitable or inhospitable; if sites are hospitable, they have a carrying capacity determined by harshness.
    max_Wasps_Per_Colony = 60; % The maximum number of wasps that can exist on a colony at any given time. Therefore, the carrying capacity in terms of the maximum theoretical number of wasps who can exist in a deme at any one time is: (max_Wasps_Per_Colony)*(Harshness_P)*(max_NestCarryingCapacity)
    nWasps = (max_Wasps_Per_Colony)*(max_NestCarryingCapacity); % The maximum theoretical number of wasps who can exist in a single deme.
% How does reproduction work? Reproduction is haplodiploid, with single-mating. We assume female philopatry and male-biased dispersal. Specifically, we assume that males disperse to the two neighbouring demes. If the two neighbouring demes are uninhabited, males mate on their home deme (which may generate inbreeding in harsh landscapes). We assume that mating occurs at the start of each phase.
% Time clicks forward in phases. There are 6 phases in a year. Here, choose the number of years to run the model for:
TotalYears = 50; TotalPhases = TotalYears*6; YearlyPhasesList = repmat(1:6,1,TotalYears)';
% Give each wasp slot an ID number within its site. Within each site, the numbers start at 1 and go up to 'nWasps'. Not every wasp slot is necessarily occupied by a wasp. When a wasp dies and is replaced, a new wasp receives the ID number. The ID numbers are therefore effectively individual slots available in the site (deme).
Wasps = NaN(90,nWasps,nSites); % For each wasp slot, there are 40 columns of wasp-slot-specific info (you can add more). This is only for females. The first 3 columns are the index position of the wasp slot. The other columns are  info about the current occupant. If no wasp currently occupies the wasp slot, those columns will just show 'NaN':
% Setting up the fixed first three columns of 'Wasps' (wasp-slot indexes):             
   for Site = 1:nSites
                Wasps(1,:,Site) = 1:nWasps;                                                         % Row 1: Wasp-slot ID numbers
                Wasps(2,:,Site) = repelem(1:max_NestCarryingCapacity,1,max_Wasps_Per_Colony)';      % Row 2: Nest ID numbers for each wasp-slot
                Wasps(3,:,Site) = repmat((1:max_Wasps_Per_Colony)',max_NestCarryingCapacity,1);     % Row 3: Wasp-slot dominance statuses. For each nest, whoever is in position 1 in the dominance status column is the queen. The rest of the statuses are not used in the model.
   end
InstantCooperators = zeros(90,nWasps,nSites); % there can be a theoretical max of 'nWasps' as instantly-cooperative foundresses (if everyone tries this strategy), so there are nWasps rows in this table.
% RedirectedHelpingPool = zeros(nWasps,90,nSites); % there can be a theoretical max of 'nWasps' in the redirected helping pool. USES UP A LOT OF MEMORY...
max_subordinate_group_size = 2; % Set the maximum number of subordinate foundresses manually.
SitesList = 1:nSites;
g1 = 5; % surviving adult female offspring produced over each 2-month phase for a foundress (phase 1) nest
g2 = 20; % surviving adult female offspring produced over each 2-month phase for an early mature (phase 2) nest
g3 = 30; % surviving adult female offspring produced over each 2-month phase for a fully mature (phase 3) nest
g4 = 70; % surviving adult female offspring produced over each 2-month phase for a terminal (phase 4) nest
g5 = 70;
% The relative helping value of instant cooperator subordinates versus subordinates who are redirected helpers (i.e., this determines the OPPORTUNITY COST in helping effort you can provide that arises from trying to be a lead founder). 
death_rate = 0.05; % Probability with which each individual non-queen wasp dies each phase.
% ----------------------------------------------------------------------------
% CHOOSE HOW MUCH TO SWITCH ON FOUNDRESS KIN DISCRIMINATION:

% Foundress kin discrimination means that subordinates automatically join sister dominants if one is available (i.e., if there is a slot available on a nest with a sister as dominant).
% This can be via kin recognition (CHCs) or natal philopatry within the site.
% The strength of foundress kin discrimination varies from 0 (absent) to 1 (complete), and can be set here:
StrengthOfKinDiscrimination = 0; % set the probability with which foundresses automatically associate through kin discrimination.
% Foundress who do not associate through kin discrimination join foundress nests at random within the site.

% The model should be run at different levels of kin discrimination to reveal the extent to which kin discrimination is required to maintain high kinship across different climatic contexts.
% ----------------------------------------------------------------------------
% CHOOSE THE OPPORTUNITY FOR REDIRECTED HELPING:

% The opportunity for redirected helping is set by the user (between 0 and 1, inclusive):
RedirectedHelpingOpportunity = 0.5; % set the probability that a failed lead foundress has the opportunity to become a redirected helper.
% When '1', attempting to build your own nest and failing does not carry an opportunity cost in terms of lost opportunities to be a subordinate (and therefore no chance to help kin, etc.).
% When '0', a failed lead foundress has no opportunity to join a nest as a subordinate.                    

% ----------------------------------------------------------------------------
% SETTING UP THE STARTING ALLELES IN THE POPULATION:
 
% OPTION 1: INITIALISE A UNIFORM DISTRIBUTION OF ALLELE VALUES IN THE POPULATION:
            Wasps(4:15,:,:) = 0.1*randi(10,size(Wasps(4:15,:,:))); % TRAITS y AND x (Social strategy: worker or foundress). y: If above-average body condition. x: If below-average body condition.
            Wasps(16:27,:,:) = 0.1*randi(10,size(Wasps(16:27,:,:)));
            Wasps(35:46,:,:) = 0.1*randi(10,size(Wasps(35:46,:,:))); % TRAITS k AND z (Cooperativeness of foundresses: willingness to instantly join a dominant as a subordinate, without ever attempting to build your own nest). k: If above-average body condition. z: If below-average body condition.
            Wasps(47:58,:,:) = 0.1*randi(10,size(Wasps(47:58,:,:)));
% The mates for new queens who found nest in the first generation:
            all_males = ones(24,nWasps*nSites);
            all_males(1:6,:) = 0.1*randi(10,size(all_males(1:6,:,:)));                  
            all_males(7:12,:) = 0.1*randi(10,size(all_males(7:12,:,:))); 
            all_males(13:18,:) = 0.1*randi(10,size(all_males(13:18,:,:))); 
            all_males(19:24,:) = 0.1*randi(10,size(all_males(19:24,:,:))); 
% Set up starting male mates' values for the first generation:
                % For existing queens:
                    Wasps(64:69,:,:) = 0.1*randi(10,size(Wasps(64:69,:,:)));                                          % HAVE TEMPORARILY ADDED +0.1 TO THESE VALUES SO CAN KEEP TRACK OF THEM MOVING THROUGH THE TABLES. BUT SET BACK TO THE STARTING TRAIT VALUES WHEN THE SCRIPT IS READY TO RUN.
                    Wasps(70:75,:,:) = 0.1*randi(10,size(Wasps(70:75,:,:))); 
                    Wasps(76:81,:,:) = 0.1*randi(10,size(Wasps(76:81,:,:))); 
                    Wasps(82:87,:,:) = 0.1*randi(10,size(Wasps(82:87,:,:))); 
               
% OPTION 2: INITIALISE AS A MONOMORPHIC POPULATION FOR SPECIFIED ALLELE VALUES:
        % STARTING TRAIT VALUES:
        % Manually choose the starting trait values:
            %y_Starting_Trait_Values = 0.9; 
            %x_Starting_Trait_Values = 0.9; 
            %k_Starting_Trait_Values = 0.5; 
            %z_Starting_Trait_Values = 0.5; 

            %Wasps(4:15,:,:) = y_Starting_Trait_Values; % TRAITS y AND x (Social strategy: worker or foundress). y: If above-average body condition. x: If below-average body condition.
            %Wasps(16:27,:,:) = x_Starting_Trait_Values;
            %Wasps(35:46,:,:) = k_Starting_Trait_Values; % TRAITS k AND z (Cooperativeness of foundresses: willingness to instantly join a dominant as a subordinate, without ever attempting to build your own nest). k: If above-average body condition. z: If below-average body condition.
            %Wasps(47:58,:,:) = z_Starting_Trait_Values;
            
        % Set up starting male mates' values for the first generation:
                % For existing queens:
                    %Wasps(64:69,:,:) = y_Starting_Trait_Values + 0.1;                                           % HAVE TEMPORARILY ADDED +0.1 TO THESE VALUES SO CAN KEEP TRACK OF THEM MOVING THROUGH THE TABLES. BUT SET BACK TO THE STARTING TRAIT VALUES WHEN THE SCRIPT IS READY TO RUN.
                    %Wasps(70:75,:,:) = x_Starting_Trait_Values + 0.1; 
                    %Wasps(76:81,:,:) = k_Starting_Trait_Values + 0.1; 
                    %Wasps(82:87,:,:) = z_Starting_Trait_Values + 0.1; 
                % The mates for new queens who found nest in the first generation:
                    %all_males = ones(24,nWasps*nSites);
                    %all_males(1:6,:) = all_males(1:6,:)*y_Starting_Trait_Values + 0.1;                  % HAVE TEMPORARILY ADDED +0.1 TO THESE VALUES SO CAN KEEP TRACK OF THEM MOVING THROUGH THE TABLES. BUT SET BACK TO THE STARTING TRAIT VALUES WHEN THE SCRIPT IS READY TO RUN.
                    %all_males(7:12,:) = all_males(7:12,:)*x_Starting_Trait_Values + 0.1;
                    %all_males(13:18,:) = all_males(13:18,:)*k_Starting_Trait_Values + 0.1;
                    %all_males(19:24,:) = all_males(19:24,:)*z_Starting_Trait_Values + 0.1;

% ------------------------------

        % Biological characteristics of each wasp:
        Wasps(28,:,:) = rand(size(Wasps(28,:,:)));          % Initialise body conditions randomly in the first generation only.
        %starting_ages = ceil(rand(nWasps,1)*4); 
        for Site = 1:nSites
            Wasps(30,:,Site) = 1;                          % Row 30: wasp age (number of phases, starting at 1). For this first phase in the simulation, randomly drawn from 1, 2, 3, or 4.
        end
               
        % Make sure that no queens in the starting phase are in age 1 (which would not make sense): 
        % Use logical indexing to find all instances of a specific value in a specific column of 'Wasps':
        % Here you specify the inputs of interest:
        idx = find(Wasps(3,:,:) == 1);                      % Find all queens.
        % Set the age for all queens to '2', '3', or '4' for this starting phase:
        Wasps(30,idx) = randi([2 4],size(idx));

         % For setting up the starting phase, we simulate some vacancies from the previous phase, to allow space for new foundresses. We therefore eliminate three nests from the population:
        for Site = 1:nSites
            Wasps(4:end,Wasps(2,:,Site) == 1,Site) = NaN;  % eliminate the nest in spot 1
            Wasps(4:end,Wasps(2,:,Site) == 2,Site) = NaN;  % eliminate the nest in spot 2
            Wasps(4:end,Wasps(2,:,Site) == 3,Site) = NaN;  % eliminate the nest in spot 3
        end % end loop through sites.
        
% ----------------------------------------------------------------------------
% Sanity checkpoints:
% To ensure that no problems arise, we can track different 'sanity checkpoints' in the model. Each sanity check has its own column. The value should be '1' for each of them if the model passess the sanity check. Each row is a phase.
SanityCheckOnOrOff = 1; % Set to '1' if you want to run sanity checks during the model. Set to '0' to turn off sanity checks.
    % 'SanityCheckpoint' Column 1: Verifies process in random allocation of subordinate foundresses to foundations. (Checks that all of the columns extracted from 'Foundations' are column 7 or greater.)

if SanityCheckOnOrOff == 1
     SanityCheckpoint = nan(TotalPhases,1);
end % end setting up sanity checkpoint record.
 
% Foundresses have a choice: cooperate (VOLUNTARY HELPING) or nest alone. If you nest alone, you can be joined by cooperators as subordinates. However, your nest may fail,
% especially if you do not receive any cooperators. If your nest fails, you can join a successful dominant as a subordinate (REDIRECTED HELPING).
% ----------------------------------------------------------------------------
% SET UP ARRAYS FOR TRACKING VALUES THROUGH TIME:
FoundressPhenotype = nan(TotalPhases,1);  % 'FoundressPhenotype' tracks the proportion of newly-adult wasps (their phase 1) would are choosing to become foundresses rather than workers.
PleometrosisPhenotype = nan(TotalPhases,1); % 'PleometrosisPhenotype' tracks the proportion of foundresses who choose to be instant cooperators, rather than attempting to be lead founders.
foundations_Radius = nan(TotalPhases,1);
mean_group_size = nan(TotalPhases,1);
median_body_condition = nan(TotalPhases,1);
NewWorkerAverageCondition = nan(TotalPhases,1);
NewHopefulLeadFounderAverageCondition = nan(TotalPhases,1);
NewInstantCooperatorAverageCondition = nan(TotalPhases,1);
HigherConditionFoundressPhenotype = nan(TotalPhases,1);
LowerConditionFoundressPhenotype = nan(TotalPhases,1);
empty_sites_tracker = nan(TotalPhases,1);
relatedness_data = [NaN NaN];
relatedness_tracker = nan(TotalPhases,1);
whole_year_relatedness_tracker = nan(TotalYears,1);
sister_nest_tracker = nan(TotalPhases,1); % records the proportion of subordinates who come from the same parental nest as the dominant (i.e., are sisters)
HopefulFounderCountTracker = nan(TotalPhases,1); % records the number of hopeful lead founders each phase.
InstantCooperatorCountTracker = nan(TotalPhases,1); % records the number of instant cooperators each phase.
RedirectedHelperCountTracker = nan(TotalPhases,1); % records the number of hopeful lead founders who eventually become subordinates on a different nest as a redirected helper.
%%

%% OPEN THIS COMMENT SECTION FOR A LIST OF WHICH TRAITS/INFORMATION ARE IN WHICH ROWS OF THE MASTER 'WASPS' ARRAY:

    % Row 1                 Wasp-slot ID within the site (i.e., column number in 'Wasps')
    % Row 2                 Colony ID within the site
    % Row 3                 Wasp-slot's dominance position within the colony
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    % Row 4         y1      Maternal allele                 The 'y' traits are the probability of choosing to be a foundress if you have higher body condition
    % Row 5         y1          Paternal allele
    % Row 6         y2      Maternal allele
    % Row 7         y2          Paternal allele
    % Row 8         y3      Maternal allele
    % Row 9         y3          Paternal allele
    % Row 10        y4      Maternal allele
    % Row 11        y4          Paternal allele
    % Row 12        y5      Maternal allele
    % Row 13        y5          Paternal allele
    % Row 14        y6      Maternal allele
    % Row 15        y6          Paternal allele
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    % Row 16        x1      Maternal allele                 The 'x' traits are the probability of choosing to be a foundress if you have lower body condition
    % Row 17        x1          Paternal allele
    % Row 18        x2      Maternal allele
    % Row 19        x2          Paternal allele
    % Row 20        x3      Maternal allele
    % Row 21        x3          Paternal allele
    % Row 22        x4      Maternal allele
    % Row 23        x4          Paternal allele
    % Row 24        x5      Maternal allele
    % Row 25        x5          Paternal allele
    % Row 26        x6      Maternal allele
    % Row 27        x6          Paternal allele
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    % Row 28                Absolute body condition
    % Row 29                Relative body condition
    % Row 30                Wasp age (number of phases)
    % Row 31                Individual's mean genetic value for y (depends on the current phase)
    % Row 32                Individual's mean genetic value for x (depends on the current phase)
    % Row 33                Foundress ('1') or worker ('0') phenotype
    % Row 34                
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    % Row 35        k1      Maternal allele
    % Row 36        k1          Paternal allele
    % Row 37        k2      Maternal allele
    % Row 38        k2          Paternal allele
    % Row 39        k3      Maternal allele
    % Row 40        k3          Paternal allele
    % Row 41        k4      Maternal allele
    % Row 42        k4          Paternal allele
    % Row 43        k5      Maternal allele
    % Row 44        k5          Paternal allele
    % Row 45        k6      Maternal allele
    % Row 46        k6          Paternal allele
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    % Row 47        z1      Maternal allele
    % Row 48        z1          Paternal allele
    % Row 49        z2      Maternal allele
    % Row 50        z2          Paternal allele
    % Row 51        z3      Maternal allele
    % Row 52        z3          Paternal allele
    % Row 53        z4      Maternal allele
    % Row 54        z4          Paternal allele
    % Row 55        z5      Maternal allele
    % Row 56        z5          Paternal allele
    % Row 57        z6      Maternal allele
    % Row 58        z6          Paternal allele
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    % Row 59                Individual's mean genetic value for k (depends on the current phase)
    % Row 60                Individual's mean genetic value for z (depends on the current phase)
    % Row 61                Pleometrosis phenotype
    % Row 62            
    % Row 63
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    % Row 64        y1      Allele in queen's haploid male mate
    % Row 65        y2      Allele in queen's haploid male mate
    % Row 66        y3      Allele in queen's haploid male mate
    % Row 67        y4      Allele in queen's haploid male mate
    % Row 68        y5      Allele in queen's haploid male mate
    % Row 69        y6      Allele in queen's haploid male mate
    % Row 70        x1      Allele in queen's haploid male mate
    % Row 71        x2      Allele in queen's haploid male mate
    % Row 72        x3      Allele in queen's haploid male mate
    % Row 73        x4      Allele in queen's haploid male mate
    % Row 74        x5      Allele in queen's haploid male mate
    % Row 75        x6      Allele in queen's haploid male mate
    % Row 76        k1      Allele in queen's haploid male mate
    % Row 77        k2      Allele in queen's haploid male mate
    % Row 78        k3      Allele in queen's haploid male mate
    % Row 79        k4      Allele in queen's haploid male mate
    % Row 80        k5      Allele in queen's haploid male mate
    % Row 81        k6      Allele in queen's haploid male mate
    % Row 82        z1      Allele in queen's haploid male mate
    % Row 83        z2      Allele in queen's haploid male mate
    % Row 84        z3      Allele in queen's haploid male mate
    % Row 85        z4      Allele in queen's haploid male mate
    % Row 86        z5      Allele in queen's haploid male mate
    % Row 87        z6      Allele in queen's haploid male mate
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    % Row 88                ID number of new foundress nest (unique in the whole population), for lead founders
    % Row 89                Individual wasp survival ('1' if surviving this phase, '0' if scheduled to die)
    % Row 90                Total female offspring produced by this queen

%%

% Overlapping generations
% Haplodiploidy
% Circular lattice
% Environmental quality

% Save the true EnvStates (this is used to restore the EnvStates after the initialisation phase):
true_EnvStates = EnvState;
tic; % start timer
% ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
for Phase = 1:TotalPhases
        Phase
        PhaseOfYear = YearlyPhasesList(Phase); % The current seasonal phase of the year (numbered 1 to 6).

        % In initialisation year only: for climates whose Phase1 climate is EnvState=0 (unlivable without hibernation or torpor), we temporarily adjust EnvState to a low number (0.1) for the initialisation year only, to enable smooth initialisation of the simulation. In all other years, EnvState in phase 1 is then 0:
        if Phase == 1 && EnvState(PhaseOfYear) == 0
            EnvState(1) = 0.1;
        else 
            EnvState = true_EnvStates;
        end

        % At the start of each year, set up a vector for storing whole-year relatedness data for the year:
        if PhaseOfYear == 1
            whole_year_relatedness_data = [NaN NaN];
        end
                                                
        %%    
        % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        % ALLELES AND PHENOTYPES FOR ALL WASPS IN THE POPULATION:
        disp(['Current Phase: ',num2str(Phase),'. Current section: (1) Reviewing alleles and phenotypes for all wasps in the population'])
        %tic
        %%                       
                        % Which rows' traits are expressed in the current phase?
                        if PhaseOfYear == 1
                            y_maternal_allele_row = 4; x_maternal_allele_row = 16; k_maternal_allele_row = 35; z_maternal_allele_row = 47; % i.e., if it is phase 1 of the year, look to column 4 of the 'Wasps' table
                        elseif PhaseOfYear == 2
                            y_maternal_allele_row = 6; x_maternal_allele_row = 18; k_maternal_allele_row = 37; z_maternal_allele_row = 49; 
                        elseif PhaseOfYear == 3
                            y_maternal_allele_row = 8; x_maternal_allele_row = 20; k_maternal_allele_row = 39; z_maternal_allele_row = 51; 
                        elseif PhaseOfYear == 4
                            y_maternal_allele_row = 10; x_maternal_allele_row = 22; k_maternal_allele_row = 41; z_maternal_allele_row = 53; 
                        elseif PhaseOfYear == 5
                            y_maternal_allele_row = 12; x_maternal_allele_row = 24; k_maternal_allele_row = 43; z_maternal_allele_row = 55; 
                        elseif PhaseOfYear == 6
                            y_maternal_allele_row = 14; x_maternal_allele_row = 16; k_maternal_allele_row = 45; z_maternal_allele_row = 57; 
                        end % end of checking through phases of the year.
                        % In each case, the paternal alleles are the next row:
                            y_paternal_allele_row = y_maternal_allele_row + 1; 
                            x_paternal_allele_row = x_maternal_allele_row + 1;  
                            k_paternal_allele_row = k_maternal_allele_row + 1; 
                            z_paternal_allele_row = z_maternal_allele_row + 1;                    
                        % Column 4              y1 Maternal allele              Value inherited from previous phase
                        % ...                   ...                             ...   
                        % Column 27             x6 Paternal allele              Value inherited from previous phase 
                        % Column 28             Absolute body condition         Value inherited from the previous phase
                                                                                    
                                                                                % BODY CONDITION NEEDS TO BE UPDATED TO DEPEND ON ENVSTATE AND HELPING EFFORT EXPERIENCED DURING YOUR DEVELOPMENT
                                                                                
                        % Column 29             Whether body condition is above decision threshold to use trait y
                                                                                % The 'decision_threshold' is the threshold for which wasps have information (i.e., they know whether they are above or below this body condition threshold).
                                                                                % You can set the decision threshold to be a fixed value, or you can make it relative (e.g., wasps can assess whether they are above or below the average body condition in their newly-emerged cohort):
                                                                                idx = find( Wasps(30,:,:) == 1) ; % find all newly-emerged wasps (i.e., wasps in their first adult phase)
                                                                                    decision_threshold = mean(Wasps(28,idx)); 
                                                                                Wasps(29,idx) = Wasps(28,idx) > decision_threshold;

                                                                                if FiguresOnOrOff == 1
                                                                                    figure(1)
                                                                                    subplot(4,4,3)
                                                                                    hist(Wasps(28,idx))
                                                                                end
                        % Column 30             Wasp age (number of phases)     Value inherited from previous phase (it was incremented by 1 at the end of the previous phase)
                        % Column 31             Mean genetic value for y        This depends on the phase of year:
                                                                                idx = find( ~isnan(Wasps(4,:,:)) ); % find all existing wasps in the population
                                                                                    Wasps(31,idx) = (Wasps(y_maternal_allele_row,idx) + Wasps(y_paternal_allele_row,idx))/2;
                        % Column 32             Mean genetic value for x        Also depends on the phase of year: 
                                                                                % Using the same line as above: idx = find( ~isnan(Wasps(4,:,:)) ); % find all existing wasps in the population
                                                                                    Wasps(32,idx) = (Wasps(x_maternal_allele_row,idx) + Wasps(x_paternal_allele_row,idx))/2;
                        % Column 33             Lifetime foundress or worker phenotype   Determined here:                            % So, will each wasp be a foundress or a worker? It depends on their mean genetic values (above). Whether we express y or x in turn depends on the wasp's body condition (column 28). If body condition is above-average, y is expressed. If below-average, x is expressed. The average body condition among ALL WASPS in the site (we might later want to revise this just to be among all new wasps in the site). Each new (first phase of adult life) wasp's actual expression of y (foundress or not) is in column 33:
                                                                                %random_value = rand(1,nWasps);
                                                                                %Wasps(33,:,:) = (Wasps(30,:,:) == 1).*((Wasps(29,:,:).*(Wasps(31,:,:) > random_value)) + ((1-Wasps(29,:,:)).*(Wasps(32,:,:) > random_value))); % Column 33: Foundress or worker? '1' if choosing to be a foundress. Wasps only get to make this decision at the start of their adult life. If you choose to become a foundress, you are now entered into the pool of potential foundresses for this phase.                                           
                                    
                                                                                idx = find(Wasps(30,:,:) == 1 & Wasps(29,:,:) == 1); % find all newly-emerged wasps (their first phase) who have a '1' in row 29 (i.e., are above the decision threshold for condition)
                                                                                     random_value = rand(1,size(idx,1));
                                                                                Wasps(33,idx) = (Wasps(31,idx) > random_value);
                                                                                idx = find(Wasps(30,:,:) == 1 & Wasps(29,:,:) == 0); % find all newly-emerged wasps (their first phase) who have a '0' in row 29 (i.e., are below the decision threshold for condition)
                                                                                     random_value = rand(1,size(idx,1));
                                                                                     Wasps(33,idx) = (Wasps(32,idx) > random_value);
                        % Column 34                      
                        
                        % Column 35             k1 Maternal allele              Value inherited from previous phase. (Trait: If you choose to become a foundress, will you attempt nest-founding or be an instant cooperator?)
                        % ...                   ...                             ...
                        % Column 58             z6 Paternal allele              Value inherited from previous phase.
                        % Column 59             Mean genetic value for k        Depends on phase of year:
                                                                                Wasps(59,:,:) = (Wasps(k_maternal_allele_row,:,:) + Wasps(k_paternal_allele_row,:,:))/2;     % ROW 59: each wasp's mean genetic value (average of maternal and paternal alleles) for k for this phase.                                      
                        % Column 60             Mean genetic value for z        Depends on phase of year:
                                                                                Wasps(60,:,:) = (Wasps(z_maternal_allele_row,:,:) + Wasps(z_paternal_allele_row,:,:))/2;     % Column 60: each wasp's mean genetic value (average of maternal and paternal alleles) for z for this phase.
                        % Column 61             Pleometrosis phenotype          Determined here:                                             % i.e., if you choose to become a foundress, will you attempt nest-founding or be an instant cooperator?
                                                                                pleometrosis_random_value = rand(1,nWasps);
                                                                                Wasps(61,:,:) = (Wasps(33,:,:) == 1).*((Wasps(29,:,:).*(Wasps(59,:,:) > pleometrosis_random_value)) + ((1-Wasps(29,:,:)).*(Wasps(60,:,:) > pleometrosis_random_value))); % Column 61: '1' if choosing to be an instant cooperator. '0' if choosing to try establishing your own nest.
        %%
        %toc  
        % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        % RE-INITIALISING LOCALLY-EXTINCT SITES:
        % If a site has gone locally extinct, re-initialise it by resetting it with an identical composition to the closest surviving site:
        %%
         disp(['Current Phase: ',num2str(Phase),'. Current section: (2) Re-initialising locally-extinct sites'])
        % Find sites that are locally extinct:
        idx = find(isnan(Wasps(4,:,:))); 
        [row,col,page] = ind2sub(size(Wasps(4,:,:)),idx);
        [empty_slot_count,each_site]=groupcounts(page);
        empty_sites = [each_site empty_slot_count];
        empty_sites = each_site(empty_slot_count == size(Wasps,2));
       
        % Plot empty sites:
        empty_sites_tracker(Phase) = size(empty_sites,1);

if FiguresOnOrOff == 1       
figure(1)
        subplot(4,4,10)
            if Phase > 6
    % First, shade the different sectors according to harshness (harsher is darker):
    my_transparency_baseline = 0;       my_face_color = [0.5,0.5,0.5];      my_radius_max = nSites;
    Jan_to_Mar_theta = deg2rad(repelem(360,my_radius_max)); polarhistogram(Jan_to_Mar_theta,1,'BinLimits',deg2rad([330 390]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(1));
        hold on
    Mar_to_May_theta = deg2rad(repelem(30,my_radius_max)); polarhistogram(Mar_to_May_theta,1,'BinLimits',deg2rad([30 90]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(2));
    May_to_Jul_theta = deg2rad(repelem(90,my_radius_max)); polarhistogram(May_to_Jul_theta,1,'BinLimits',deg2rad([90 150]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(3));
    Jul_to_Sep_theta = deg2rad(repelem(150,my_radius_max)); polarhistogram(Jul_to_Sep_theta,1,'BinLimits',deg2rad([150 210]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(4));
    Sep_to_Nov_theta = deg2rad(repelem(210,my_radius_max)); polarhistogram(Sep_to_Nov_theta,1,'BinLimits',deg2rad([210 270]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(5));
    Nov_to_Dec_theta = deg2rad(repelem(270,my_radius_max)); polarhistogram(Nov_to_Dec_theta,1,'BinLimits',deg2rad([270 330]),'FaceColor',my_face_color,'FaceAlpha',IsHibernation(6));

    angle_increments = (0:1.0472:((Phase-1)*1.0472))';                            
    theta_new = linspace(0, max(angle_increments), 360*(Phase/6));
    theta_new = (0:0.05:((Phase-1)*1.0472))';   
    
    hold on
    figure(1)
        subplot(4,4,10)
    set(gcf,'color','w');
    r_new_higher = interp1(angle_increments(1:Phase), empty_sites_tracker(1:Phase), theta_new, 'linear', 'extrap');
    polarplot(theta_new,r_new_higher, Color =[0,1,1, 0.5]); % The last value is the transparency.
    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
    ax.RAxisLocation = -30;
    set(gca, 'GridColor', "black", 'GridAlpha', 1);
    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
    
    pause(0.001)

    hold on
    figure(1)
        subplot(4,4,10)
    thetaticks(30:60:390);
    thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'})
    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
    ax.RAxisLocation = -30;
    set(gca, 'GridColor', "black", 'GridAlpha', 1);
    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
    pause(0.001)
    hold off
            end  
end % end of if FiguresOnOrOff toggle.

        % end plotting empty sites.

        % List the sites that remain live:
        live_sites = (1:nSites)'; live_sites(empty_sites) = 0; live_sites = live_sites(live_sites ~=0);
        
        % To link the two ends of the circular lattice, temporarily add in <1 and >nSites site IDs:
        live_sites = cat(1,live_sites, live_sites((end-2):end)-nSites, live_sites((1:2))+nSites);
        
        % Find the nearest live site to each empty site, using the code snippet at: https://uk.mathworks.com/matlabcentral/answers/152301-find-closest-value-in-array
        A = repmat(live_sites,[1 length(empty_sites)]);
        [minValue,closestIndex] = min(abs(A-empty_sites'));
        closest_live_site = live_sites(closestIndex); 
        recolonisation_changes_to_make = [empty_sites closest_live_site];
        
        % Set sites <1 or >nSites to their corresponding actual number (e.g., '1001' is site 1):
        if max(recolonisation_changes_to_make(:,2)) > nSites
            recolonisation_changes_to_make(recolonisation_changes_to_make(:,2) > nSites,2) = recolonisation_changes_to_make(recolonisation_changes_to_make(:,2) > nSites,2) - nSites;
        end
        if min(recolonisation_changes_to_make(:,2)) < 1
            recolonisation_changes_to_make(recolonisation_changes_to_make(:,2) < 1,2) = recolonisation_changes_to_make(recolonisation_changes_to_make(:,2) <1 ,2) + nSites;
        end    
        
        % Re-initialise sites by making them identical to the nearest surviving site:
        Wasps(4:end,:,recolonisation_changes_to_make(:,1)) = Wasps(4:end,:,recolonisation_changes_to_make(:,2));
        %%
        if FiguresOnOrOff == 1
            figure(1)
            subplot(4,4,6)
            plot(empty_sites)
            title('Empty sites')
        end
        % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        % FOR HIBERNATION/TORPOR PHASES:          
        %%
        % Some phases are unlivable, and require either hibernation (if too cold) or torpor (if too hot/dry).
        % These are phases where EnvState is 0. For theses unlivable phases, we let wasps survive to the end of the phase, in a state of hibernation or torpor.
        % During these phases, there is no reproduction or cooperation, so all of the sections below are ignored.

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % HIBERNATION PHASES (COLD):
                            % By definition, any wasp emerging from hibernation must act as a foundress, because there are no worker nests left.
                            % For these wasps, we must therefore set everyone's phenotype to '1'.
                            % Therefore, for exit from hibernation and continuation of hibernation:
                            if Phase > 1 && IsHibernation(YearlyPhasesList(Phase-1)) == 1 % if the last phase was a hibernation (whilst this one is not):
                                    idx = find(Wasps(30,:,:) == 1);
                                    Wasps(33,idx) = 1;
                            end
                    
                            % For entry to hibernation:
                            if EnvState(PhaseOfYear) == 0 && IsHibernation(PhaseOfYear) == 1 % hibernation states only
                                                % In hibernation states, only hopeful foundresses can progress to the next stage, because they must leave the nest and join a hibernation cluster. This is not necessarily true for wasps in hot torpor states, where wasps can remain on their mature post-emergence colony, and resume the colony at the end of the torpor.
                                                % Therefore, in hibernation states only, worker strategies are impossible by definition:
                                               
                                                                        idx = find(Wasps(33,:,:) ~= 1); % find all non-hopeful-foundress wasps.
                                                                        Wasps(4:end,idx) = nan; % Kill all wasps who have not chosen to become foundresses.
                                                                        
                                                                        idx = find(Wasps(30,:,:) > 1); % find all wasps aged greater than 1 phases:
                                                                        Wasps(4:end,idx) = nan; % Kill all older wasps.
                                                   
                            end % end if statement dealing with hibernation

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % TORPOR PHASES (HOT):
        % Torpor phases occur in hot unlivable states, unlike hibernation. The following differences arise between torpor and hibernation in the model:
                % (1) In torpor phases, all adults can survive (not just hopeful foundresses)
                % (2) In torpor phases, all wasps remain on their parental nest (effectively in a state of suspended animation), rather than leaving the nest to enter a hibernaculum with other wasps on the site
                % (3) In torpor phases, the parental nest survives, but brood production is temporarily suspended

        % We assume that larger colonies are more likely to survive torpor:
                    ind = find(~isnan(Wasps(4,:,:)));                               % Identifies all existing wasps in the population.
                    [row,col,page] = ind2sub(size(Wasps(4,:,:)), ind);              % Provides the wasp slot id (column, 'col') and site ('page') for each existing wasp in the population.
                    torpor_existing_wasps = [col page 100000*page+Wasps(2,sub2ind([nWasps,nSites],col,page))'];  % The third column of 'existing_wasps' lists the home colony for every individual (i.e., the mature colony or the newly secure foundress nest that they have just entered 'Wasps' in). Every colony in the population has a unique code, as earlier.
                    [torpor_group_size,torpor_which_nest]=groupcounts(torpor_existing_wasps(:,3));
                    torpor_group_size_dataset = [torpor_which_nest torpor_group_size]; 

                     % * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *        
                            % Torpor-state colony survival function (which can be changed) is here a logistic function of group size:
                                                torpor_k = 0.05; % The steepness of the logistic curve.
                                                torpor_BaselineSurvival = 0.9; 
                                                torpor_MaximumSurvival = 0.5; 
                                                
                                                torpor_colony_survival_probability  = torpor_BaselineSurvival + (((torpor_MaximumSurvival-torpor_BaselineSurvival))./(1 + exp(torpor_k*((max_Wasps_Per_Colony/2)-torpor_group_size)))); 
       
                            % * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *        
        
                    % Colonies now survive or fail according to their colony survival probability:
                    torpor_colony_survival = torpor_colony_survival_probability > rand(length(torpor_colony_survival_probability),1);
                    % To see which nests have survived, use:        which_nest(~colony_survival);

                    % All members of colonies scheduled to die are now eliminated from the population:
                            col = torpor_existing_wasps(ismember(torpor_existing_wasps(:,3),torpor_which_nest(~torpor_colony_survival)) == 1,1); % Wasp slots (columns) for wasps in colonies that are scheduled to die.
                            page = torpor_existing_wasps(ismember(torpor_existing_wasps(:,3),torpor_which_nest(~torpor_colony_survival)) == 1,2); % Identify the sites for these wasps.
                                % You can see the nest IDs using:   nest = existing_wasps(ismember(existing_wasps(:,3),which_nest(~colony_survival)) == 1,3);
                            % Set all these wasp slots back to 'NaN' using the linear index approach (https://uk.mathworks.com/matlabcentral/answers/2000108-efficiently-moving-values-in-a-3-dimensional-array):
                            torpor_wasps_in_dying_colonies=sub2ind(  [nWasps,nSites],col,page  );  % Identify the linear indices of all wasps who are scheduled to die.
                            Wasps(4:end,torpor_wasps_in_dying_colonies)=nan;                       % All members of dying colonies die. Their rows revert to 'NaN'.
          
                % Just like the hibernation phases, the normal processing sections below are skipped during torpor.

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % COSTS OF HIBERNATION AND TORPOR:
        % In both hibernation and torpor phases, we assume that (1) there is a cost in terms of body condition and (2) wasps with a body condition below a threshold fail to survive the hibernation/torpor:
                   if EnvState(PhaseOfYear) == 0 % hibernation and torpor states:
                        % Hibernating/torpor wasps suffer a loss in body condition due to the stresses of hibernation/torpor:
                            hibernation_torpor_cost = 0.1; % Choose the cost to body condition per phase of hibernation/torpor.
                            idx = find(Wasps(28,:,:));
                            Wasps(28,idx) = Wasps(28,idx) - hibernation_torpor_cost;
                        % No wasps with a resulting body condition below a given threshold survive the phase:
                            threshold_body_condition = 0.2;
                            idx = find(Wasps(28,:,:) < threshold_body_condition);
                            Wasps(4:end,idx) = nan; % Wasps are killed if they are below the threshold body condition.
                   end
        %%

% --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
% RECORD HOW MANY WASPS ARE CHOOSING TO BECOME FOUNDRESSES IN THIS PHASE:
disp(['Current Phase: ',num2str(Phase),'. Current section: (3) Recording how many wasps are choosing to become foundresses in this phase'])
%%
 % Find proportion of new wasps who are choosing to become foundresses:
 idx = find(Wasps(30,:,:) == 1);
    FoundressPhenotype(Phase) = sum(Wasps([33],idx))/size(Wasps([33],idx),2);
    
            % Find average condition of new workers:
            idx = find(Wasps(30,:,:) == 1 & Wasps(33,:,:) == 0);
            NewWorkerAverageCondition(Phase) = mean(Wasps(28,idx));
           
            % Find average condition of new hopeful lead founder foundresses:
            idx = find(Wasps(30,:,:) == 1 & Wasps(33,:,:) == 1 & Wasps(61,:,:) == 0);
            NewHopefulLeadFounderAverageCondition(Phase) = mean(Wasps(28,idx));
            
            % Find average condition of new instant cooperator foundresses:
            idx = find(Wasps(30,:,:) == 1 & Wasps(33,:,:) == 1 & Wasps(61,:,:) == 1);
            NewInstantCooperatorAverageCondition(Phase) = mean(Wasps(28,idx));
            
PleometrosisPhenotype(Phase) = sum(Wasps(61,:,:) == 1,"all","omitnan")/sum(Wasps(33,:,:) == 1,"all"); % 'PleometrosisPhenotype' tracks the proportion of foundresses who choose to be instant cooperators, rather than attempting to be lead founders.

% Find probability of becoming a foundress for new higher-condition and lower-condition wasps (i.e., average trait value at rows 31 and 32, respectively, in the population)
    idx = find(Wasps(30,:,:) == 1 & Wasps(29,:,:) == 1);
        HigherConditionFoundressPhenotype(Phase) = mean(Wasps(33,idx),'Omitnan');
    idx = find(Wasps(30,:,:) == 1 & Wasps(29,:,:) == 0);
        LowerConditionFoundressPhenotype(Phase) = mean(Wasps(33,idx),'Omitnan');

% Plot the following each year:
if FiguresOnOrOff == 1
                if mod(Phase,6) == 0
                figure(666)
                subplot(1,3,1) % FoundressPhenotype plot:
                hold off
                if Phase > 6
                    % First, shade the different sectors according to harshness (harsher is darker):
                    my_transparency_baseline = 0;       my_face_color = [0.5,0.5,0.5];      my_radius_max = 100;
                    Jan_to_Mar_theta = deg2rad(repelem(360,my_radius_max)); polarhistogram(Jan_to_Mar_theta,1,'BinLimits',deg2rad([330 390]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(1) == 0));
                        hold on
                    Mar_to_May_theta = deg2rad(repelem(30,my_radius_max)); polarhistogram(Mar_to_May_theta,1,'BinLimits',deg2rad([30 90]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(2) == 0));
                    May_to_Jul_theta = deg2rad(repelem(90,my_radius_max)); polarhistogram(May_to_Jul_theta,1,'BinLimits',deg2rad([90 150]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(3) == 0));
                    Jul_to_Sep_theta = deg2rad(repelem(150,my_radius_max)); polarhistogram(Jul_to_Sep_theta,1,'BinLimits',deg2rad([150 210]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(4) == 0));
                    Sep_to_Nov_theta = deg2rad(repelem(210,my_radius_max)); polarhistogram(Sep_to_Nov_theta,1,'BinLimits',deg2rad([210 270]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(5) == 0));
                    Nov_to_Dec_theta = deg2rad(repelem(270,my_radius_max)); polarhistogram(Nov_to_Dec_theta,1,'BinLimits',deg2rad([270 330]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(6) == 0));
                
                    angle_increments = (0:1.0472:((Phase-1)*1.0472))';                            
                    theta_new = linspace(0, max(angle_increments), 360*(Phase/6));
                    theta_new = (0:0.05:((Phase-1)*1.0472))';   
                    
                    rlim([0 1])
                
                    hold on
                    figure(666)
                    subplot(1,3,1)
                    set(gcf,'color','w');
                    r_new_higher = interp1(angle_increments(1:Phase),FoundressPhenotype(1:Phase), theta_new, 'linear', 'extrap');
                    polarplot(theta_new,r_new_higher, Color =[0,1,1, 0.3]); % The last value is the transparency.
                    thetaticks(30:60:390);
                    thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'})
                    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30;
                    set(gca, 'GridColor', "black", 'GridAlpha', 1);
                    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    pause(0.001)
                
                end
                hold off
                
                figure(666)
                subplot(1,3,2) % Average condition of new workers, new hopeful founders, and new instant cooperators:
                hold off 
                if Phase > 6
                    % First, shade the different sectors according to harshness (harsher is darker):
                    my_transparency_baseline = 0;       my_face_color = [0.5,0.5,0.5];      my_radius_max = 100;
                    Jan_to_Mar_theta = deg2rad(repelem(360,my_radius_max)); polarhistogram(Jan_to_Mar_theta,1,'BinLimits',deg2rad([330 390]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(1) == 0));
                        hold on
                    Mar_to_May_theta = deg2rad(repelem(30,my_radius_max)); polarhistogram(Mar_to_May_theta,1,'BinLimits',deg2rad([30 90]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(2) == 0));
                    May_to_Jul_theta = deg2rad(repelem(90,my_radius_max)); polarhistogram(May_to_Jul_theta,1,'BinLimits',deg2rad([90 150]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(3) == 0));
                    Jul_to_Sep_theta = deg2rad(repelem(150,my_radius_max)); polarhistogram(Jul_to_Sep_theta,1,'BinLimits',deg2rad([150 210]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(4) == 0));
                    Sep_to_Nov_theta = deg2rad(repelem(210,my_radius_max)); polarhistogram(Sep_to_Nov_theta,1,'BinLimits',deg2rad([210 270]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(5) == 0));
                    Nov_to_Dec_theta = deg2rad(repelem(270,my_radius_max)); polarhistogram(Nov_to_Dec_theta,1,'BinLimits',deg2rad([270 330]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(6) == 0));
                
                    angle_increments = (0:1.0472:((Phase-1)*1.0472))';                            
                    theta_new = linspace(0, max(angle_increments), 360*(Phase/6));
                    theta_new = (0:0.05:((Phase-1)*1.0472))';   
                    
                    hold on
                    figure(666)
                    subplot(1,3,2)
                    set(gcf,'color','w');
                    r_new_higher = interp1(angle_increments(1:Phase), NewWorkerAverageCondition(1:Phase), theta_new, 'linear', 'extrap');
                    polarplot(theta_new,r_new_higher, Color =[1,0,1, 0.05]); % The last value is the transparency.
                    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30;
                    set(gca, 'GridColor', "black", 'GridAlpha', 1);
                    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    
                    rlim([0 max(NewHopefulLeadFounderAverageCondition(1:Phase))])
                
                    pause(0.001)
                
                    hold on
                    figure(666)
                    subplot(1,3,2)
                    set(gcf,'color','w');
                    r_new_higher = interp1(angle_increments(1:Phase), NewHopefulLeadFounderAverageCondition(1:Phase), theta_new, 'linear', 'extrap');
                    polarplot(theta_new,r_new_higher, Color =[0,1,1, 0.05]); % The last value is the transparency.
                    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30;
                    set(gca, 'GridColor', "black", 'GridAlpha', 1);
                    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    
                    pause(0.001)
                
                    hold on
                    figure(666)
                    subplot(1,3,2)
                    set(gcf,'color','w');
                    r_new_higher = interp1(angle_increments(1:Phase), NewInstantCooperatorAverageCondition(1:Phase), theta_new, 'linear', 'extrap');
                    polarplot(theta_new,r_new_higher, Color =[0,0,1, 0.05]); % The last value is the transparency.
                    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30;
                    set(gca, 'GridColor', "black", 'GridAlpha', 1);
                    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    
                    pause(0.001)
                
                    hold on
                    figure(666)
                    subplot(1,3,2)
                    thetaticks(30:60:390);
                    thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'})
                    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30;
                    set(gca, 'GridColor', "black", 'GridAlpha', 1);
                    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    pause(0.001)
                
                    
                end  
                hold off
                
                figure(666)
                subplot(1,3,3) % Probability of becoming a foundress for high and low condition new wasps:
                hold off
                if Phase > 6
                
                    % First, shade the different sectors according to harshness (harsher is darker):
                    my_transparency_baseline = 0;       my_face_color = [0.5,0.5,0.5];      my_radius_max = 100;
                    Jan_to_Mar_theta = deg2rad(repelem(360,my_radius_max)); polarhistogram(Jan_to_Mar_theta,1,'BinLimits',deg2rad([330 390]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(1) == 0));
                        hold on
                    Mar_to_May_theta = deg2rad(repelem(30,my_radius_max)); polarhistogram(Mar_to_May_theta,1,'BinLimits',deg2rad([30 90]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(2) == 0));
                    May_to_Jul_theta = deg2rad(repelem(90,my_radius_max)); polarhistogram(May_to_Jul_theta,1,'BinLimits',deg2rad([90 150]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(3) == 0));
                    Jul_to_Sep_theta = deg2rad(repelem(150,my_radius_max)); polarhistogram(Jul_to_Sep_theta,1,'BinLimits',deg2rad([150 210]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(4) == 0));
                    Sep_to_Nov_theta = deg2rad(repelem(210,my_radius_max)); polarhistogram(Sep_to_Nov_theta,1,'BinLimits',deg2rad([210 270]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(5) == 0));
                    Nov_to_Dec_theta = deg2rad(repelem(270,my_radius_max)); polarhistogram(Nov_to_Dec_theta,1,'BinLimits',deg2rad([270 330]),'FaceColor',my_face_color,'FaceAlpha',double(EnvState(6) == 0));
                
                    angle_increments = (0:1.0472:((Phase-1)*1.0472))';                            
                    theta_new = linspace(0, max(angle_increments), 360*(Phase/6));
                    theta_new = (0:0.05:((Phase-1)*1.0472))';   
                    
                    hold on
                    figure(666)
                    subplot(1,3,3)
                    set(gcf,'color','w');
                    r_new_higher = interp1(angle_increments(1:Phase), HigherConditionFoundressPhenotype(1:Phase), theta_new, 'linear', 'extrap');
                    polarplot(theta_new,r_new_higher, Color =[0,1,1, 0.05]); % The last value is the transparency.
                    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30;
                    set(gca, 'GridColor', "black", 'GridAlpha', 1);
                    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    
                    rlim([0 1])
                
                    pause(0.001)
                
                    hold on
                    figure(666)
                    subplot(1,3,3)
                    set(gcf,'color','w');
                    r_new_higher = interp1(angle_increments(1:Phase), LowerConditionFoundressPhenotype(1:Phase), theta_new, 'linear', 'extrap');
                    polarplot(theta_new,r_new_higher, Color =[1,0,1, 0.05]); % The last value is the transparency.
                    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30;
                    set(gca, 'GridColor', "black", 'GridAlpha', 1);
                    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    
                    pause(0.001)
                
                    hold on
                    figure(666)
                    subplot(1,3,3)
                    thetaticks(30:60:390);
                    thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'})
                    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30;
                    set(gca, 'GridColor', "black", 'GridAlpha', 1);
                    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    pause(0.001)
                end  
                hold off
                end
end

%%
% ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------              
        if EnvState(PhaseOfYear) > 0 % The following sections apply only if the environment is not in a hibernation/torpor phase:
% ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------              

                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % NEST FOUNDATION AND PLEOMETROSIS: currently around 0.33 seconds if nSites=2000
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (4) Nest foundation and pleometrosis'])
                    %tic
                    %%
                    % Find linear indices for all foundresses (wasps choosing to become a foundress have a '1' in row 33):
                    idx = find(Wasps(33,:,:) == 1); 

                    % Convert from the linear indices to the subscripts:
                    [row,col,page] = ind2sub(size(Wasps(33,:,:)),idx);          % This provides the row, column (wasp), and page (site) for the 'array'. There is only 1 row, as the array is made up of the row of interest (row 33) from Wasps.
                    all_foundresses = [row col page]; % We keep a record of the foundresses, which we will return to at the end of the nest foundation sections.
   
                    % We will use row 88 to give a unique ID number to each independently-established foundress nest in the whole population. We add this number to ROW 88 of the founding dominant (every wasp who has chosen to be a hopeful lead founder, which means that they already have a '0' in their ROW 61):
                        Wasps( sub2ind(size(Wasps),row*88,col,page) ) = (1-(Wasps(sub2ind(size(Wasps),row*61,col,page)))).*((1:(size(row,1)))');            % Row 88: ID number of new foundress nest (unique in the whole population). At this stage, only entered into each hopeful lead founder's COLUMN.
                    
                    % Make an array called 'Foundations', which lists in a single 2D array all the new foundations in the population. Each row is a separate foundress nest:
                                Foundations = nan(size(row,1),6+max_subordinate_group_size);  % (Note: The larger you make the 'max_subordinate_group_size', the slower the loop below will be.)
                                Foundations(:,1) = page;                                                    % 'Foundations' Column 1: Site of each foundation
                                Foundations(:,2) = Wasps( sub2ind(size(Wasps),row*2,col,page) );            % 'Foundations' Column 2: Parent nest ID within the site
                                Foundations(:,3) = Wasps( sub2ind(size(Wasps),row*88,col,page) );           % 'Foundations' Column 3: Foundress nest ID (unique ID within the whole population)
                                Foundations(:,4) = Wasps( sub2ind(size(Wasps),row*1,col,page) );            % 'Foundations' Column 4: ID number (row within its site) of the lead foundress for this foundress nest. Its row in 'Wasps' refers to its position still in its parental nest (it will be moved out of it in the script below).
                                Foundations(:,5) = 100000*Foundations(:,1)+Foundations(:,2);                % 'Foundations' Column 5: ID number (unique within the whole population) of the parent colony (a different completely list to the foundress nest IDs. Nests with the same number in each list are not connected in any way). 
                                Foundations(:,6) = Wasps( sub2ind(size(Wasps),row*28,col,page) );           % 'Foundations' Column 6: Body condition of lead founder
                                Foundations = Foundations(Foundations(:,3)>0,:);                            % Eliminate empty rows (empty rows were produced for wasps who have not chosen to be lead foundresses, i.e. whose column 61 is '1', as they are instant cooperators).
                    
                    % Each lead founder's body condition determines whether her initial lone foundation (the construction of a small egg-only nest) fails instantly or proceeds:
                    
                              % The body condition score ranges from 0 to 1. This value is directly the probability that the wasp will succeed in establishing a nest if she attempts to become a lead foundress:
                              tolerance = 0.5*EnvState(PhaseOfYear); % Ranges from 0 to 0.5. In a maximally benign environmental state (EnvState = 1), tolerance is high (0.5). This relaxes the importance of body condition in early stage nesting success in the following line.
                              early_stage_nest_survival = Foundations(:,6) > (rand(size(Foundations(:,6))) - tolerance); % '1' if nest survives early stage, '0' if dies.
                              % If you would like to impose a minimum condition for success:
                                %%minimum_threshold_condition = 0.1;
                                %%early_stage_nest_survival(Foundations(:,6) > minimum_threshold_condition) = 0; % all lead founders below the minimum threshold condition fail

                    % REDIRECTED HELPING BY FAILED LEAD FOUNDERS: The lead founders who failed at the early-stage are set aside to add to the upcoming cooperator pool, as redirected helpers:
                                numrows = size(Foundations(early_stage_nest_survival == 0,1),1);
                                RedirectedHelpers = nan(numrows,4);
                                RedirectedHelpers(:,1) = Foundations(early_stage_nest_survival == 0,1);                                                                                 % 'RedirectedHelpers' Column 1: Site
                                RedirectedHelpers(:,2) = Foundations(early_stage_nest_survival == 0,4);                                                                                 % 'RedirectedHelpers' Column 2: Row number in Wasps (wasp-slot ID)
                                RedirectedHelpers(:,3) = Foundations(early_stage_nest_survival == 0,2);                                                                                 % 'RedirectedHelpers' Column 3: Parental nest (number within its own site)
                                RedirectedHelpers(:,4) = 100000*Foundations(early_stage_nest_survival == 0,1)+Foundations(early_stage_nest_survival == 0,2);                            % 'RedirectedHelpers' Column 4: Parental nest (unique number within whole population)
    
                    % Now eliminate the failed lead founders from their lead foundress positions in 'Foundations':
                                Foundations = Foundations(early_stage_nest_survival == 1,:);  
             
                    % At this point, there may be no foundations left in the population (especially if this is a phase of the year in which very few wasps choose to be foundresses).
                    % The rest of the foundation section only applies if foundations have actually been built by hopeful lead founder (technically, it requires at least two foundations in the entire population, to ensure that the 'sub2ind' function works smoothly):
if size(Foundations,1) > 1 % only proceed if there is more than one foundation built in the entire population
disp(['Current Phase: ',num2str(Phase),'. Current section: (5) Proceeding as there is more than a single foundation built in the population'])

                    % Identify all instant cooperators in the whole population. All instant cooperators have '1' in row 61:
                                        idx = find(Wasps(61,:,:) == 1);                              
                                        [row,col,page] = ind2sub(size(Wasps(61,:,:)),idx);          % This provides the row (wasp info), column (wasp slot ID), and page (site) for the 'array'. There is only 1 row, as the array is made up of the row of interest (row 61) from Wasps.
                                        InstantCooperators = [page     Wasps(sub2ind(size(Wasps),row*1,col,page))    Wasps(sub2ind(size(Wasps),row*2,col,page))      100000.*page+Wasps(sub2ind(size(Wasps),row*2,col,page))]; % The site, row number (wasp-slot ID), parental nest (number within its own site), and parental nest (unique number in the whole population) of all the instant cooperators in the population.
                                        % 'InstantCooperators' Column 1: Site
                                        % 'InstantCooperators' Column 2: COLUMN number (wasp slot ID) in 'Wasps'
                                        % 'InstantCooperators' Column 3: Parental nest (number within its own site)
                                        % 'InstantCooperators' Column 4: Parent nest (unique number within whole population)

                    % The opportunity for redirected helping can be set by the user.
                    % When '1', attempting to build your own nest and failing does not carry an opportunity cost in terms of lost opportunities to be a subordinate (and therefore no chance to help kin, etc.).
                    % When '0', a failed lead foundress has no opportunity to join a nest as a subordinate.
                    % 'RedirectedHelpingOpportunity' is set above, and can take any value from 0 to 1 (e.g., 0.5). It sets the probability that a failed lead foundress has the opportunity to become a redirected helper:
                    chosen_redirected_helpers = rand(size(RedirectedHelpers,1),1) < RedirectedHelpingOpportunity;
                    RedirectedHelpers = RedirectedHelpers(chosen_redirected_helpers,:);
                    if ~isempty(RedirectedHelpers)
                        InstantCooperators = cat(1,InstantCooperators,RedirectedHelpers);
                    end
                    
                    % Record the total numbers of each type of foundress this phase:
                            % First, record how many wasps become hopeful lead founders (which means they had a zero in row 61):
                                     idx = find(Wasps(61,:,:) == 0);
                                     HopefulFounderCountTracker(Phase) = max(size(idx));
                            % All other foundresses chose to become 'instant cooperators' (which means they had a one in row 61). Record how many this was:
                                     idx = find(Wasps(61,:,:) == 1);
                                     InstantCooperatorCountTracker(Phase) = max(size(idx));
                            % Of the hopeful lead founders, record how many ultimately become redirected helpers:
                                     RedirectedHelperCountTracker(Phase) = max(size(RedirectedHelpers));

                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % SISTERS JOINING IF AVAILABLE (THROUGH NATAL PHILOPATRY/KIN DISCRIMINATION):            
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (6) Sisters joining if available'])                    
                    % Identify slots in the 'Foundations' array that are available for filling by subordinates on each site:
                    idx = find(isnan(Foundations));                                         % Find linear indices of all unfilled subordinate slots in the 'Foundations' array.
                    
                    % The strength of kin discrimination (through kin recognition or within-site natal philopatry) determines how many of these sites will be automatically filled with a sister if one is available:
                    idx = idx(rand(length(idx),1) < StrengthOfKinDiscrimination);

                    % The following section runs only if at least some foundresses are joining via kin discrimination:
                    if ~isempty(idx)
                                
                                        [row,col] = ind2sub(size(Foundations),idx);                             % Identify row and column of these slots.
                                        % The site for each of these slots can be found using:                                  Foundations( sub2ind(size(Foundations),row,ones(length(row),1)) );    
                                        % The actual value at each of these slots (should all be 'NaN', by definition):         Foundations( sub2ind(size(Foundations),row,col));              
                                        
                                        % Give every available slot in 'Foundations' a sequence number within its own PARENTAL NEST SET (i.e., take all the foundations whose dominants came from parental nest X, and number all the slots (starting at 1 and counting upwards) in these foundations collectively):
                                        V1 = Foundations( sub2ind(size(Foundations),row,5*ones(length(row),1)) ); % the unique number (in the whole population) for the parental nest.
                                                % Temporarily reorder, so that we can count number of available slots in each site:
                                                OriginalOrder = (1:length(V1))';
                                                temporary_array = [V1 OriginalOrder];
                                                V1_reordered = sortrows(temporary_array,1);
                                                V1 = V1_reordered(:,1);
                                        t = diff([0; find([diff(V1)~=0; true])]);V2 = ones(sum(t), 1);V2(cumsum(t(1:end-1))+1) = 1-t(1:end-1);V2 = cumsum(V2);  % A generic/useful line of code (from https://stackoverflow.com/questions/49780361/create-vector-which-ascends-based-on-repeated-values-of-another-vector-matlab) for generating a sequence of numbers (starting at 1 each time) for members of each group.
                                                % Restore original order:
                                                output = sortrows([V2 V1_reordered],3);
                                                foundress_slots_to_fill = [row col output(:,[2 1])];
                                                    % Column 1 of 'foundress_slots_to_fill':    Contains the row of this slot in 'Foundations'
                                                    % Column 2 of 'foundress_slots_to_fill':    Contains the column of this slot in 'Foundations'
                                                    % Column 3 of 'foundress_slots_to_fill':    Contains the parental nest ID
                                                    % Column 4 of 'foundress_slots_to_fill':    Contains the sequence number of this slot within its parental nest set
                                                
                                        % Now take all available foundresses (in the 'InstantCooperator' array), and similarly give them a sequence number within their own PARENTAL NEST SET (i.e., take all members of 'InstantCooperators' who come from parental nest X, and number then (starting at 1 and counting upwards):
                                        V1 = InstantCooperators(:,4);
                                        t = diff([0; find([diff(V1)~=0; true])]);V2 = ones(sum(t), 1);V2(cumsum(t(1:end-1))+1) = 1-t(1:end-1);V2 = cumsum(V2);  % A generic/useful line of code (from https://stackoverflow.com/questions/49780361/create-vector-which-ascends-based-on-repeated-values-of-another-vector-matlab) for generating a sequence of numbers (starting at 1 each time) for members of each group.
                                        InstantCooperators(:,5) = V2; % add the numbers as a new column (Column 5) in 'InstantCooperators'
                    
                                        % Fill the available slots with the remaining *sister* instant cooperators by pairing them according to their allocated slot (e.g., find the wasp in 'InstantCooperators' that is in slot 24 on site 9998, and add it to the corresponding cell of 'Foundations':
                                        [ida, idb] = ismember(    foundress_slots_to_fill(:,3:4)    ,  InstantCooperators(:,4:5),   'rows'   );
                                        foundress_slots_to_fill(ida,5:(4+size(InstantCooperators,2))) = InstantCooperators(idb(ida),:);
                                                    % Column 6 of 'foundress_slots_to_fill':    Contains the instant cooperator ID (wasp-slot column number within its site) to enter into that foundress slot. Sisters of the lead founders.
                                        Foundations(idx) = foundress_slots_to_fill(:,6);
                    
                                        % Now that these sisters have joined a foundress nest, remove them from 'InstantCooperators':
                                        InstantCooperators(idb(ida),:) = [];  % idb(ida) gives the row numbers in 'InstantCooperators' for the wasps who have just been transferred to 'foundress_slots_to_fill'. Using [] removes them from the array (e.g., https://uk.mathworks.com/help/matlab/math/removing-rows-or-columns-from-a-matrix.html).
                    end

                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % RANDOM JOINING (MAY BE SISTERS OR NON-SISTERS):           
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (7) Random joining (may be sisters or non-sisters)'])                  
                    % From the wasps who remain in 'InstantCooperators', we now allocate them at random to foundress nests within their site. They may be sisters or non-sisters.
                    % The process is the same as for the natal philopatry/kin discrimination section.
                    
                    % Identify remaining slots in the 'Foundations' array that are available for filling by subordinates on each site:
                    idx = find(Foundations == 0 | isnan(Foundations));                                           % Find linear indices of all unfilled subordinate slots in the 'Foundations' array, which now have '0'.
                    [row,col] = ind2sub(size(Foundations),idx);                             % Identify row and column of these slots.
                    % The site for each of these slots can be found using:                                  Foundations( sub2ind(size(Foundations),row,ones(length(row),1)) );    
                    % The actual value at each of these slots (should all be 'NaN', by definition):         Foundations( sub2ind(size(Foundations),row,col));              
                                
                                % SANITY CHECKPOINT 1: Verifies that all of the columns are column 7 or greater:
                                if SanityCheckOnOrOff == 1
                                         SanityCheckpoint(Phase,1) = isempty(col(col<7)); % Equals 1 if all of the columns in [row col] are 7 or greater (as they should be). If it does not equal 1, then a problem has arisen (i.e., zeros appearing elsewhere in 'Foundations', throwing off the indexing).
                                end % end sanity checkpoint.
                    
                    % Proceed  with random joining if there are slots available for filling:
                    if ~isempty(idx)  
                                               % Give every available slot in 'Foundations' a sequence number within its own SITE (i.e., number all the remaining open slots in a site (starting at 1 and counting upwards):
                                                V1 = Foundations( sub2ind(size(Foundations),row,1*ones(length(row),1)) ); % Site number (from column 1 of 'Foundations').
                                                        % Temporarily reorder, so that we can count number of available slots in each site:
                                                        OriginalOrder = (1:length(V1))';
                                                        temporary_array = [V1 OriginalOrder];
                                                        V1_reordered = sortrows(temporary_array,1);
                                                        V1 = V1_reordered(:,1);
                                                t = diff([0; find([diff(V1)~=0; true])]);V2 = ones(sum(t), 1);V2(cumsum(t(1:end-1))+1) = 1-t(1:end-1);V2 = cumsum(V2);  % A generic/useful line of code (from https://stackoverflow.com/questions/49780361/create-vector-which-ascends-based-on-repeated-values-of-another-vector-matlab) for generating a sequence of numbers (starting at 1 each time) for members of each group.
                                                        % Restore original order:
                                                        output = sortrows([V2 V1_reordered],3);
                                                        foundress_slots_to_fill = [row col output(:,[2 1])];
                                                            % Column 1 of 'foundress_slots_to_fill':    Contains the row of this slot in 'Foundations'
                                                            % Column 2 of 'foundress_slots_to_fill':    Contains the column of this slot in 'Foundations'
                                                            % Column 3 of 'foundress_slots_to_fill':    Contains the parental nest ID
                                                            % Column 4 of 'foundress_slots_to_fill':    Contains the sequence number of this slot within its parental nest set
                                                        
                                                % Shuffle all remaining rows (foundresses) in the 'InstantCooperator' list within their site. The wasps will still be allocated to foundations in their home site, of course, but this shuffling randomises the order that they will be allocated within their site:
                                                            InstantCooperators = InstantCooperators(randperm(size(InstantCooperators, 1)), :);
                                                            InstantCooperators = sortrows(InstantCooperators,1); % the original 'InstantCooperators' is sorted by site. Put it back into site order.
                                                
                                                % Now take all remaining foundresses (in the 'InstantCooperator' array), and similarly give them a sequence number within their own SITE (i.e., take all members of 'InstantCooperators' who come from site X, and number then (starting at 1 and counting upwards):
                                                V1 = InstantCooperators(:,1);
                                                t = diff([0; find([diff(V1)~=0; true])]);V2 = ones(sum(t), 1);V2(cumsum(t(1:end-1))+1) = 1-t(1:end-1);V2 = cumsum(V2);  % A generic/useful line of code (from https://stackoverflow.com/questions/49780361/create-vector-which-ascends-based-on-repeated-values-of-another-vector-matlab) for generating a sequence of numbers (starting at 1 each time) for members of each group.
                                                InstantCooperators(:,6) = V2; % add the numbers as a new column (Column 6) in 'InstantCooperators'
                            
                                                % Fill the available slots with the remaining instant cooperators by pairing them according to their allocated slot (e.g., find the wasp in 'InstantCooperators' that is in slot 24 on site 9998, and add it to the corresponding cell of 'Foundations':
                                                [ida, idb] = ismember(    foundress_slots_to_fill(:,3:4)    ,  InstantCooperators(:,[1 6]),   'rows'   );
                                                foundress_slots_to_fill(ida,5:(4+size(InstantCooperators,2))) = InstantCooperators(idb(ida),:);
                                                            % Column 6 of 'foundress_slots_to_fill':    Contains the instant cooperator ID (wasp-slot column number within its site) to enter into that foundress slot. Sisters of the lead founders.
                                                Foundations(idx) = foundress_slots_to_fill(:,6);
                            
                                                % Now that these sisters have joined a foundress nest, remove them from 'InstantCooperators':
                                                InstantCooperators(idb(ida),:) = [];  % idb(ida) gives the row numbers in 'InstantCooperators' for the wasps who have just been transferred to 'foundress_slots_to_fill'. Using [] removes them from the array (e.g., https://uk.mathworks.com/help/matlab/math/removing-rows-or-columns-from-a-matrix.html).
                            
                                                % Set all unfilled subordinate positions to 'NaN' (they are currently '0'):
                                                ind = find(Foundations == 0);   
                                                Foundations(ind) = NaN;
                    end
                   
                    % -------------------------------------------------------------------------------
                    % CALCULATE AND RECORD FOUNDRESS RELATEDNESSES:
                    %%
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (8) Calculating foundress relatednesses'])                       
                    % Subordinate relatednesses to dominant:

                            % It might be better to create and use a neutral locus, rather than one under selection.
                            % For now, however, we will use the locus that is relevant to this phase (i.e., this changes each phase).

                            % We will use as genetic value the value in Column 59 (genetic value for k):

                            % REGRESSION RELATEDNESS RELATIVE TO THE WHOLE POPULATION:
                            
                                            % On each foundation, the lead foundress's genetic value for k is:
                                            dominants_genetic_values = Wasps( sub2ind(size(Wasps), 59*ones(size(Foundations,1),1) ,Foundations(:,4),Foundations(:,1)) );
                
                                            % Each of the subordinate slots' genetic values for k:
                                            relatedness_data = [NaN NaN];
                                            for subordinate = 7:(7+max_subordinate_group_size-1)
                                                    subordinate_locations = [59*ones(size(Foundations,1),1) Foundations(:,subordinate) Foundations(:,1) dominants_genetic_values]; % Column 1: look in row 59 of 'Wasps'. Column 2: Current listed wasp slot (in parental colony in 'Wasps') of this subordinate. Column 3: site. Column 4: dominant's genetic value.
                                                    subordinate_locations = subordinate_locations(sum(isnan(subordinate_locations),2)==0,:); % remove any 'NaN' values (i.e., unfilled slots)
                                                    subordinates_genetic_values = Wasps( sub2ind(size(Wasps), subordinate_locations(:,1), subordinate_locations(:,2), subordinate_locations(:,3)  ));
                                                    relatedness_data = cat(1, relatedness_data, [subordinate_locations(:,4) subordinates_genetic_values]); % Column 1: dominant's genetic value. Column 2: subordinate's genetic value.
                                            end
                                            
                                            % Calculate regression relatedness:
                                                    x = relatedness_data(2:end,2); % subordinate's genetic value
                                                    y = relatedness_data(2:end,1); % dominant's genetic value
                                                    p = polyfit(x,y,1); 
                                                    f = polyval(p,x); 
                                            
                                            % To plot the regression slope for regression relatedness, use:
                                            if FiguresOnOrOff == 1
                                                    figure(1)
                                                    subplot(4,4,1)
                                                    hold on
                                                    plot(x,f,'Color', [0 1 1 0.1])
                                            end

                                            % Keep track of relatedness in each phase:
                                            relatedness_tracker(Phase) = p(1);
                                            
                                            if FiguresOnOrOff == 1
                                                figure(1)
                                                subplot(4,4,2)
                                                hold on
                                                plot(relatedness_tracker); pause(0.001)
                                                hold off
                                            end

                                            % Calculate average foundress relatedness across the whole year:
                                            
                                            if PhaseOfYear == 1
                                                relatedness_data_Phase1 = relatedness_data;
                                                whole_year_relatedness_data = cat(1,whole_year_relatedness_data,relatedness_data_Phase1);
                                            elseif PhaseOfYear == 2
                                                relatedness_data_Phase2 = relatedness_data;
                                                whole_year_relatedness_data = cat(1,whole_year_relatedness_data,relatedness_data_Phase2);
                                            elseif PhaseOfYear == 3
                                                relatedness_data_Phase3 = relatedness_data;
                                                whole_year_relatedness_data = cat(1,whole_year_relatedness_data,relatedness_data_Phase3);
                                            elseif PhaseOfYear == 4
                                                relatedness_data_Phase4 = relatedness_data;
                                                whole_year_relatedness_data = cat(1,whole_year_relatedness_data,relatedness_data_Phase4);
                                            elseif PhaseOfYear == 5
                                                relatedness_data_Phase5 = relatedness_data;
                                                whole_year_relatedness_data = cat(1,whole_year_relatedness_data,relatedness_data_Phase5);
                                            elseif PhaseOfYear == 6
                                                relatedness_data_Phase6 = relatedness_data;
                                                whole_year_relatedness_data = cat(1,whole_year_relatedness_data,relatedness_data_Phase6);
                                                % Summarise this year in the final phase of the year:
                                                x = whole_year_relatedness_data(:,2); % subordinate's genetic value 
                                                y = whole_year_relatedness_data(:,1); % dominant's genetic value
                                                p = polyfit(x(~isnan(x)),y(~isnan(x)),1);
                                                whole_year_relatedness_tracker(find(isnan(whole_year_relatedness_tracker), 1)) = p(1); % fill in the next 'NaN' value in whole_year_relatedness_tracker with the regression relatedness for all this year's phases together.
                                                if FiguresOnOrOff == 1
                                                    figure(1)
                                                    subplot(4,4,5)
                                                    plot(whole_year_relatedness_tracker); ylim([0 1]); pause(0.001)
                                                end
                                            end
                                                                       
                            % PROBABILITY THAT DOMINANT IS A SISTER (I.E., CAME FROM THE SAME PARENTAL NEST):
                                % Find the parental nest for each subordinate:
                                subordinate_list = [];                                                    
                                for subordinate = 7:(7+max_subordinate_group_size-1)                                               
                                            idx = find(~isnan(Foundations(:,subordinate)));
                                            subordinate_list = cat(1,subordinate_list,[Foundations(idx,1) Foundations(idx,4) Foundations(idx,subordinate) Foundations(idx,5)]);
                                            % Column 1 is the site, Column 2 is the dominant's ID, Column 3 is the subordinate's ID. Column 4 is the dominant's parental nest ID.
                                end
                                % The parental nest ID for each subordinate is therefore:
                                subordinate_parental_nests = 100000*(subordinate_list(:,1))+Wasps(2,sub2ind(  [nWasps,nSites],subordinate_list(:,3),subordinate_list(:,1)  ))';
                                % Record the proportion of subordinates who are sisters of the dominant (i.e., come from the same parental nest) is:
                                sister_nest_tracker(find(isnan(sister_nest_tracker), 1)) = sum(subordinate_parental_nests==subordinate_list(:,4))/size(subordinate_parental_nests,1);
                                % Plot the results:
                                if FiguresOnOrOff == 1
                                    figure(1)
                                    subplot(4,4,11)
                                    plot(sister_nest_tracker); ylim([0 1]); pause(0.001);  
                                end
                                % Take annual average of 'sister_nest_tracker' (weighted average based on number of subordinates in each phase):
                                % SECTION TO BE CONTINUED.

                                
                    %%                 
                    % -------------------------------------------------------------------------------
                    % FOUNDRESS NEST SURVIVAL OR FAILURE:
                    % Once a foundress group has established, the nest's survival depends on the extent of cooperation.
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (9) Foundress nest survival or failure'])                     
                    % The total number of subordinates on each nest in the whole population:        sum(1-isnan(Foundations(:,[7:end])),2); % Each row is a separate foundation in the 'Foundations' array.
                    % As a proportion of maximum group size:                                        sum(1-isnan(Foundations(:,[7:end])),2)./max_subordinate_group_size
                    
                    % The foundress nest survival function can be anything that you like.
                    % The simplest function is just that (subordinate group size)/(max subordinate group size) gives the probability of the foundress nest surviving (which implies, as in Tindo et al. 2008, that single-foundress colonies inevitably fail: cooperation is necessary for foundation survival to maturity):
                    % Alternatively, we can grant single-foundress nests a slim chance of survival, which is what we do here (a single foundress nest has a 1/(total max possible group size) probability of surviving this stage.
                    foundations_survival = (   (1+sum(1-isnan(Foundations(:,7:(6+max_subordinate_group_size))),2))./(max_subordinate_group_size+1)      ) > rand(size(Foundations,1),1);
                    Foundations = Foundations(foundations_survival == 1,:);
                    % This function can easily be changed in this section if required (e.g., replaced with a sigmoid curve, etc.).
                    % For instance, I would like to come back to this and add in the redirected helpers, with the value of their help discounted according to 'relative_value_of_redirected_helpers'.
                    
                    % NOTE FOR EDITS: It would be good to model the idea I had in Maroua, of a sort of 'intermediate harshness' hypothesis: at low or high harshness, instant (though not necessarily redirected) cooperation is low. At very high harshness,
                    % nest succeess or failure may be so stochastic, regardless of group size, that the benefits of cooperation are too low. At very low harshness, the opportunity cost of becoming a helper is too high, as you could succeed alone.
                    % I think we could also illustrate this 'intermediate harshness' hypothesis with a simple analytical model.

                    % -------------------------------------------------------------------------------
                    % FOUNDRESS NESTS PROGRESS TO MATURITY (BY CLAIMING A SPOT IN THE 'WASPS' ARRAY):
                    % If no foundations survive that step, then we end the foundation section here:
                    if size(Foundations,1) > 0 

                    % A large number of foundations can be set up in a site, in the 'Foundations' array. Free nest slots on the site are filled by the available foundations (unless the site's carrying capacity is reached, at which point surplus foundations fail to secure a nest spot). The number of mature colony slots available in any site depends on the 'Wasps' array.
                    % Larger foundress groups are more successful. We therefore fill the available spaces in the 'Wasps' array in order of foundress group size.
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (10) Foundress nests progress to maturity'])                    
                    % Within each site, sort the foundations in order of group size:
                    Foundations = sortrows([Foundations (sum(1-isnan(Foundations(:,7:end)),2))], [1 size(Foundations,2)+1], {'ascend' 'descend'}); % A result of this line (besides the fact that the foundress nests are now sorted by group size) is that there is now a new column in 'Foundations' at the end, containing the group sizes.
                    
                    % Add a ranking number to the foundress nests in terms of group size:
                    A = Foundations(:,1);
                    N = diff(find([1;diff(A)~=0;1]));  Sequences_3 = cell2mat(arrayfun(@(n)(1:n).',N(:),'uni',0));      % A generic/useful line of code (from https://uk.mathworks.com/matlabcentral/answers/341223-how-to-generate-sequence-numbers) for generating a sequence of numbers (starting at 1 each time) for members of each group. Here, for each subordinate slot available within each site, so 'A' is the first column of 'Foundations'.
                    % e.g., you can see these sequences by running [InstantCooperators Sequences_2]
                    
                    % Identify how many mature/maturing colony slots are available on each site in the 'Wasps' array:
                    open_nest_spots = reshape(sum(isnan(Wasps(4,Wasps(3,:,1) == 1,:))), nSites,1);

% NEW ADDITION: If this is the first phase after a hibernation, however, all the nest spots are actually open, as all the wasps in the 'Wasps' array will actually be in hibernacula:
if Phase > 1 && IsHibernation(YearlyPhasesList(Phase-1)) == 1 && IsHibernation(YearlyPhasesList(Phase)) == 0
        open_nest_spots = ones(nSites,1)*max_NestCarryingCapacity;
end
                    
                    % Identify how many surviving foundations there are on each site:
                    [nest_counts,which_site] = groupcounts(Foundations(:,1));
                    number_of_nests = zeros(nSites,1);
                    number_of_nests(which_site) = nest_counts; 
                    
                    % The number of surviving foundations may be larger than the number of available colony slots in 'Wasps'. Therefore, the number of foundress nests to transfer to 'Wasps' from 'Foundations' is:
                    foundation_count_entering_Wasps_array = (open_nest_spots<number_of_nests).*open_nest_spots + (open_nest_spots>=number_of_nests).*number_of_nests;
                    
                    % A column vector containing the number of foundations that will enter 'Wasps' for each foundress group's site (the rows correspond to the rows of 'Foundations'):
                    total_foundation_count_entering_Wasps_for_this_site = foundation_count_entering_Wasps_array(Foundations(:,1));       
                    
                    % For the surplus foundress groups in 'Foundations' (i.e., those over the nest carrying capacity for the site): save them in a new array called 'SurplusFoundations', and eliminate them from 'Foundations':
                    SurplusFoundations = Foundations(Sequences_3 > total_foundation_count_entering_Wasps_for_this_site,:); 
                    Foundations = Foundations(total_foundation_count_entering_Wasps_for_this_site>=Sequences_3,:); % eliminate the surplus foundations from the original 'Foundations' array.

                   % We need a column vector containing the destination nest slot in 'Wasps' that this foundation will be entered into:
                                                
                            % Find the COLUMN and page numbers (i.e., site) of all open dominant positions in 'Wasps':
                            ind = find(Wasps(3,:,:) == 1 & isnan(Wasps(4,:,:)));
                            [row,col,page] = ind2sub(size(Wasps(3,:,:)), ind);
                            open_dominant_positions = [col page];
                    
% If this is the first phase after a hibernation, however, all the nest spots are biologically (even though they won't appear that way looking only at the 'Wasps' array), as all the wasps in the 'Wasps' array will actually be in hibernacula:
if Phase > 1 && IsHibernation(YearlyPhasesList(Phase-1)) == 1 && IsHibernation(YearlyPhasesList(Phase)) == 0
        ind = find(Wasps(3,:,:) == 1);
        [row,col,page] = ind2sub(size(Wasps(3,:,:)), ind);
        open_dominant_positions = [col page];
end

                            % Within each site, give the foundations a number starting from 1 up to the number of open nest spots on that site in 'Wasps':
                                        A = Foundations(:,1);
                                        N = diff(find([1;diff(A)~=0;1]));  Sequences_4 = cell2mat(arrayfun(@(n)(1:n).',N(:),'uni',0));      % A generic/useful line of code (from https://uk.mathworks.com/matlabcentral/answers/341223-how-to-generate-sequence-numbers) for generating a sequence of numbers (starting at 1 each time) for members of each group. Here, for each subordinate slot available within each site, so 'A' is the first column of 'Foundations'.
                                        % e.g., you can see these sequences by running [Foundations(:,1) Sequences_4]
                            % Similarly, number the open dominant positions:
                                        A = open_dominant_positions(:,2);
                                        N = diff(find([1;diff(A)~=0;1]));  Sequences_5 = cell2mat(arrayfun(@(n)(1:n).',N(:),'uni',0));      % A generic/useful line of code (from https://uk.mathworks.com/matlabcentral/answers/341223-how-to-generate-sequence-numbers) for generating a sequence of numbers (starting at 1 each time) for members of each group. Here, for each subordinate slot available within each site, so 'A' is the first column of 'Foundations'.
                            % Identify the COLUMN number that each dominant foundress will enter:
                                       [ida, idb] = ismember([Foundations(:,1) Sequences_4],[open_dominant_positions(:,2) Sequences_5], 'rows'); 
                                       open_dominant_positions = open_dominant_positions(idb);
                    
                    % The changes that we want to make to 'Wasps':
                            changes_to_make = [Foundations(:,4) open_dominant_positions Foundations(:,1)];
                            for subordinate = 1:max_subordinate_group_size % the subordinate list starts in column 7 of 'Foundations' and continues rightwards
                                changes_to_make = cat(1,changes_to_make,[Foundations(:,subordinate+6) open_dominant_positions+subordinate Foundations(:,1)]);
                            end
                            changes_to_make = changes_to_make(~isnan(changes_to_make(:,1)),:);
                            % Column 1 of 'changes_to_make': starting COLUMN (COLUMN of foundress in its parental nest in 'Wasps')
                            % Column 2 of 'changes_to_make': destination COLUMN (COLUMN in new foundress nest in 'Wasps' that we will move this foundress to)
                            % Column 3 of 'changes_to_make': site
                    
                    % Now return to 'Wasps' and make these changes (i.e., move the foundresses out of their parental nests and set up their new foundress nests in 'Wasps'):
                        % Following the method at: https://uk.mathworks.com/matlabcentral/answers/2000108-efficiently-moving-values-in-a-3-dimensional-array
                            start=sub2ind(  [nWasps,nSites],changes_to_make(:,1),changes_to_make(:,3)  );
                             dest=sub2ind(  [nWasps,nSites],changes_to_make(:,2),changes_to_make(:,3)  );
                            Wasps(4:end,dest) = Wasps(4:end,start);                          
                    %%
                    %toc
                    end % end of if Foundations array exists.
end % End long section that only applies if foundations have been constructed.
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (12) Ensuring that foundresses are no longer listed in their parent colony'])   
                    % ENSURE THAT FOUNDRESSES ARE NO LONGER LISTED IN THEIR PARENT COLONY:
                    % All foundresses are now set to 'NaN' in their old (parent) colony. This includes foundresses who failed. We assume that foundresses who fail, and who then fail to join an existing foundress nest as a helper.
                            identify_foundresses = sub2ind(  [nWasps,nSites],all_foundresses(:,2),all_foundresses(:,3)  ); % Using the 'all_foundresses' array from the start of the nest foundation sections.
                            Wasps(4:end,identify_foundresses)=nan; % Any wasp who attempted to become a foundress is now 'NaN' in their parental colony: their old wasp slot has opened.                
                                                            
                    %%

                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % WHO DID THE SUCCESSFUL FOUNDRESSES MATE WITH?
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (13) Identifying who the successful foundresses mated with'])  
                    %tic
                    %%
                    % The new successful lead foundresses can be identified in 'Wasps' by the fact that they:
                                        % (1) ...are in dominance position 1 on their nests (Column 3 == 1)
                                        % (2) ...still carry a '1' in their column 33 (this switches to '0' for all foundresses at the end of this section, so all older queens have a '0' in this column)
                                        % (2) ...exist as a wasp (Column 4 is not 'NaN')

                                % Therefore, the indices for the successful lead foundresses in the whole population are:        
                                idx = find(  Wasps(3,:,:)==1     &     Wasps(33,:,:)==1    &     isnan(Wasps(4,:,:))==0  );      
                                [row,col,page] = ind2sub(size(Wasps(3,:,:)),idx);          % This provides the row (wasp), column, and page (site) for the 'array'. There is only 1 column, as the array is made up of the 'column_of_interest' from Wasps.
                                successful_lead_founders = [row col page];

                                % FOUNDRESS MATING: Find the corresponding mate in the 'all_males' array produced at the end of the last phase. To simulate global male dispersal, it has already been shuffled:
                                Wasps(64:87,idx) = all_males(:,randsample(1:size(all_males,2),size(successful_lead_founders,1),true)); 

                                            % NOTE: IF INTRODUCING NEST INHERITANCE IN THE FUTURE, WILL NEED TO INCLUDE MATES FOR OTHER WASPS.
      
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % RECORD NEWLY-ESTABLISHED FOUNDRESSES AS NO LONGER PROSPECTIVE FOUNDRESSES:
                    % For every occupied wasp slot in the population, switch from '0' to '1': all hopeful foundresses in this phase have now had their attempt.
                            idx = find(Wasps(33,:,:) == 1);                
                            Wasps(33,idx) = 0; % Replace all '1' values with '0' in Column 33 of Wasps. Note: it is important that this replacement comes *after* the mating section above, because we use a '1' in row 33 there to identify the new foundresses.
                    %%
                    %toc
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % INDIVIDUAL WASPS DIE (END OF THE PHASE):
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (14) Individual wasps die'])  
                    %tic
                    %%
                    % Individual wasps die with probability 'death_rate' each phase:
                        idx = find(Wasps(30,:,:) > 0);                   % Finds the indices of all elements in row 30 (age) that have ages greater than 0 (i.e., all existing adults)    
                        [row,col,page] = ind2sub(size(Wasps(30,:,:)),idx); 
                        Wasps(89,idx) = rand(size(row,1),1) > death_rate; % Set column 89 to '1' if the wasp survives, and '0' if it dies.
                        % To find the subscript positions of these wasps, use:     
     
                    % All wasps in their 6th phase die:
                        idx = find(Wasps(30,:,:) >= 6);                     % Finds all wasps that are 6 phases old.
                        %[row,col,page] = ind2sub(size(Wasps(30,:,:)),idx);          % This provides the row (wasp), column, and page (site) for the 'array'. There is only 1 column, as the array is made up of the 'column_of_interest' from Wasps.
                        % Set column 89 to '0' for all wasps in their 5th phase:
                        Wasps(89,idx) = 0;
                            
                     % We assume that queens do not die due to stochastic individual death:
                        idx = find(Wasps(3,:,:) == 1);                 % Find all queens ('1' in row 3)  
                        % Set column 89 as '1' (survival) if you are a queen:
                        Wasps(89,idx) = 1; 
                        
                     % All wasps scheduled to die now have a '0' in row 89. We now set all their rows from 4 to the end to 'NaN' (freeing the wasp slot):   
                        idx = find(Wasps(89,:,:) == 0);
                        Wasps(4:end,idx)=nan;
                    %%
                    %toc
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % HELPER INVESTMENTS OCCUR:
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (15) Totalling helper investments'])  
                    %tic
                    %%
                    ind = find(~isnan(Wasps(4,:,:)));                               % Identifies all existing wasps in the population.
                    [row,col,page] = ind2sub(size(Wasps(4,:,:)), ind);              % Provides the wasp slot id (column, 'col') and site ('page') for each existing wasp in the population.
                    existing_wasps = [col page 100000*page+Wasps(2,sub2ind([nWasps,nSites],col,page))'];  % The third column of 'existing_wasps' lists the home colony for every individual (i.e., the mature colony or the newly secure foundress nest that they have just entered 'Wasps' in). Every colony in the population has a unique code, as earlier.
                    [group_size,which_nest]=groupcounts(existing_wasps(:,3));
                    group_size_dataset = [which_nest group_size]; % This dataset is used to plot the mean group size in the population (in figure code at the end of the phase)
                    
                    if FiguresOnOrOff == 1
                        figure(1)
                        subplot(4,4,4)
                        hist(group_size_dataset(:,2))
                    end

                    %%
                    %toc
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % WHOLE COLONIES DIE (END OF THE PHASE): 
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (16) Whole colonies die']) 
                    %tic
                    %%
                    % The colony survival function can be changed:

                            % * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *        
                            % Current candidate colony survival function is a logistic function of group size, where the minimum value is determined by EnvState:
                                                k = 0.05; % The steepness of the logistic curve.
                                                BaselineSurvival = EnvState(PhaseOfYear)/3; % The survival probability of a single-foundress colony over one phase. You can either set this as a constant or let it change depending on EnvState in the phase. If it depends on EnvState, the relative advantage (compared to smaller colonies) of being a larger colony is increased in harsher phases, amplifying the relative value of being an altruistic worker. i.e. Environmental harshness penalises smaller colonies more.
                                                MaximumSurvival = 0.9; % The survival probability of a maximum-sized colony in a maximally-benign environment.
                                                if BaselineSurvival > MaximumSurvival
                                                    BaselineSurvival = MaximumSurvival;
                                                end
                                                colony_survival_probability  = BaselineSurvival + (((MaximumSurvival-BaselineSurvival))./(1 + exp(k*((max_Wasps_Per_Colony/2)-group_size)))); 
                                                       
                                                % Add a small amount of random noise around the line:
                                                colony_survival_probability = colony_survival_probability + 0.1*randi([-1 1],size(colony_survival_probability)).*rand(size(colony_survival_probability));

                                                % To see the function:
                                                if FiguresOnOrOff == 1
                                                    figure(1)
                                                    subplot(4,4,7)
                                                    scatter(group_size, colony_survival_probability,1,'MarkerFaceAlpha',0.05,'MarkerEdgeAlpha',0.2); ylim([0 1]); xlim([0 max_Wasps_Per_Colony])
                                                    title('Colony survival') 
                                                end
                            % * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *        
        
                    % Colonies now survive or fail according to their colony survival probability:
                    colony_survival = colony_survival_probability > rand(length(colony_survival_probability),1);
                    % To see which nests have survived, use:        which_nest(~colony_survival);

                    % COLONIES THAT REACH THEIR 6TH PHASE MUST ALSO DIE (this could be relaxed in a future model incorporating serial polygyny):
                            % Find all queens who are older than 5 phases:
                            idx = find(Wasps(3,:,:) == 1 & ~isnan(Wasps(4,:,:)) & Wasps(30,:,:) > 5);
                            % Find the population-wide unique nest ID for these queens:
                            [row,col,page] = ind2sub(size(Wasps(4,:,:)),idx);
                            overage_queens = [row col page 100000*page+Wasps(2,sub2ind([nWasps,nSites],col,page))']; % The last column here provides the nest ID for this queen.
                            % Set 'colony_survival' to '0' for any colony that is over 4 phases old (i.e., has a queen that is over 4 phases old):
                            [ida, idb] = ismember(which_nest, overage_queens(:,4)); % Any colony that has an overage queen should now have a '1' in the corresponding row of 'ida'.
                            colony_survival(ida) = 0; % These colonies are now scheudled to die.

                    % All members of colonies scheduled to die are now eliminated from the population:
                            col = existing_wasps(ismember(existing_wasps(:,3),which_nest(~colony_survival)) == 1,1); % Wasp slots (columns) for wasps in colonies that are scheduled to die.
                            page = existing_wasps(ismember(existing_wasps(:,3),which_nest(~colony_survival)) == 1,2); % Identify the sites for these wasps.
                                % You can see the nest IDs using:   nest = existing_wasps(ismember(existing_wasps(:,3),which_nest(~colony_survival)) == 1,3);
                            % Set all these wasp slots back to 'NaN' using the linear index approach (https://uk.mathworks.com/matlabcentral/answers/2000108-efficiently-moving-values-in-a-3-dimensional-array):
                            wasps_in_dying_colonies=sub2ind(  [nWasps,nSites],col,page  );  % Identify the linear indices of all wasps who are scheduled to die.
                            Wasps(4:end,wasps_in_dying_colonies)=nan;                       % All members of dying colonies die. Their rows revert to 'NaN'.
          
                    % Clear variables to conserve memory:
                    clear existing_wasps;
                    %%
                    %toc
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % SURVIVING COLONIES PRODUCE DAUGHTERS: 
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (17) Surviving colonies produce daughters']) 
                    %tic
                    %%
                    % Nests of age 1 produce g1 offspring. Nests of age 2 produce g2 offspring. And so on. (The quality/condition of the offspring
                    % will depend on worker helping effort, as does nest survival to the next phase. We have not let offspring quantity
                    % depend on worker helping effort directly (though it does affect it indirectly, by increasing nest survival between phases).
                    % We can easily change that in future if required.
                    % In row 90, record the total female offspring produced by each queen:
                                % 1-phase-old nests produce 'g1' total offspring:
                                array_row30 = Wasps(30,:,:);
                                array_row3 = Wasps(3,:,:);
                                idx = find(array_row30 == 1 & array_row3 == 1); 
                                Wasps(90,idx) = g1;
                                % 2-phase-old nests produce 'g2' total offspring:
                                idx = find(array_row30 == 2 & array_row3 == 1); 
                                Wasps(90,idx) = g2;
                                % 3-phase-old nests produce 'g3' total offspring:
                                idx = find(array_row30 == 3 & array_row3 == 1); 
                                Wasps(90,idx) = g3;
                                % 4-phase-old nests produce 'g4' total offspring:
                                idx = find(array_row30 == 4 & array_row3 == 1); 
                                Wasps(90,idx) = g4;  
                                % 5-phase-old nests produce 'g5' total offspring:
                                idx = find(array_row30 == 5 & array_row3 == 1); 
                                Wasps(90,idx) = g5; 
                               
                 % Identify available slots in the population (i.e., wasp slot columns in 'Wasps' that are currently empty):
                        idx1 = find(isnan(Wasps(4,:,:))); % If the slot is available, there is no genetic information in row 4 and onwards (i.e., row 4 will be 'NaN')
                        [row,col,page] = ind2sub(size(Wasps(4,:,:)),idx1);       
                        
                        idx2 = find(Wasps(3,:,:) == 1); % Is there a queen? Find all queen slots.
                        [queen_row,queen_col,queen_page] = ind2sub(size(Wasps(3,:,:)),idx2); 
                        queen_exists = ~isnan(Wasps(4,idx2))'; % '1' if there is a queen, '0' if no queen (and hence no nest).

                        % Focus on empty slots on colonies that actually exist (i.e., available slots where there is a corresponding queen):
                        does_nest_exist = ismember([Wasps(2,idx1)' page],[Wasps(2,idx2(queen_exists))' queen_page(queen_exists)],'rows');
                        slots = [];
                        slots = [col(does_nest_exist)  Wasps(2,sub2ind([nWasps nSites],col(does_nest_exist),page(does_nest_exist)))' page(does_nest_exist)];         
                                % column 1 of 'slots': the column number (wasp slot ID) of an available spot on an actually existing colony. 
                                % Column 2 of 'slots': colony number within the site. 
                                % Column 3 of 'slots': site.

                        % Number each available slot in each colony:
                        V1 = (100000*slots(:,3)+slots(:,2)); % the unique IDs for each colony in the population
                        t = diff([0; find([diff(V1)~=0; true])]);V2 = ones(sum(t), 1);V2(cumsum(t(1:end-1))+1) = 1-t(1:end-1);V2 = cumsum(V2);  % A generic/useful line of code (from https://stackoverflow.com/questions/49780361/create-vector-which-ascends-based-on-repeated-values-of-another-vector-matlab) for generating a sequence of numbers (starting at 1 each time) for members of each group.
                        % e.g., you can see these sequences by running [new_available_slots V2]
                        
                        % How many offspring did the queen for each of these colonies produce?
                            % Because there are 'max_Wasps_Per_Colony' slots in each colony, we can find the first slot (i.e., the queen) for each colony number using:     (max_Wasps_Per_Colony*(ColonyID-1))+1
                                slot_of_corresponding_queen = (max_Wasps_Per_Colony*((slots(:,2)-1)))+1;  % e.g., [slots slot_of_corresponding_queen]
                            % Go to the 90th row of the colony's queen's wasp slot to find the number of female offspring produced:
                                females_produced = Wasps(90,sub2ind([nWasps nSites],slot_of_corresponding_queen,slots(:,3)))';

                       % A queen can only fill slots if she has produced enough daughters. Therefore, eliminate slots from consideration if their sequence number is greater than the actual number of female offspring the relevant queen has produced:
                            slots = [slots slot_of_corresponding_queen females_produced];
                            slots = slots(V2<=females_produced,:);

                       % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                       % SET AGES OF ALL NEW DAUGHTERS (PRODUCED AT THE END OF THIS PHASE) TO '0' PHASES:
                       % All wasp slots in 'slots' will now be filled in with daughters. We begin by entering a '0' into their age column, as the next phase will be their first proper adult phase (phase 1):
                       Wasps(sub2ind(size(Wasps), 30*ones(length(slots),1), slots(:,1), slots(:,3) )) = 0;
   
                       % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                       % DAUGHTERS INHERIT ALLELES FROM THEIR DIPLOID MOTHERS:

                       % Set up Mendelian segregation of alleles from the mother for all four traits for every new daughter in the population:
                            all_trait_maternal_rows = [4 6 8 10 12 14 16 18 20 22 24 26 35 37 39 41 43 45 47 49 51 53 55 57];      % rows in 'Wasps' that contain a female's maternal alleles (for the traits y, x, k, and z).
                            % Therefore, the y, x, k, and z alleles that will be received from the mother if there is a wasp in the corresponding slot (i.e., the rows of the maternal genome):
                                all_maternal_allele_rows_to_receive = all_trait_maternal_rows'+randi([0 1],24,length(slots));
                           
                        % Every daughter's inheritance of y, x, k, and z alleles from their mother queen (diploid):
                                % Take all the slots to fill in the whole population, in order, and list the Mendelian segregation for each (i.e., which row of the maternal genome will yield the relevant allele):
                                all_maternal_allele_rows_to_fill = repmat([4 6 8 10 12 14 16 18 20 22 24 26 35 37 39 41 43 45 47 49 51 53 55 57],1,length(slots))';
                                                                           % ---------------------------- % % ------------------------------- %
                                                                           % y and x maternal allele rows     k and z rows maternal allele rows
        
                                maternal_inheritance_changes_to_make = [all_maternal_allele_rows_to_receive(1:size(all_maternal_allele_rows_to_receive,1)*size(all_maternal_allele_rows_to_receive,2))' all_maternal_allele_rows_to_fill repelem(slots(:,1),24) repelem(slots(:,2),24) repelem(slots(:,3),24) repelem(slots(:,4),24)];
                                    % Columns of 'inheritance_changes_to_make':
                                            % Column 1: the source allele row to turn to in 'Wasps' for transmission at the relevant locus (i.e., randomly sampled from either the maternal or paternal row in the mother, i.e. random Mendelian segregation).
                                            % Column 2: the destination allele row to fill in in 'Wasps' for the daughter (i.e., all the fixed maternal rows for y, x, k, and z)
                                            % Column 3: the currently empty slot on this nest, which we are about to fill (i.e., the destination column in 'Wasps')
                                            % Column 4: the nest number within the site
                                            % Column 5: the site for this nest
                                            % Column 6: the column in 'Wasps' belonging to this nest's queen (i.e., the mother for the new daughter)
                                    % Every row in 'inheritance_changes_to_make' deals with a different gene locus.
                                 
                                    maternal_inheritance_start=sub2ind(  size(Wasps),       maternal_inheritance_changes_to_make(:,1),maternal_inheritance_changes_to_make(:,6),maternal_inheritance_changes_to_make(:,5)  );
                                                                                            % Source allele row.                      % Mother column (queen).                  % Site for this nest.
                                     maternal_inheritance_dest=sub2ind(  size(Wasps),       maternal_inheritance_changes_to_make(:,2),maternal_inheritance_changes_to_make(:,3),maternal_inheritance_changes_to_make(:,5)  );
                                                                                            % Destination allele row.                 % Destination wasp slot.                  % Site for this nest.   
                                        Wasps(maternal_inheritance_dest) = Wasps(maternal_inheritance_start);
                    
                         % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                         % DAUGHTERS INHERIT ALLELES FROM THEIR HAPLOID FATHERS:

                         % Every daughter's inheritance of y, x, k, and z alleles from their father (haploid):
                                % Father's alleles are in these rows (in the queen's column): 
                                all_paternal_allele_source_rows = repmat([64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87],1,length(slots))';    % the rows in 'Wasps' that contain each queen's mate's alleles (for the traits y, x, k, and z), which are in each queen's column. These are the fathers for the daughters we are working on.
                                                                          % -------------------------------- % % ------------------------------- %
                                                                          % Father's y and x allele rows         Father's k and z rows allele rows
        
                                % The daughter's paternally-inherited alleles will go into these rows (in the daughter's own column):
                                all_trait_paternal_rows_to_fill = repmat([5 7 9 11 13 15 17 19 21 23 25 27 36 38 40 42 44 46 48 50 52 54 56 58],1,length(slots))';      % rows in 'Wasps' that will each daughter's paternal alleles (for the traits y, x, k, and z).
                                                                          % ---------------------------- % % -------------------------------- %
                                                                          % y and x paternal allele rows    k and z rows paternal allele rows
                                
                                % Set up the array listing the changes to make to process inheritance of alleles from the haploid father:
                                 paternal_inheritance_changes_to_make = [all_paternal_allele_source_rows all_trait_paternal_rows_to_fill repelem(slots(:,1),24) repelem(slots(:,2),24) repelem(slots(:,3),24) repelem(slots(:,4),24)];
                                    % Columns of 'inheritance_changes_to_make':
                                            % Column 1: the source allele row to turn to in 'Wasps' for transmission at the relevant locus
                                            % Column 2: the destination allele row to fill in in 'Wasps' for the daughter
                                            % Column 3: the currently empty slot on this nest, which we are about to fill (i.e., the destination column in 'Wasps')
                                            % Column 4: the nest number within the site
                                            % Column 5: the site for this nest
                                            % Column 6: the column in 'Wasps' belonging to this nest's queen (i.e., the mother for the new daughter). This is used for finding the father's allele, as a queen's mate's alleles are stored in that queen's column.
                                    % Every row in 'inheritance_changes_to_make' deals with a different gene locus.
                                 
                                    paternal_inheritance_start=sub2ind(  size(Wasps),       paternal_inheritance_changes_to_make(:,1),  paternal_inheritance_changes_to_make(:,6),  paternal_inheritance_changes_to_make(:,5)  );
                                                                                            % Source allele row.                        % Queen's column.                           % Site for this nest.
                                     paternal_inheritance_dest=sub2ind(  size(Wasps),       paternal_inheritance_changes_to_make(:,2),  paternal_inheritance_changes_to_make(:,3),  paternal_inheritance_changes_to_make(:,5)  );
                                                                                            % Destination allele row.                   % Destination wasp slot.                    % Site for this nest.   
                                        Wasps(paternal_inheritance_dest) = Wasps(paternal_inheritance_start);

                    %%
                    %toc
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % EACH DAUGHTER'S BODY CONDITION DEPENDS ON HER EXPERIENCES DURING DEVELOPMENT: HELPING EFFORT AND ENVIRONMENTAL STATE
                    %tic
                    %%
                            % Group size (helping effort) for each parental colony was calculated above:

                            % Recall that each parental colony has a population-wide unique ID given by (100000*Site)+(Site specific colony number).

                            % For each new daughter, find the group size that she experienced during development:
                                        % Turn to the 'slots' array, which contains the subscript locations for all the new daughters.
                                        % For each wasp in the 'slots' array, find the group size of helpers during its development, using the 'group_size_dataset' obtained earlier:
                                        parental_colony_unique_ID = 100000*slots(:,3)+slots(:,2);
                                        % For each of these wasps, the group size during its development was:
                                        [ida, idb] = ismember(parental_colony_unique_ID,group_size_dataset(:,1));
                                        group_size_during_development = group_size_dataset(idb(ida),2);
                                        % i.e., see: [parental_colony_unique_ID group_size_during_development]

                                        % Find the linear indices for the cells in 'Wasps' where we will insert body condition values (row 28) for all the daughters from the 'slots' array:
                                        ind_of_new_daughters = sub2ind(size(Wasps), 28*ones(size(slots,1),1),slots(:,1), slots(:,3));
                                                % e.g., you can see these indices using: [slots ind]
                                        
                                    % The body condition function depends on the helper group size during your development but also on environmental conditions.
                                    % You can change the chosen function. Here, we use:

                                            % * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *        
                                            % Current body condition survival function is a logistic function of group size, where the minimum value is determined by EnvState:
                                                        k = 0.1; % The steepness of the logistic curve.
                                                        BaselineBodyCondition = EnvState(PhaseOfYear)/3; % You can either set this as a constant or let it change depending on EnvState in the phase. If it depends on EnvState, the relative advantage (compared to smaller colonies) of being raised in a larger colony is increased in harsher phases.
                                                        MaximumBodyCondition = 1; 
                                                        if MaximumBodyCondition > 1
                                                            MaximumBodyCondition = 1;
                                                        end
                                                        if BaselineBodyCondition > MaximumBodyCondition
                                                            BaselineBodyCondition = MaximumBodyCondition;
                                                        end
                                                        InflectionPoint = (max_Wasps_Per_Colony/2);
                                                        Wasps(ind_of_new_daughters) = BaselineBodyCondition + (MaximumBodyCondition-BaselineBodyCondition)./(1 + exp(k*(InflectionPoint-group_size_during_development)));  % This is the current body condition function.
                                                       
                                                        % Add a small amount of random noise around the line:
                                                        Wasps(ind_of_new_daughters) = Wasps(ind_of_new_daughters) + 0.1*randi([-1 1],size(ind_of_new_daughters)).*rand(size(ind_of_new_daughters));

                                                        % To see the function, use:         
                                                        if FiguresOnOrOff == 1
                                                            figure(1)
                                                            subplot(4,4,8)
                                                            scatter(group_size_during_development,Wasps(ind_of_new_daughters),1,'MarkerFaceAlpha',0.05,'MarkerEdgeAlpha',0.2); ylim([0 1]); xlim([0 max_Wasps_Per_Colony])
                                                            title('Daughter body condition') 
                                                        end
                                            % * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *        
                    %%
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % MALE GENOMES, DISPERSAL, AND INTRODUCTION OF MUTATIONS:       
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (18) Male genomes, dispersal, and introduction of mutations']) 
                    %tic
                    %%
                    %toc
% THIS SECTION IS NOT 100% PERFECT YET: THERE IS NO MENDELIAN SEGREGATION IN THE TRANSMISSION OF ALLELES FROM MOTHERS TO SONS! THEY CURRENTLY EITHER GET THE WHOLE MATERNAL ALLELE SET IN THE MOTHER OR THE WHOLE PATERNAL ALLELE SET IN THE MOTHER!

                    % We assume complete mixing (global dispersal) male dispersal in the landscape.
                    % We assume that only colonies (i.e., queens) that survive to late maturity (phases 3 and above) produce males (another benefit of cooperation enabling colony survival).
                    % We assume that all male-producing queens produce the same number of males.
                    
                    % Generate representative male genomes by sampling from all queens greater than 2 phases old in the whole population:
                           idx = find(Wasps(3,:,:) == 1 & Wasps(30,:,:) > 2 & isnan(Wasps(4,:,:)) == 0); 
                           if ~isempty(idx) % We assume males are only produced if there are queens greater than 2 phases old to produce them (this is not the case, for instance, in the spring in South Africa):
                                                   [col page] = ind2sub([nWasps nSites],idx); 
                                                   maternal_alleles = Wasps([all_trait_maternal_rows],sub2ind([nWasps nSites], col, page));
                                                   all_trait_paternal_rows = [5 7 9 11 13 15 17 19 21 23 25 27 36 38 40 42 44 46 48 50 52 54 56 58];
                                                   paternal_alleles = Wasps([all_trait_paternal_rows],sub2ind([nWasps nSites], col, page));
                                                   all_males = [maternal_alleles paternal_alleles maternal_alleles paternal_alleles];    
                                                   
                                                   % Shuffle all the male columns randomly, to ensure global random dispersal:
                                                   start = find(all_males(1,:,:) >= 0); % starting columns
                                                   dest = randperm(size(all_males,2),size(all_males,2)); % destination columns
                                                   all_males(:,dest) = all_males(:,start);
                        
                                                   % Introduce mutations to the population by adding or subtracting small increments to alleles in males with low probability:
                                                               larger_mutation_probability = 0.01;
                                                               larger_mutation_size = 0.1;
                                                               smaller_mutation_probability = 0.05;
                                                               smaller_mutation_size = (rand()/10);
                                    
                                                   % Larger mutations:
                                                               % Use linear indices of all alleles in the 'all_males' array to select a random subset of alleles to receive a larger mutation:
                                                               idx = find(all_males);
                                                               number_of_alleles_for_larger_mutatation = round(larger_mutation_probability*length(idx));
                                                               chosen_indices = randperm(max(idx),number_of_alleles_for_larger_mutatation)';
                                                               
                                                               % Apply positive larger mutations to this random set of alleles in males:
                                                               up_or_down = randsample([-1, 1],number_of_alleles_for_larger_mutatation,true)'; % whether the mutation will be negative or positive
                                                              
                                                               % The mutations to make:
                                                               larger_mutations = [all_males(chosen_indices)     all_males(chosen_indices)+larger_mutation_size.*up_or_down];
                                                               % Eliminate impossible mutations (i.e., mutations that would result in allele values greater than 1 or less than 0:
                                                               larger_mutations(larger_mutations(:,2) < 0,2) = 0;
                                                               larger_mutations(larger_mutations(:,2) > 1,2) = 1;
                        
                                                               % Apply the mutations:
                                                               all_males(chosen_indices) = larger_mutations(:,2);
                        
                                                    % Smaller mutations:
                                                               % Use linear indices of all alleles in the 'all_males' array to select a random subset of alleles to receive a smaller mutation:
                                                               idx = find(all_males);
                                                               number_of_alleles_for_smaller_mutatation = round(smaller_mutation_probability*length(idx));
                                                               chosen_indices = randperm(max(idx),number_of_alleles_for_smaller_mutatation)';
                                                               
                                                               % Apply positive larger mutations to this random set of alleles in males:
                                                               up_or_down = randsample([-1, 1],number_of_alleles_for_smaller_mutatation,true)'; % whether the mutation will be negative or positive
                                                              
                                                               % The mutations to make:
                                                               smaller_mutations = [all_males(chosen_indices)     all_males(chosen_indices)+smaller_mutation_size.*up_or_down];
                                                               % Eliminate impossible mutations (i.e., mutations that would result in allele values greater than 1 or less than 0:
                                                               smaller_mutations(smaller_mutations(:,2) < 0,2) = 0;
                                                               smaller_mutations(smaller_mutations(:,2) > 1,2) = 1;
                        
                                                               % Apply the mutations:
                                                               all_males(chosen_indices) = smaller_mutations(:,2);
                           end % end of male production.                            
                    % The list of males ('all_males') is used in the next phase for finding the mates for the new foundresses.
                    %%            
                    %toc                                               
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    % INCREMENT ALL AGES BY +1:
                    disp(['Current Phase: ',num2str(Phase),'. Current section: (19) Incrementing ages by +1']) 
                    idx = find(~isnan(Wasps(30,:,:)));
                    Wasps(30,idx) = Wasps(30,idx) + 1; 
                    % The increment only occurs during 'livable' phases (i.e., not hibernation/torpor phases).
                    % ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    
% Plot spatial overview of the population:
if FiguresOnOrOff == 1
    figure(1)
    subplot(4,4,9)
    Angle_spatial_sites = linspace(0,2*pi,nSites)';
    NaN_per_site = sum(reshape((isnan(Wasps(4,:,:))), [], size(Wasps(4,:,:), 3)))';
    Radius_sites = nWasps-NaN_per_site;
    tbl = table(Angle_spatial_sites,Radius_sites);
    polarplot(tbl,"Angle_spatial_sites","Radius_sites")
    rlim([0 400]);
    pause(0.001)
end

% ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Plot panel of polar plots:
%%
% Save data for plotting:
foundations_Radius(Phase) = mean(number_of_nests); % The value 'foundations_Radius(Phase)' is used at the end of the phase to plot the number of foundations that were established.
             
if FiguresOnOrOff == 1
    figure(888)
    subplot(1,3,1)
    % PLOT MEAN GROUP SIZE IN THE POPULATION:
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
    mean_group_size(Phase) = mean(group_size);
    if Phase > 6
        set(gcf,'color','w');
        set(gca, 'color', 'none');
            angle_increments = (0:1.0472:((Phase-1)*1.0472))';                            
            theta_new = linspace(0, max(angle_increments), 360*(Phase/6));
            theta_new = (0:0.05:((Phase-1)*1.0472))';   
            r_new = interp1(angle_increments(1:Phase), mean_group_size(1:Phase), theta_new, 'linear', 'extrap');
            polarplot(theta_new,r_new, Color =[0,1,1, 0.1]); % The last value is the transparency.
            thetaticks(30:60:390);
            thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'})
            rlim([0 max_Wasps_Per_Colony]);
            ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
            ax.RAxisLocation = -30;
            set(gca, 'GridColor', "black", 'GridAlpha', 1);
            ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
            pause(0.001)
    end  
    hold off
figure(888)
subplot(1,3,2)
    % PLOT BODY CONDITION OF ALL THE NEW DAUGHTERS PRODUCED DURING THIS PHASE (THE MEMBERS OF THE 'SLOTS' ARRAY, WHO ARE IN THEIR PHASE 0)
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
            median_body_condition(Phase) = median(Wasps(ind_of_new_daughters));
            if Phase > 6
                set(gcf,'color','w');
                    angle_increments = (0:1.0472:((Phase-1)*1.0472))';                            
                    theta_new = linspace(0, max(angle_increments), 360*(Phase/6));
                    theta_new = (0:0.05:((Phase-1)*1.0472))';   
                    r_new = interp1(angle_increments(1:Phase), median_body_condition(1:Phase), theta_new, 'linear', 'extrap');
                    figure101 = polarplot(theta_new,r_new, Color =[0,1,1, 0.1]); % The last value is the transparency.
                    thetaticks(30:60:390);
                    thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'})
                    rticks([0.1 0.5 1.0])
                    rtickangle(60)
                    rlim([0 1]);
                    ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                    ax.RAxisLocation = -30;
                    set(gca, 'GridColor', "black", 'GridAlpha', 1);
                    ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                    pause(0.001)
            end  
            hold off         
figure(888)
subplot(1,3,3)
 % PLOT OF NUMBER OF MEAN SURVIVING FOUNDRESS NESTS PER SITE:
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
                if Phase > 6
                    set(gcf,'color','w');
                        angle_increments = (0:1.0472:((Phase-1)*1.0472))';                            
                        theta_new = linspace(0, max(angle_increments), 360*(Phase/6));
                        theta_new = (0:0.05:((Phase-1)*1.0472))';   
                        r_new1 = interp1(angle_increments(1:Phase), foundations_Radius(1:Phase), theta_new, 'linear', 'extrap');
                        polarplot(theta_new,r_new1, Color =[0,1,1, 0.1]); % The last value is the transparency.
                        thetaticks(30:60:390);
                        thetaticklabels({'Mar','May','Jul','Sep','Nov','Jan'})
                        rlim([0 max(foundations_Radius((Phase-6):Phase))]);
                        ax = gca; % "Get a handle to the polar plot axes" (https://uk.mathworks.com/matlabcentral/answers/291120-set-the-location-of-r-axis-labels-using-polar-in-matlab-r2016a)
                        ax.RAxisLocation = -30;
                        set(gca, 'GridColor', "black", 'GridAlpha', 1);
                        ax.RGrid = "off"; % set to "on" if you want to include the inner grid circles
                        pause(0.001)
                end   
                hold off
end
%%
% ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        end % end if statement for non-hibernation/non-torpor phases.
end % end phase.   
toc; % end timer

% Print completion message:
"This simulation run has now completed running."

% ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% EXPORT OUTPUTS (PARTICULARLY IF ON HPC):

% Specify the outputs to save:

    % Record the phase types for the last 20% of phases:
                YearlyPhasesList_LastSection = YearlyPhasesList(round(0.8*TotalPhases):end); % take final 20% of phases

    % Sample the final 20% of years for relatednesses:
                Relatednesses_LastSection = whole_year_relatedness_tracker(round(0.8*TotalYears):end);

    % Average foundress relatedness in the last 20% of phases...:
                % ...in Phase 1:
                Final_AverageFoundressRelatedness_Phase1 = nanmean(Relatednesses_LastSection(YearlyPhasesList_LastSection == 1));
                % ...in Phase 2:
                Final_AverageFoundressRelatedness_Phase2 = nanmean(Relatednesses_LastSection(YearlyPhasesList_LastSection == 2));
                % ...in Phase 3:
                Final_AverageFoundressRelatedness_Phase3 = nanmean(Relatednesses_LastSection(YearlyPhasesList_LastSection == 3));
                % ...in Phase 4:
                Final_AverageFoundressRelatedness_Phase4 = nanmean(Relatednesses_LastSection(YearlyPhasesList_LastSection == 4));
                % ...in Phase 5:
                Final_AverageFoundressRelatedness_Phase5 = nanmean(Relatednesses_LastSection(YearlyPhasesList_LastSection == 5));
                % ...in Phase 6:
                Final_AverageFoundressRelatedness_Phase6 = nanmean(Relatednesses_LastSection(YearlyPhasesList_LastSection == 6));
               
        % Final annual mean foundress relatedness (unweighted - you can calculate the weighted value in the output processing script):
        Final_AnnualMeanRelatednessUnweighted = mean(whole_year_relatedness_tracker(round(0.8*TotalYears):end)); % take the average of 'whole_year_relatedness_tracker' for the final 20% of simulated years (when simulation is likely to have reached equilibrium values).

    % Sample the final 20% of phases for the following:
    HigherConditionFoundressPhenotype_LastSection = HigherConditionFoundressPhenotype(round(0.8*TotalPhases):end); % take final 20% of phases
    LowerConditionFoundressPhenotype_LastSection = LowerConditionFoundressPhenotype(round(0.8*TotalPhases):end); % take final 20% of phases
    foundations_Radius_LastSection = foundations_Radius(round(0.8*TotalPhases):end); % take final 20% of phases
    HopefulFounderCountTracker_LastSection = HopefulFounderCountTracker(round(0.8*TotalPhases):end); % take final 20% of phases
    InstantCooperatorCountTracker_LastSection = InstantCooperatorCountTracker(round(0.8*TotalPhases):end); % take final 20% of phases
    RedirectedHelperCountTracker_LastSection = RedirectedHelperCountTracker(round(0.8*TotalPhases):end); % take final 20% of phases

        % Probability of becoming a foundress for higher condition wasps:
        % ...in Phase 1:
        Final_HigherConditionFoundressPhenotype_Phase1 = mean(HigherConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 1));
        % ...in Phase 2:
        Final_HigherConditionFoundressPhenotype_Phase2 = mean(HigherConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 2));
        % ...in Phase 3:
        Final_HigherConditionFoundressPhenotype_Phase3 = mean(HigherConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 3));
        % ...in Phase 4:
        Final_HigherConditionFoundressPhenotype_Phase4 = mean(HigherConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 4));
        % ...in Phase 5:
        Final_HigherConditionFoundressPhenotype_Phase5 = mean(HigherConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 5));
        % ...in Phase 6:
        Final_HigherConditionFoundressPhenotype_Phase6 = mean(HigherConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 6));
        
        % Probability of becoming a foundress for lower condition wasps:
        % ...in Phase 1:
        Final_LowerConditionFoundressPhenotype_Phase1 = mean(LowerConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 1));
        % ...in Phase 2:
        Final_LowerConditionFoundressPhenotype_Phase2 = mean(LowerConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 2));
        % ...in Phase 3:
        Final_LowerConditionFoundressPhenotype_Phase3 = mean(LowerConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 3));
        % ...in Phase 4:
        Final_LowerConditionFoundressPhenotype_Phase4 = mean(LowerConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 4));
        % ...in Phase 5:
        Final_LowerConditionFoundressPhenotype_Phase5 = mean(LowerConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 5));
        % ...in Phase 6:
        Final_LowerConditionFoundressPhenotype_Phase6 = mean(LowerConditionFoundressPhenotype_LastSection(YearlyPhasesList_LastSection == 6));
        
        % Record the mean number of foundations established in each phase (the variable 'foundations_Radius' above):
        % ...in Phase 1:
        Final_foundations_Radius_Phase1 = mean(foundations_Radius_LastSection(YearlyPhasesList_LastSection == 1));
        % ...in Phase 2:
        Final_foundations_Radius_Phase2 = mean(foundations_Radius_LastSection(YearlyPhasesList_LastSection == 2));
        % ...in Phase 3:
        Final_foundations_Radius_Phase3 = mean(foundations_Radius_LastSection(YearlyPhasesList_LastSection == 3));
        % ...in Phase 4:
        Final_foundations_Radius_Phase4 = mean(foundations_Radius_LastSection(YearlyPhasesList_LastSection == 4));
        % ...in Phase 5:
        Final_foundations_Radius_Phase5 = mean(foundations_Radius_LastSection(YearlyPhasesList_LastSection == 5));
        % ...in Phase 6:
        Final_foundations_Radius_Phase6 = mean(foundations_Radius_LastSection(YearlyPhasesList_LastSection == 6));

        % Record the average number of hopeful lead founders:
        % ...in Phase 1:
        Final_Average_HopefulLeadFounderCountTracker_Phase1 = mean(HopefulFounderCountTracker_LastSection(YearlyPhasesList_LastSection == 1));
        % ...in Phase 2:
        Final_Average_HopefulLeadFounderCountTracker_Phase2 = mean(HopefulFounderCountTracker_LastSection(YearlyPhasesList_LastSection == 2));
        % ...in Phase 3:
        Final_Average_HopefulLeadFounderCountTracker_Phase3 = mean(HopefulFounderCountTracker_LastSection(YearlyPhasesList_LastSection == 3));
        % ...in Phase 4:
        Final_Average_HopefulLeadFounderCountTracker_Phase4 = mean(HopefulFounderCountTracker_LastSection(YearlyPhasesList_LastSection == 4));
        % ...in Phase 5:
        Final_Average_HopefulLeadFounderCountTracker_Phase5 = mean(HopefulFounderCountTracker_LastSection(YearlyPhasesList_LastSection == 5));
        % ...in Phase 6:
        Final_Average_HopefulLeadFounderCountTracker_Phase6 = mean(HopefulFounderCountTracker_LastSection(YearlyPhasesList_LastSection == 6));
         
        % Record the average number of instant cooperators:
        % ...in Phase 1:
        Final_Average_InstantCooperatorCountTracker_Phase1 = mean(InstantCooperatorCountTracker_LastSection(YearlyPhasesList_LastSection == 1));
        % ...in Phase 2:
        Final_Average_InstantCooperatorCountTracker_Phase2 = mean(InstantCooperatorCountTracker_LastSection(YearlyPhasesList_LastSection == 2));
        % ...in Phase 3:
        Final_Average_InstantCooperatorCountTracker_Phase3 = mean(InstantCooperatorCountTracker_LastSection(YearlyPhasesList_LastSection == 3));
        % ...in Phase 4:
        Final_Average_InstantCooperatorCountTracker_Phase4 = mean(InstantCooperatorCountTracker_LastSection(YearlyPhasesList_LastSection == 4));
        % ...in Phase 5:
        Final_Average_InstantCooperatorCountTracker_Phase5 = mean(InstantCooperatorCountTracker_LastSection(YearlyPhasesList_LastSection == 5));
        % ...in Phase 6:
        Final_Average_InstantCooperatorCountTracker_Phase6 = mean(InstantCooperatorCountTracker_LastSection(YearlyPhasesList_LastSection == 6));
         
        % Record the average number of redirected helpers:
        % ...in Phase 1:
        Final_Average_RedirectedHelperCountTracker_Phase1 = mean(RedirectedHelperCountTracker_LastSection(YearlyPhasesList_LastSection == 1));
        % ...in Phase 2:
        Final_Average_RedirectedHelperCountTracker_Phase2 = mean(RedirectedHelperCountTracker_LastSection(YearlyPhasesList_LastSection == 2));
        % ...in Phase 3:
        Final_Average_RedirectedHelperCountTracker_Phase3 = mean(RedirectedHelperCountTracker_LastSection(YearlyPhasesList_LastSection == 3));
        % ...in Phase 4:
        Final_Average_RedirectedHelperCountTracker_Phase4 = mean(RedirectedHelperCountTracker_LastSection(YearlyPhasesList_LastSection == 4));
        % ...in Phase 5:
        Final_Average_RedirectedHelperCountTracker_Phase5 = mean(RedirectedHelperCountTracker_LastSection(YearlyPhasesList_LastSection == 5));
        % ...in Phase 6:
        Final_Average_RedirectedHelperCountTracker_Phase6 = mean(RedirectedHelperCountTracker_LastSection(YearlyPhasesList_LastSection == 6));
         
        % Collate these outputs into a single row vector:
        this_Simulation_Outputs_Vector = [ThisSimulationNumber; % Column 1
             Final_AnnualMeanRelatednessUnweighted; % Column 2                      
             Final_HigherConditionFoundressPhenotype_Phase1; % Column 3
             Final_HigherConditionFoundressPhenotype_Phase2; % Column 4
             Final_HigherConditionFoundressPhenotype_Phase3; % Column 5
             Final_HigherConditionFoundressPhenotype_Phase4; % Column 6
             Final_HigherConditionFoundressPhenotype_Phase5; % Column 7
             Final_HigherConditionFoundressPhenotype_Phase6; % Column 8
             Final_LowerConditionFoundressPhenotype_Phase1; % Column 9
             Final_LowerConditionFoundressPhenotype_Phase2; % Column 10
             Final_LowerConditionFoundressPhenotype_Phase3; % Column 11
             Final_LowerConditionFoundressPhenotype_Phase4; % Column 12
             Final_LowerConditionFoundressPhenotype_Phase5; % Column 13
             Final_LowerConditionFoundressPhenotype_Phase6; % Column 14
             Final_foundations_Radius_Phase1; % Column 15
             Final_foundations_Radius_Phase2; % Column 16
             Final_foundations_Radius_Phase3; % Column 17
             Final_foundations_Radius_Phase4; % Column 18
             Final_foundations_Radius_Phase5; % Column 19
             Final_foundations_Radius_Phase6]'; % Column 20
             Final_AverageFoundressRelatedness_Phase1; % Column 21
             Final_AverageFoundressRelatedness_Phase2; % Column 22
             Final_AverageFoundressRelatedness_Phase3; % Column 23
             Final_AverageFoundressRelatedness_Phase4; % Column 24
             Final_AverageFoundressRelatedness_Phase5; % Column 25
             Final_AverageFoundressRelatedness_Phase6; % Column 26
             Final_Average_HopefulLeadFounderCountTracker_Phase1; % Column 27
             Final_Average_HopefulLeadFounderCountTracker_Phase2; % Column 28
             Final_Average_HopefulLeadFounderCountTracker_Phase3; % Column 29
             Final_Average_HopefulLeadFounderCountTracker_Phase4; % Column 30
             Final_Average_HopefulLeadFounderCountTracker_Phase5; % Column 31
             Final_Average_HopefulLeadFounderCountTracker_Phase6; % Column 32
             Final_Average_InstantCooperatorCountTracker_Phase1; % Column 33
             Final_Average_InstantCooperatorCountTracker_Phase2; % Column 34
             Final_Average_InstantCooperatorCountTracker_Phase3; % Column 35
             Final_Average_InstantCooperatorCountTracker_Phase4; % Column 36
             Final_Average_InstantCooperatorCountTracker_Phase5; % Column 37
             Final_Average_InstantCooperatorCountTracker_Phase6; % Column 38
             Final_Average_RedirectedHelperCountTracker_Phase1; % Column 39
             Final_Average_RedirectedHelperCountTracker_Phase2; % Column 40
             Final_Average_RedirectedHelperCountTracker_Phase3; % Column 41
             Final_Average_RedirectedHelperCountTracker_Phase4; % Column 42
             Final_Average_RedirectedHelperCountTracker_Phase5; % Column 43
             Final_Average_RedirectedHelperCountTracker_Phase6; % Column 44

% To find the final average foundress relatednesses as a weighted average of the number of foundations in each phase, you can multiply the average relatednesses
% in each phase by the 'foundations_Radius' in that phase, when you process the outputs in 'Processing_HPC_MATLAB_outputs.m'.

% Clear everything except variables of interest (to reduce the file size of the resulting output MAT file):
clearvars -except this_Simulation_Outputs_Vector foundations_Radius HigherConditionFoundressPhenotype LowerConditionFoundressPhenotype mean_group_size median_body_condition NewHopefulLeadFounderAverageCondition NewInstantCooperatorAverageCondition NewWorkerAverageCondition PleometrosisPhenotype relatedness_tracker sister_nest_tracker YearlyPhasesList

% Save and export the output to a MAT file:        
save('MATLAB_Output_SimulationID_"SimID".mat')

% Print report:
"Outputs from this simulation have now been saved in a MAT file."

% ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
quit; % end MATLAB (this is necessary for finishing the job if running on HPC. Comment out this line if running on the local computer; otherwise, it will shut down MATLAB.
