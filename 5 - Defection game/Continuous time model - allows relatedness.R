# PK
# THE DEFECTION GAME

# AN IDEA: For a sanity check to make sure that we aren't seeing spurious patterns,
# we could do a 'null' run where we randomise the rows in 'my_data'. If the model is
# detecting genuine effects, they should vanish when we run the 'null' randomised
# model, and the predictors' 95% credible intervals should overlap zero. Try it and see?

# ---------------------------------------------------------------------
# CHOOSE WHETHER OR NOT TO INCLUDE RELATEDNESS:

# Type '1' to include relatedness (which therefore changes the model code and
# drops all trials for which there are no relatedness estimates). Otherwise, type '0':
IncludeRelatedness = 0

                    # If including relatedness, there is a potential bias introduced by the fact that relatedness is strongly correlated/colinear
                    # with country. Almost all relatednesses are full-sister within the South African trials, whilst there is a lot of variation
                    # within the Cameroonian trials. It may be inappropriate to include country in a model exploring the effects of relatedness.
                    # To restrict the relatedness analysis only to Cameroon (where there is much more variation), set IncludeBothCountries to zero:
                    IncludeBothCountries = 1

# If including relatedness, you need to supply the relatedness values (average relatedness on each colony). Before running this script,
# you should run 'Processing_relatedness_output.R'. Within that script, a dataframe
# containing mean relatedness within each trial is generated ('MeanParticipantRelatedness').

# ---------------------------------------------------------------------

# Import the transitions dataset to R and name it 'my_data':
my_data <- Transitions_table_ToImportToR

# Remove all rows that are not transitions:
my_data <- my_data[!grepl("Not_a_transition", my_data$Observation_k),]
View(my_data)

# Make sure that interval time columns are in numeric format:
my_data$AbsoluteIntervalTime <- as.numeric(my_data$AbsoluteIntervalTime)
my_data$IntervalTime <- as.numeric(my_data$IntervalTime)
my_data$TimeSinceTrialStart <- as.numeric(my_data$TimeSinceTrialStart)

# Remove all intervals that are shorter than 5 minutes:
my_data <- subset(my_data, AbsoluteIntervalTime>(5/60))

# Total number of retained transitions:
dim(my_data)[[1]]

# Total number of retained trials:
length(unique(my_data$Trial))

# Make sure that the e columns are in numeric format:
my_data$e11 <- as.numeric(my_data$e11); my_data$e12 <- as.numeric(my_data$e12); my_data$e13 <- as.numeric(my_data$e13); my_data$e14 <- as.numeric(my_data$e14)
my_data$e21 <- as.numeric(my_data$e21); my_data$e22 <- as.numeric(my_data$e22); my_data$e23 <- as.numeric(my_data$e23); my_data$e24 <- as.numeric(my_data$e24)
my_data$e31 <- as.numeric(my_data$e31); my_data$e32 <- as.numeric(my_data$e32); my_data$e33 <- as.numeric(my_data$e33); my_data$e34 <- as.numeric(my_data$e34)
my_data$e41 <- as.numeric(my_data$e41); my_data$e42 <- as.numeric(my_data$e42); my_data$e43 <- as.numeric(my_data$e43); my_data$e44 <- as.numeric(my_data$e44)

# -----------------------------------------------------------------------------
# IMPORT THE TRIAL INFO TABLE:

# Copy-paste the 'Trial_info_table' sheet of the Supplementary Material Excel file into
# its own Excel file (called 'Trial_info_table'), and then import it into R:

View(Trial_info_table) 

# -----------------------------------------------------------------------------
# Choose whether you want to exclude data after the first 3 days:
# IF YES, RUN THESE TWO LINES. IF YOU WANT TO INCLUDE ALL DATA, REGARDLESS OF TIMEPOINT, COMMENT THEM OUT:
##            Time_Threshold <- 24*3
##            my_data <- subset(my_data, TimeSinceTrialStart < Time_Threshold)
# I think we should present both results side by side.

# -----------------------------------------------------------------------------
# INCLUDING RELATEDNESSES:

if (IncludeRelatedness == 1){
  my_data <- merge(my_data, MeanParticipantRelatednesses, by.x = "Trial", by.y = "Trial")
  mean_relatedness <- mean(as.numeric(my_data$MeanRelatedness))
  colony_relatedness <- as.numeric(my_data$MeanRelatedness)
}

if (IncludeRelatedness == 0){
  mean_relatedness <- 0 # If we are not including relatedness, we just set this value to zero. Not because
  # there will be genuine zero relatedness, but so that it drops out of the model script below.
  colony_relatedness <- numeric(dim(my_data)[1]) # As in the line above, this is so that the relatedness term just vanishes
  # from the model code if we are not including relatedness. It is not assuming that trials have zero relatedness.
  # The code here just creates a vector of zeros (with the right length for the dataset).
}

# If only including Cameroon:
if (IncludeBothCountries == 0){
  my_data <- subset(my_data, Country == "Cameroon")
}

# -----------------------------------------------------------------------------

# Load libraries:
library(rjags)
library(readxl)
library(dplyr)

# Load "msm" module in RJAGS, which is needed for the mexp() function:
load.module("msm")

# Extract the values for the e array:
e_array_all <- select(my_data, e11, e12, e13, e14, e21, e22, e23, e24, e31, e32, e33, e34, e41, e42, e43, e44)

NumberOfRows <- dim(e_array_all)[1]
myStack <- stack(e_array_all)
e <- array(myStack$values, dim = c(NumberOfRows,4,4))
# Now, you can get any interval-observation's transition data (e.g., for observation 88, use e.array[88,,])

K <- NumberOfRows

n <- array(0,dim=c(K,4)) # (Sets up an array 'n' to hold the following line.)
for (k in 1:K){ for (i in 1:4) { n[k, i] <- sum(e[k, i, 1:4]) }  }

ColonyTotal = length(levels(as.factor(my_data$Trial)))

# Make a new column, containing a unique number code for each colony trial:
my_data$ColonyNumberCode = as.numeric(factor(my_data$Trial))

# Do the same for the two countries, but where Cameroon is one and South Africa is zero:
my_data$CountryCode = as.numeric(c("Cameroon" = "1", "South Africa" = "0")[my_data$Country])

# JAGS hits the 'log density' error for the very long time intervals. We therefore censor the small number of observations
# that are greater than 100 hours to 100 (that includes the maximum one, which is 449 hours) to enable
# fitting the model successfully:
my_data$IntervalTime <- as.numeric(my_data$IntervalTime)
my_data$intervaltime_censored = ifelse(my_data$IntervalTime>100, 100, my_data$IntervalTime)

# The number of censored intervals:
dim(subset(my_data, my_data$IntervalTime > 100))[[1]]

# -----------------------------------------------------------------------------
# JAGS needs all of the data to be provided in one list (here called 'dat').
# Therefore, we prepare data for JAGS, and assign each element the names they
# appear with in the model code section:
dat <- list("e" = e, 
            "K" = K,
            "n" = n,
            "ColonyTotal" = ColonyTotal,
            "timeinterval" = as.numeric(my_data$intervaltime_censored),
            "Colony" = my_data$ColonyNumberCode,
            "Country" = my_data$CountryCode,
            "totalsubordinates" = as.numeric(my_data$TrialSubordinatesCount),
            "colonyrelatedness" = colony_relatedness,
            "mean_relatedness" = mean_relatedness,
            "mean_groupsize" = mean(as.numeric(my_data$TrialSubordinatesCount)),
            "IncludeRelatedness" = IncludeRelatedness,
            "IncludeBothCountries" = IncludeBothCountries
)

# ------------------------------------------------------------------------------------------
# MODEL IN JAGS/BUGS SYNTAX:

cat("
    model{
    
    # MULTINOMIAL LIKELIHOODS
    
    for (k in 1:K) { # K is the total number of interval observations (rows)

    e[k, 1, 1:4] ~ dmulti(A[k, 1, 1:4], n[k, 1]) 
    e[k, 2, 1:4] ~ dmulti(A[k, 2, 1:4], n[k, 2])
    e[k, 3, 1:4] ~ dmulti(A[k, 3, 1:4], n[k, 3])
    e[k, 4, 1:4] ~ dmulti(A[k, 4, 1:4], n[k, 4])

    }
    
    # Structure of the 'e' data:
    # Row: k. Each row a trial (colony)
    # Column: i. Each column an initial state
    # Depth: destination state
   
      # ------------------------------------------------------------------------------------------
      # TRANSFORMING TRANSITION *RATE* MATRIX INTO TRANSITION *PROBABILITY* MATRIX FOR GIVEN TIME INTERVAL:
      
      # First, multiply the transition rate matrix by the corresponding time interval for this observation (intervaltime[k]):
   
      for (k in 1:K) {
      
                Qtmatrix[k,1,1] <- ratematrix[k,1,1]*timeinterval[k]
                Qtmatrix[k,1,2] <- ratematrix[k,1,2]*timeinterval[k]
                Qtmatrix[k,1,3] <- ratematrix[k,1,3]*timeinterval[k]
                Qtmatrix[k,1,4] <- ratematrix[k,1,4]*timeinterval[k]
                
                Qtmatrix[k,2,1] <- ratematrix[k,2,1]*timeinterval[k]
                Qtmatrix[k,2,2] <- ratematrix[k,2,2]*timeinterval[k]
                Qtmatrix[k,2,3] <- ratematrix[k,2,3]*timeinterval[k]
                Qtmatrix[k,2,4] <- ratematrix[k,2,4]*timeinterval[k]
                
                Qtmatrix[k,3,1] <- ratematrix[k,3,1]*timeinterval[k]
                Qtmatrix[k,3,2] <- ratematrix[k,3,2]*timeinterval[k]
                Qtmatrix[k,3,3] <- ratematrix[k,3,3]*timeinterval[k]
                Qtmatrix[k,3,4] <- ratematrix[k,3,4]*timeinterval[k]
                
                Qtmatrix[k,4,1] <- ratematrix[k,4,1]*timeinterval[k]
                Qtmatrix[k,4,2] <- ratematrix[k,4,2]*timeinterval[k]
                Qtmatrix[k,4,3] <- ratematrix[k,4,3]*timeinterval[k]
                Qtmatrix[k,4,4] <- ratematrix[k,4,4]*timeinterval[k]
      
      # Second, take the matrix exponential of the Qt matrix to obtain the transition probability matrix corresponding to 
      # this observation's interval time (timeinterval[k]):

                TransitionProbabilityMatrix[k,1:4,1:4] <- mexp(Qtmatrix[k,1:4,1:4])
                
      # Third, save the elements of this transition probability matrix so we can use them in the multinomial
      # likelihood section:
      
              A[k,1,1] <- TransitionProbabilityMatrix[k,1,1]
              A[k,1,2] <- TransitionProbabilityMatrix[k,1,2]
              A[k,1,3] <- TransitionProbabilityMatrix[k,1,3]
              A[k,1,4] <- TransitionProbabilityMatrix[k,1,4]
              
              A[k,2,1] <- TransitionProbabilityMatrix[k,2,1]
              A[k,2,2] <- TransitionProbabilityMatrix[k,2,2]
              A[k,2,3] <- TransitionProbabilityMatrix[k,2,3]
              A[k,2,4] <- TransitionProbabilityMatrix[k,2,4]
              
              A[k,3,1] <- TransitionProbabilityMatrix[k,3,1]
              A[k,3,2] <- TransitionProbabilityMatrix[k,3,2]
              A[k,3,3] <- TransitionProbabilityMatrix[k,3,3]
              A[k,3,4] <- TransitionProbabilityMatrix[k,3,4]
              
              A[k,4,1] <- TransitionProbabilityMatrix[k,4,1]
              A[k,4,2] <- TransitionProbabilityMatrix[k,4,2]
              A[k,4,3] <- TransitionProbabilityMatrix[k,4,3]
              A[k,4,4] <- TransitionProbabilityMatrix[k,4,4]
            
      }
    
      # ------------------------------------------------------------------------------------------
      # REGRESSION EQUATIONS FOR TRANSITION *RATE* MATRIX:
      
      # I think we could use the regression equations to predict the elements of the Q matrix
      # (i.e., the transition *rate* matrix). For each observation, we can then multiply the predicted
      # Q matrix by its relevant interval time t_k to produce a matrix Qt. Finally, we could take
      # the matrix exponential of this inside JAGS (using the mexp() funtion) to obtain the transition
      # *probability* matrix in time interval t_k. We then use these probabilities in the multinomial
      # likelihood section above, to fit them to what actually happened. Does that work?
      
      # Predicting the elements of the Q matrix (the transition *rate* matrix):
      
      for (k in 1:K) {
      
      ratematrix[k,1,1] <- -(ratematrix[k,1,2] + ratematrix[k,1,3])
      ratematrix[k,1,2] <- alpha[1,2] + IncludeBothCountries*CountryEffect[1,2]*Country[k] + u12[Colony[k]] + groupsizeEffect[1,2]*totalsubordinates[k] + IncludeRelatedness*relatednessEffect[1,2]*colonyrelatedness[k]
      ratematrix[k,1,3] <- alpha[1,3] + IncludeBothCountries*CountryEffect[1,3]*Country[k] + u13[Colony[k]] + groupsizeEffect[1,3]*totalsubordinates[k] + IncludeRelatedness*relatednessEffect[1,3]*colonyrelatedness[k]
      ratematrix[k,1,4] <- 0
      
      ratematrix[k,2,1] <- alpha[2,1] + IncludeBothCountries*CountryEffect[2,1]*Country[k] + u21[Colony[k]] + groupsizeEffect[2,1]*totalsubordinates[k] + IncludeRelatedness*relatednessEffect[2,1]*colonyrelatedness[k]
      ratematrix[k,2,2] <- -(ratematrix[k,2,1] + ratematrix[k,2,4])
      ratematrix[k,2,3] <- 0
      ratematrix[k,2,4] <- alpha[2,4] + IncludeBothCountries*CountryEffect[2,4]*Country[k] + u24[Colony[k]] + groupsizeEffect[2,4]*totalsubordinates[k] + IncludeRelatedness*relatednessEffect[2,4]*colonyrelatedness[k]
      
      ratematrix[k,3,1] <- alpha[3,1] + IncludeBothCountries*CountryEffect[3,1]*Country[k] + u31[Colony[k]] + groupsizeEffect[3,1]*totalsubordinates[k] + IncludeRelatedness*relatednessEffect[3,1]*colonyrelatedness[k]
      ratematrix[k,3,2] <- 0
      ratematrix[k,3,3] <- -(ratematrix[k,3,1] + ratematrix[k,3,4])
      ratematrix[k,3,4] <- alpha[3,4] + IncludeBothCountries*CountryEffect[3,4]*Country[k] + u34[Colony[k]] + groupsizeEffect[3,4]*totalsubordinates[k] + IncludeRelatedness*relatednessEffect[3,4]*colonyrelatedness[k]
      
      ratematrix[k,4,1] <- 0
      ratematrix[k,4,2] <- alpha[4,2] + IncludeBothCountries*CountryEffect[4,2]*Country[k] + u42[Colony[k]] + groupsizeEffect[4,2]*totalsubordinates[k] + IncludeRelatedness*relatednessEffect[4,2]*colonyrelatedness[k]
      ratematrix[k,4,3] <- alpha[4,3] + IncludeBothCountries*CountryEffect[4,3]*Country[k] + u43[Colony[k]] + groupsizeEffect[4,3]*totalsubordinates[k] + IncludeRelatedness*relatednessEffect[4,3]*colonyrelatedness[k]
      ratematrix[k,4,4] <- -(ratematrix[k,4,2] + ratematrix[k,4,3])
      
      }
      
      UnusedNodes1 <- alpha
      UnusedNodes2 <- mean_relatedness
      
      # ------------------------------------------------------------------------------------------
      # PRIORS:
      
      # Priors on intercepts:
            for (i in 1:4){ for (j in 1:4){ alpha[i,j]~dnorm(0,0.1) } }
            
       # Priors on CountryEffects:
            for (i in 1:4){ for (j in 1:4){ CountryEffect[i,j]~dnorm(0,0.1) } }
            
       # Priors on groupsizeEffect:
            for (i in 1:4){ for (j in 1:4){ groupsizeEffect[i,j]~dnorm(0,0.1) } }
            
        # Priors on relatednessEffect:
            for (i in 1:4){ for (j in 1:4){ relatednessEffect[i,j]~dnorm(0,0.1) } }
      
      # Priors on random effect (Colony):
         # C groups
        for (c in 1:ColonyTotal) {
        
        u12[c] ~ dnorm(0,tau12)
        u13[c] ~ dnorm(0,tau13)
        
        u21[c] ~ dnorm(0,tau21)
        u24[c] ~ dnorm(0,tau24)
        
        u31[c] ~ dnorm(0,tau31)
        u34[c] ~ dnorm(0,tau34)
        
        u42[c] ~ dnorm(0,tau42)
        u43[c] ~ dnorm(0,tau43)
        
        }
        
        # Hyperpriors:
        
            dgammaVariable1 <- 10
            dgammaVariable2 <- 1
            
            tau12 ~ dgamma(dgammaVariable1,dgammaVariable2)
            tau13 ~ dgamma(dgammaVariable1,dgammaVariable2)
            
            tau21 ~ dgamma(dgammaVariable1,dgammaVariable2)
            tau24 ~ dgamma(dgammaVariable1,dgammaVariable2)
            
            tau31 ~ dgamma(dgammaVariable1,dgammaVariable2)
            tau34 ~ dgamma(dgammaVariable1,dgammaVariable2)
            
            tau42 ~ dgamma(dgammaVariable1,dgammaVariable2)
            tau43 ~ dgamma(dgammaVariable1,dgammaVariable2)
      
    "
    , 
    file="myJAGSmodel.txt")

# ------------------------------------------------------------------------------------------
# IF RUNNING BOTH COUNTRIES, WE WILL CALCULATE THE POSTERIOR PREDICTIVE DISTRIBUTION IN EACH USING THE 'COUNTRYEFFECT' EFFECT:

# To enable that, we need to track a predicted 'ratematrix' for each country over the iterations of MCMC.
# We therefore add this section to model code:

if (IncludeBothCountries == 1){
cat("
    # Section added automatically only if running both countries:
    
    # ------------------------------------------------------------------------------------------
      # POSTERIOR PREDICTIVE DISTRIBUTION FOR RATEMATRIX (Q MATRIX) IN EACH COUNTRY:
      
      Cameroon_ratematrix[1,1] <- -(Cameroon_ratematrix[1,2] + Cameroon_ratematrix[1,3])
      Cameroon_ratematrix[1,2] <- alpha[1,2] + groupsizeEffect[1,2]*mean_groupsize + relatednessEffect[1,2]*mean_relatedness
      Cameroon_ratematrix[1,3] <- alpha[1,3] + groupsizeEffect[1,3]*mean_groupsize + relatednessEffect[1,3]*mean_relatedness
      Cameroon_ratematrix[1,4] <- 0
      
      Cameroon_ratematrix[2,1] <- alpha[2,1] + groupsizeEffect[2,1]*mean_groupsize + relatednessEffect[2,1]*mean_relatedness
      Cameroon_ratematrix[2,2] <- -(Cameroon_ratematrix[2,1] + Cameroon_ratematrix[2,4])
      Cameroon_ratematrix[2,3] <- 0
      Cameroon_ratematrix[2,4] <- alpha[2,4] + groupsizeEffect[2,4]*mean_groupsize + relatednessEffect[2,4]*mean_relatedness
      
      Cameroon_ratematrix[3,1] <- alpha[3,1] + groupsizeEffect[3,1]*mean_groupsize + relatednessEffect[3,1]*mean_relatedness
      Cameroon_ratematrix[3,2] <- 0
      Cameroon_ratematrix[3,3] <- -(Cameroon_ratematrix[3,1] + Cameroon_ratematrix[3,4])
      Cameroon_ratematrix[3,4] <- alpha[3,4] + groupsizeEffect[3,4]*mean_groupsize + relatednessEffect[3,4]*mean_relatedness
      
      Cameroon_ratematrix[4,1] <- 0
      Cameroon_ratematrix[4,2] <- alpha[4,2] + groupsizeEffect[4,2]*mean_groupsize + relatednessEffect[4,2]*mean_relatedness
      Cameroon_ratematrix[4,3] <- alpha[4,3] + groupsizeEffect[4,3]*mean_groupsize + relatednessEffect[4,3]*mean_relatedness
      Cameroon_ratematrix[4,4] <- -(Cameroon_ratematrix[4,2] + Cameroon_ratematrix[4,3])
      
      SouthAfrica_ratematrix[1,1] <- -(SouthAfrica_ratematrix[1,2] + SouthAfrica_ratematrix[1,3])
      SouthAfrica_ratematrix[1,2] <- alpha[1,2] + CountryEffect[1,2] + groupsizeEffect[1,2]*mean_groupsize + relatednessEffect[1,2]*mean_relatedness
      SouthAfrica_ratematrix[1,3] <- alpha[1,3] + CountryEffect[1,3] + groupsizeEffect[1,3]*mean_groupsize + relatednessEffect[1,3]*mean_relatedness
      SouthAfrica_ratematrix[1,4] <- 0
      
      SouthAfrica_ratematrix[2,1] <- alpha[2,1] + CountryEffect[2,1] + groupsizeEffect[2,1]*mean_groupsize + relatednessEffect[2,1]*mean_relatedness
      SouthAfrica_ratematrix[2,2] <- -(SouthAfrica_ratematrix[2,1] + SouthAfrica_ratematrix[2,4])
      SouthAfrica_ratematrix[2,3] <- 0
      SouthAfrica_ratematrix[2,4] <- alpha[2,4] + CountryEffect[2,4] + groupsizeEffect[2,4]*mean_groupsize + relatednessEffect[2,4]*mean_relatedness
      
      SouthAfrica_ratematrix[3,1] <- alpha[3,1] + CountryEffect[3,1] + groupsizeEffect[3,1]*mean_groupsize + relatednessEffect[3,1]*mean_relatedness
      SouthAfrica_ratematrix[3,2] <- 0
      SouthAfrica_ratematrix[3,3] <- -(SouthAfrica_ratematrix[3,1] + SouthAfrica_ratematrix[3,4])
      SouthAfrica_ratematrix[3,4] <- alpha[3,4] + CountryEffect[3,4] + groupsizeEffect[3,4]*mean_groupsize + relatednessEffect[3,4]*mean_relatedness
      
      SouthAfrica_ratematrix[4,1] <- 0
      SouthAfrica_ratematrix[4,2] <- alpha[4,2] + CountryEffect[4,2] + groupsizeEffect[4,2]*mean_groupsize + relatednessEffect[4,2]*mean_relatedness
      SouthAfrica_ratematrix[4,3] <- alpha[4,3] + CountryEffect[4,3] + groupsizeEffect[4,3]*mean_groupsize + relatednessEffect[4,3]*mean_relatedness
      SouthAfrica_ratematrix[4,4] <- -(SouthAfrica_ratematrix[4,2] + SouthAfrica_ratematrix[4,3])

    ",file="myJAGSmodel.txt",append=TRUE)
} # end of 'if' function asking if both countries are included.

# ------------------------------------------------------------------------------------------
# SECTION ADDED AUTOMATICALLY IF INCLUDING RELATEDNESS:

# Similarly, if we are including relatedness in the model, we can calculate the posterior
# predictive distribution at different relatedness values.

# We will use the following two relatedness values: r=0.2 (low relatedness) and r=0.75 (high relatedness). 
# NOTE: This is specifically for Cameroon (i.e., each 'CountryEffect' = 0).

if (IncludeRelatedness == 1){
cat("
    # Section added automatically only if including relatedness:
    
    # ------------------------------------------------------------------------------------------
      # POSTERIOR PREDICTIVE DISTRIBUTION FOR RATEMATRIX (Q MATRIX) AT LOW AND HIGH RELATEDNESSES:
      # This is specifically for Cameroon (i.e., each 'CountryEffect' = 0).
      
      Low_r_ratematrix[1,1] <- -(Low_r_ratematrix[1,2] + Low_r_ratematrix[1,3])
      Low_r_ratematrix[1,2] <- alpha[1,2] + groupsizeEffect[1,2]*mean_groupsize + relatednessEffect[1,2]*0.2
      Low_r_ratematrix[1,3] <- alpha[1,3] + groupsizeEffect[1,3]*mean_groupsize + relatednessEffect[1,3]*0.2
      Low_r_ratematrix[1,4] <- 0
      
      Low_r_ratematrix[2,1] <- alpha[2,1] + groupsizeEffect[2,1]*mean_groupsize + relatednessEffect[2,1]*0.2
      Low_r_ratematrix[2,2] <- -(Low_r_ratematrix[2,1] + Low_r_ratematrix[2,4])
      Low_r_ratematrix[2,3] <- 0
      Low_r_ratematrix[2,4] <- alpha[2,4] + groupsizeEffect[2,4]*mean_groupsize + relatednessEffect[2,4]*0.2
      
      Low_r_ratematrix[3,1] <- alpha[3,1] + groupsizeEffect[3,1]*mean_groupsize + relatednessEffect[3,1]*0.2
      Low_r_ratematrix[3,2] <- 0
      Low_r_ratematrix[3,3] <- -(Low_r_ratematrix[3,1] + Low_r_ratematrix[3,4])
      Low_r_ratematrix[3,4] <- alpha[3,4] + groupsizeEffect[3,4]*mean_groupsize + relatednessEffect[3,4]*0.2
      
      Low_r_ratematrix[4,1] <- 0
      Low_r_ratematrix[4,2] <- alpha[4,2] + groupsizeEffect[4,2]*mean_groupsize + relatednessEffect[4,2]*0.2
      Low_r_ratematrix[4,3] <- alpha[4,3] + groupsizeEffect[4,3]*mean_groupsize + relatednessEffect[4,3]*0.2
      Low_r_ratematrix[4,4] <- -(Low_r_ratematrix[4,2] + Low_r_ratematrix[4,3])
      
      High_r_ratematrix[1,1] <- -(High_r_ratematrix[1,2] + High_r_ratematrix[1,3])
      High_r_ratematrix[1,2] <- alpha[1,2] + groupsizeEffect[1,2]*mean_groupsize + relatednessEffect[1,2]*0.75
      High_r_ratematrix[1,3] <- alpha[1,3] + groupsizeEffect[1,3]*mean_groupsize + relatednessEffect[1,3]*0.75
      High_r_ratematrix[1,4] <- 0
      
      High_r_ratematrix[2,1] <- alpha[2,1] + groupsizeEffect[2,1]*mean_groupsize + relatednessEffect[2,1]*0.75
      High_r_ratematrix[2,2] <- -(High_r_ratematrix[2,1] + High_r_ratematrix[2,4])
      High_r_ratematrix[2,3] <- 0
      High_r_ratematrix[2,4] <- alpha[2,4] + groupsizeEffect[2,4]*mean_groupsize + relatednessEffect[2,4]*0.75
      
      High_r_ratematrix[3,1] <- alpha[3,1] + groupsizeEffect[3,1]*mean_groupsize + relatednessEffect[3,1]*0.75
      High_r_ratematrix[3,2] <- 0
      High_r_ratematrix[3,3] <- -(High_r_ratematrix[3,1] + High_r_ratematrix[3,4])
      High_r_ratematrix[3,4] <- alpha[3,4] + groupsizeEffect[3,4]*mean_groupsize + relatednessEffect[3,4]*0.75
      
      High_r_ratematrix[4,1] <- 0
      High_r_ratematrix[4,2] <- alpha[4,2] + groupsizeEffect[4,2]*mean_groupsize + relatednessEffect[4,2]*0.75
      High_r_ratematrix[4,3] <- alpha[4,3] + groupsizeEffect[4,3]*mean_groupsize + relatednessEffect[4,3]*0.75
      High_r_ratematrix[4,4] <- -(High_r_ratematrix[4,2] + High_r_ratematrix[4,3])

    ",file="myJAGSmodel.txt",append=TRUE)
} # end of 'if' function asking whether relatedness is included.

# -----------------------------------------------------------------------------------------
# Add the end bracket to the model code:
cat("}",file="myJAGSmodel.txt",append=TRUE)

# ------------------------------------------------------------------------------------------
# Initial values:
inits <- list(alpha = array(1,dim=c(4,4)))

# ------------------------------------------------------------------------------------------
# SET UP THE JAGS MODEL:

NumberOfChainsRun = 3 # A large number of chains is an efficient way of sampling the posterior.

jags.m <- jags.model( file = "myJAGSmodel.txt",
                      data = dat, 
                      inits = inits,
                      n.chains = NumberOfChainsRun,    # Number of chains to run.
                      n.adapt = 1000 ) # Number of steps in the adaptation phase. 

# ------------------------------------------------------------------------------------------
# BURN-IN:

update(jags.m, n.iter = 1000)

# -----------------------------------------------------------------------------------------------------------------------
# OBTAIN ESTIMATES FOR THE REGRESSION SLOPE VALUES:

# Monitor the following parameters:
params <- c("CountryEffect",
            "u12", "u13", "u21", "u24", "u31", "u34", "u42", "u43",
            "alpha[1,2]",
            "alpha[1,3]",
            "alpha[2,1]",
            "alpha[2,4]",
            "alpha[3,1]",
            "alpha[3,4]",
            "alpha[4,2]",
            "alpha[4,3]",
            "groupsizeEffect[1,2]",
            "groupsizeEffect[1,3]",
            "groupsizeEffect[2,1]",
            "groupsizeEffect[2,4]",
            "groupsizeEffect[3,1]",
            "groupsizeEffect[3,4]",
            "groupsizeEffect[4,2]",
            "groupsizeEffect[4,3]",
            "relatednessEffect[1,2]",
            "relatednessEffect[1,3]",
            "relatednessEffect[2,1]",
            "relatednessEffect[2,4]",
            "relatednessEffect[3,1]",
            "relatednessEffect[3,4]",
            "relatednessEffect[4,2]",
            "relatednessEffect[4,3]"
            )

# Run JAGS and save the posterior samples:
samps <- coda.samples( jags.m,
                       params,
                       thin = 5,
                       n.iter = 2000 )

# Check for convergence using the Gelman-Rubin diagnostic:
gelman.diag(samps) # statistics
gelman.plot(samps) # plot

# View the results:
my_quantiles <- summary(samps)$quantiles
my_effect_stats <- summary(samps)$statistics
my_results <- cbind(my_quantiles, my_effect_stats)
View(my_results)

# Plot the results:
    # First, make the row names (the effects) into an actual column:
        my_results <- as.data.frame(my_results)
        my_results$effect_name <- row.names(my_results)
  # Focus only on candidate 'significant' effects (i.e., effects whose 95% credible interval does not overlap zero):
        my_results <- subset(my_results, sign(my_results$`2.5%`) == sign(my_results$`97.5%`))
  # Now plot the caterpillar plot:
        library(scales)
        library(ggplot2)
        ggplot() +
          geom_segment(data = my_results, 
                       aes(x = my_results$`2.5%`, 
                           y = effect_name, 
                           xend = my_results$`97.5%`, 
                           yend = effect_name), 
                       size = 0.5) +
          geom_segment(data = my_results, 
                       aes(x = my_results$Mean-0.05, # using this 'segment' to highlight the mean
                           y = effect_name, 
                           xend = my_results$Mean+0.05, # using this 'segment' to highlight the mean
                           yend = effect_name), 
                       size = 2) +
          geom_vline(xintercept = 0, linetype = "dashed") +
          theme_classic() + 
          theme(text = element_text(size=12)) +
          labs(y= "Predictor", 
               x = "Effect")

# -----------------------------------------------------------------------------------------------------------------------
# NOW THAT THE MCMC HAS RUN, WE CAN WORK OUT THE STATIONARY DISTRIBUTION (GET THE PREDICTIVE POSTERIOR DISTRIBUTION FOR THE STATIONARY DISTRIBUTION):
# The two sections below look at the between-country comparison and the relatedness comparison. Note that the relatedness comparison is plotted for Cameroon only, 
# regardless of whether or not South Africa is included.
# -----------------------------------------------------------------------------------------------------------------------
# POSTERIOR PREDICTION 1: COMPARING THE TWO COUNTRIES

# Only run this section if you chose to include both countries.
        
        # We will now monitor the ratematrices:
        params2 <- c("Cameroon_ratematrix",
                    "SouthAfrica_ratematrix")
        
        # Run JAGS and save the posterior samples:
        samps2 <- coda.samples( jags.m,
                               params2,
                               thin = 4,
                               n.iter = 200 )
        
        # View the results:
        my_quantiles2 <- summary(samps2)$quantiles
        my_effect_stats2 <- summary(samps2)$statistics
        my_results2 <- cbind(my_quantiles2, my_effect_stats2)
        View(my_results2)
        
# Extract the dataframe of tracked values from MCMC:
data <- as.data.frame(window(samps2)[[1]])

# Use the 'castor' package, so we can calculate the stationary distribution with the get_stationary_distribution() function:
library(castor)

# Set up a matrix for each country to hold the stationary distribution results (where each row is a different iteration of MCMC):
Cameroon_StationaryDistributionResults <- matrix(NaN, nrow = dim(data)[1], ncol = 4)
SouthAfrica_StationaryDistributionResults <- matrix(NaN, nrow = dim(data)[1], ncol = 4)

for (iteration in 1:dim(data)[1]){
  
  # Set up the Q matrix for Cameroon:
  Cameroon_Qmatrix <- matrix(NaN, nrow = 4, ncol = 4)
  
  # Fill in the Q matrix for Cameroon with the values in this iteration of MCMC:
  Cameroon_Qmatrix[1,1] <- data$`Cameroon_ratematrix[1,1]`[iteration]
  Cameroon_Qmatrix[1,2] <- data$`Cameroon_ratematrix[1,2]`[iteration]
  Cameroon_Qmatrix[1,3] <- data$`Cameroon_ratematrix[1,3]`[iteration]
  Cameroon_Qmatrix[1,4] <- data$`Cameroon_ratematrix[1,4]`[iteration]
  
  Cameroon_Qmatrix[2,1] <- data$`Cameroon_ratematrix[2,1]`[iteration]
  Cameroon_Qmatrix[2,2] <- data$`Cameroon_ratematrix[2,2]`[iteration]
  Cameroon_Qmatrix[2,3] <- data$`Cameroon_ratematrix[2,3]`[iteration]
  Cameroon_Qmatrix[2,4] <- data$`Cameroon_ratematrix[2,4]`[iteration]
  
  Cameroon_Qmatrix[3,1] <- data$`Cameroon_ratematrix[3,1]`[iteration]
  Cameroon_Qmatrix[3,2] <- data$`Cameroon_ratematrix[3,2]`[iteration]
  Cameroon_Qmatrix[3,3] <- data$`Cameroon_ratematrix[3,3]`[iteration]
  Cameroon_Qmatrix[3,4] <- data$`Cameroon_ratematrix[3,4]`[iteration]
  
  Cameroon_Qmatrix[4,1] <- data$`Cameroon_ratematrix[4,1]`[iteration]
  Cameroon_Qmatrix[4,2] <- data$`Cameroon_ratematrix[4,2]`[iteration]
  Cameroon_Qmatrix[4,3] <- data$`Cameroon_ratematrix[4,3]`[iteration]
  Cameroon_Qmatrix[4,4] <- data$`Cameroon_ratematrix[4,4]`[iteration]
  
  # Set up the Q matrix for South Africa:
  SouthAfrica_Qmatrix <- matrix(NaN, nrow = 4, ncol = 4)
  
  # Fill in the Q matrix for SouthAfrica with the values in this iteration of MCMC:
  SouthAfrica_Qmatrix[1,1] <- data$`SouthAfrica_ratematrix[1,1]`[iteration]
  SouthAfrica_Qmatrix[1,2] <- data$`SouthAfrica_ratematrix[1,2]`[iteration]
  SouthAfrica_Qmatrix[1,3] <- data$`SouthAfrica_ratematrix[1,3]`[iteration]
  SouthAfrica_Qmatrix[1,4] <- data$`SouthAfrica_ratematrix[1,4]`[iteration]
  
  SouthAfrica_Qmatrix[2,1] <- data$`SouthAfrica_ratematrix[2,1]`[iteration]
  SouthAfrica_Qmatrix[2,2] <- data$`SouthAfrica_ratematrix[2,2]`[iteration]
  SouthAfrica_Qmatrix[2,3] <- data$`SouthAfrica_ratematrix[2,3]`[iteration]
  SouthAfrica_Qmatrix[2,4] <- data$`SouthAfrica_ratematrix[2,4]`[iteration]
  
  SouthAfrica_Qmatrix[3,1] <- data$`SouthAfrica_ratematrix[3,1]`[iteration]
  SouthAfrica_Qmatrix[3,2] <- data$`SouthAfrica_ratematrix[3,2]`[iteration]
  SouthAfrica_Qmatrix[3,3] <- data$`SouthAfrica_ratematrix[3,3]`[iteration]
  SouthAfrica_Qmatrix[3,4] <- data$`SouthAfrica_ratematrix[3,4]`[iteration]
  
  SouthAfrica_Qmatrix[4,1] <- data$`SouthAfrica_ratematrix[4,1]`[iteration]
  SouthAfrica_Qmatrix[4,2] <- data$`SouthAfrica_ratematrix[4,2]`[iteration]
  SouthAfrica_Qmatrix[4,3] <- data$`SouthAfrica_ratematrix[4,3]`[iteration]
  SouthAfrica_Qmatrix[4,4] <- data$`SouthAfrica_ratematrix[4,4]`[iteration]
  
  # NOTE: MIGHT NEED TO TAKE INTO ACCOUNT ROUNDING ARTEFACTS THAT MEAN IT DOESN'T QUITE SUM TO ZERO IN EACH ROW OF THE RATEMATRIX
  
  # Calculate the stationary distributions predicted at this iteration, and enter it into the table:
  Cameroon_StationaryDistributionResults[iteration,1:4] <- get_stationary_distribution(Cameroon_Qmatrix)
  SouthAfrica_StationaryDistributionResults[iteration,1:4] <- get_stationary_distribution(SouthAfrica_Qmatrix)
  
}

# Convert stationary distribution results to a dataframe to enable easy plotting:
CameroonResults <- as.data.frame(Cameroon_StationaryDistributionResults)
SouthAfricaResults <- as.data.frame(SouthAfrica_StationaryDistributionResults)

# Reshape the dataframes so that it is suitable for ggplot:
library(reshape2)
SouthAfricaResults$Country = "SouthAfrica"
dat1 <- melt(SouthAfricaResults, id.vars=5)
CameroonResults$Country = "Cameroon"
dat2 <- melt(CameroonResults, id.vars=5)
combined <- rbind(dat1, dat2)

# Plotting 95% prediction intervals:

      # To do this, I think we should use the quantile function? So we would have 95% quantiles, which 
      # would be from quantile 2.5 to quantile 97.5? Here is my attempt at that:
      my_PP_quantiles <- as.data.frame(unique(cbind(combined$Country, combined$variable)))
      colnames(my_PP_quantiles) <- c("Country","variable")
      my_PP_quantiles$name <- paste(my_PP_quantiles$Country, my_PP_quantiles$variable)
      
      # The 'V' seems to vanish from the variable names. Add it back in:
      my_PP_quantiles$variable <- sub("^", "V", my_PP_quantiles$variable)
      
      # Set up empty columns:
      my_PP_quantiles$upper <- NA
      my_PP_quantiles$lower <- NA
      my_PP_quantiles$mean <- NA

      for (i in 1: dim(my_quantiles)[1]){
        this_country <- my_PP_quantiles[i,1]
        this_variable <- my_PP_quantiles[i,2]
        x <- subset(combined, Country == this_country & variable == this_variable)$value
        my_PP_quantiles[i,"upper"] <- quantile(x, .975, type=1)
        my_PP_quantiles[i,"lower"] <- quantile(x, .255, type=1)
        my_PP_quantiles[i,"mean"] <- mean(x)
      }
    
      # Reorder rows alphabetically so that each country's V1s are next to each other, etc.:
      my_PP_quantiles <- my_PP_quantiles[order(my_PP_quantiles$variable),]
      # Lock in the order using the 'factor' command, so that it is plotted accordingly:
      my_PP_quantiles$name <- factor(my_PP_quantiles$name, levels = my_PP_quantiles$name)
      
      # Now plot the caterpillar plot:
      library(scales)
      library(ggplot2)
      my_color_variable <- my_PP_quantiles$Country
      ggplot() +
        geom_segment(data = my_PP_quantiles, 
                     aes(x = my_PP_quantiles$upper, 
                         y = my_PP_quantiles$name, 
                         xend = my_PP_quantiles$lower,  
                         yend = my_PP_quantiles$name,
                         color = my_PP_quantiles$Country
                         ),
                     size = 0.5) +
        theme_classic() +
        geom_segment(data = my_PP_quantiles, 
                     aes(x = my_PP_quantiles$mean-0.002, # using this 'segment' to highlight the mean
                         y = my_PP_quantiles$name, 
                         xend = my_PP_quantiles$mean+0.002, # using this 'segment' to highlight the mean
                         yend = my_PP_quantiles$name), 
                     size = 2) +
        scale_x_continuous(expand = c(0,0)) +
        scale_color_manual(values=c("Cameroon"="turquoise", "SouthAfrica"="red")) +
        theme_classic() + 
        theme(legend.position="none") + 
        theme(text = element_text(size=12)) +
        scale_y_discrete(labels = c('1','1',  '2','2',  '3','3',  '4','4')) +
        labs(y= "Game state", 
             x = "Posterior predictive probability")
    
# ---------------------------------------------------
# SANITY-CHECK BY COMPARING AGAINST THE ACTUAL PROPORTIONS OF TIME SPENT STAYING IN EACH CATEGORY:
      # SECTION TO BE CONTINUED

# For each nest, calculate the proportion of its observations that are each of e11, e22, e33, or e44.

# First, make a list of all trials in the data:
trial_list <- levels(as.factor(my_data$Trial))

# Loop through each trial to calculate the summary statistics:

for (trial in 1:length(trial_list)){
  
  
  
  
}
# -----------------------------------------------------------------------------------------------------------------------
# POSTERIOR PREDICTION 2: COMPARING LOW AND HIGH RELATEDNESS

# Only run this section if you chose to include relatedness. It is specifically for Cameroon.
        
        # We will now monitor the ratematrices:
        r_params <- c("Low_r_ratematrix",
                    "High_r_ratematrix")
        
        # Run JAGS and save the posterior samples:
        samps_r <- coda.samples( jags.m,
                               r_params,
                               thin = 4,
                               n.iter = 200 )
        
        # View the results:
        my_quantiles_r <- summary(samps_r)$quantiles
        my_effect_stats_r <- summary(samps_r)$statistics
        my_results_r <- cbind(my_quantiles_r, my_effect_stats_r)
        View(my_results_r)
        
# Extract the dataframe of tracked values from MCMC:
data_r <- as.data.frame(window(samps_r)[[1]])

# Use the 'castor' package, so we can calculate the stationary distribution with the get_stationary_distribution() function:
library(castor)

# Set up a matrix for each country to hold the stationary distribution results (where each row is a different iteration of MCMC):
Low_r_StationaryDistributionResults <- matrix(NaN, nrow = dim(data_r)[1], ncol = 4)
High_r_StationaryDistributionResults <- matrix(NaN, nrow = dim(data_r)[1], ncol = 4)

for (iteration in 1:dim(data_r)[1]){
  
  # Set up the Q matrix for the low relatedness predictions:
  Low_r_Qmatrix <- matrix(NaN, nrow = 4, ncol = 4)
  
  # Fill in the Q matrix for the low relatedness predictions with the values in this iteration of MCMC:
  Low_r_Qmatrix[1,1] <- data_r$`Low_r_ratematrix[1,1]`[iteration]
  Low_r_Qmatrix[1,2] <- data_r$`Low_r_ratematrix[1,2]`[iteration]
  Low_r_Qmatrix[1,3] <- data_r$`Low_r_ratematrix[1,3]`[iteration]
  Low_r_Qmatrix[1,4] <- data_r$`Low_r_ratematrix[1,4]`[iteration]
  
  Low_r_Qmatrix[2,1] <- data_r$`Low_r_ratematrix[2,1]`[iteration]
  Low_r_Qmatrix[2,2] <- data_r$`Low_r_ratematrix[2,2]`[iteration]
  Low_r_Qmatrix[2,3] <- data_r$`Low_r_ratematrix[2,3]`[iteration]
  Low_r_Qmatrix[2,4] <- data_r$`Low_r_ratematrix[2,4]`[iteration]
  
  Low_r_Qmatrix[3,1] <- data_r$`Low_r_ratematrix[3,1]`[iteration]
  Low_r_Qmatrix[3,2] <- data_r$`Low_r_ratematrix[3,2]`[iteration]
  Low_r_Qmatrix[3,3] <- data_r$`Low_r_ratematrix[3,3]`[iteration]
  Low_r_Qmatrix[3,4] <- data_r$`Low_r_ratematrix[3,4]`[iteration]
  
  Low_r_Qmatrix[4,1] <- data_r$`Low_r_ratematrix[4,1]`[iteration]
  Low_r_Qmatrix[4,2] <- data_r$`Low_r_ratematrix[4,2]`[iteration]
  Low_r_Qmatrix[4,3] <- data_r$`Low_r_ratematrix[4,3]`[iteration]
  Low_r_Qmatrix[4,4] <- data_r$`Low_r_ratematrix[4,4]`[iteration]
  
  # Set up the Q matrix for the high relatedness predictions:
  High_r_Qmatrix <- matrix(NaN, nrow = 4, ncol = 4)
  
  # Fill in the Q matrix for the high-relatedness predictions with the values in this iteration of MCMC:
  High_r_Qmatrix[1,1] <- data_r$`High_r_ratematrix[1,1]`[iteration]
  High_r_Qmatrix[1,2] <- data_r$`High_r_ratematrix[1,2]`[iteration]
  High_r_Qmatrix[1,3] <- data_r$`High_r_ratematrix[1,3]`[iteration]
  High_r_Qmatrix[1,4] <- data_r$`High_r_ratematrix[1,4]`[iteration]
  
  High_r_Qmatrix[2,1] <- data_r$`High_r_ratematrix[2,1]`[iteration]
  High_r_Qmatrix[2,2] <- data_r$`High_r_ratematrix[2,2]`[iteration]
  High_r_Qmatrix[2,3] <- data_r$`High_r_ratematrix[2,3]`[iteration]
  High_r_Qmatrix[2,4] <- data_r$`High_r_ratematrix[2,4]`[iteration]
  
  High_r_Qmatrix[3,1] <- data_r$`High_r_ratematrix[3,1]`[iteration]
  High_r_Qmatrix[3,2] <- data_r$`High_r_ratematrix[3,2]`[iteration]
  High_r_Qmatrix[3,3] <- data_r$`High_r_ratematrix[3,3]`[iteration]
  High_r_Qmatrix[3,4] <- data_r$`High_r_ratematrix[3,4]`[iteration]
  
  High_r_Qmatrix[4,1] <- data_r$`High_r_ratematrix[4,1]`[iteration]
  High_r_Qmatrix[4,2] <- data_r$`High_r_ratematrix[4,2]`[iteration]
  High_r_Qmatrix[4,3] <- data_r$`High_r_ratematrix[4,3]`[iteration]
  High_r_Qmatrix[4,4] <- data_r$`High_r_ratematrix[4,4]`[iteration]
  
  # NOTE: MIGHT NEED TO TAKE INTO ACCOUNT ROUNDING ARTEFACTS THAT MEAN IT DOESN'T QUITE SUM TO ZERO IN EACH ROW OF THE RATEMATRIX
  
  # Calculate the stationary distributions predicted at this iteration, and enter it into the table:
  Low_r_StationaryDistributionResults[iteration,1:4] <- get_stationary_distribution(Low_r_Qmatrix)
  High_r_StationaryDistributionResults[iteration,1:4] <- get_stationary_distribution(High_r_Qmatrix)
  
}

# Convert stationary distribution results to a dataframe to enable easy plotting:
Low_r_Results <- as.data.frame(Low_r_StationaryDistributionResults)
High_r_Results <- as.data.frame(High_r_StationaryDistributionResults)

# Reshape the dataframes so that it is suitable for ggplot:
library(reshape2)
Low_r_Results$relatedness = "Low"
dat1 <- melt(Low_r_Results, id.vars=5)
High_r_Results$relatedness = "High"
dat2 <- melt(High_r_Results, id.vars=5)
combined <- rbind(dat1, dat2)

# Plotting 95% prediction intervals:

      # To do this, I think we should use the quantile function? So we would have 95% quantiles, which 
      # would be from quantile 2.5 to quantile 97.5? Here is my attempt at that:
      my_PP_quantiles_r <- as.data.frame(unique(cbind(combined$relatedness, combined$variable)))
      colnames(my_PP_quantiles_r) <- c("relatedness","variable")
      my_PP_quantiles_r$name <- paste(my_PP_quantiles_r$relatedness, my_PP_quantiles_r$variable)
      
      # The 'V' seems to vanish from the variable names. Add it back in:
      my_PP_quantiles_r$variable <- sub("^", "V", my_PP_quantiles_r$variable)
      
      # Set up empty columns:
      my_PP_quantiles_r$upper <- NA
      my_PP_quantiles_r$lower <- NA
      my_PP_quantiles_r$mean <- NA

      for (i in 1: dim(my_PP_quantiles_r)[1]){
        this_r <- my_PP_quantiles_r[i,1]
        this_variable <- my_PP_quantiles_r[i,2]
        x <- subset(combined, relatedness == this_r & variable == this_variable)$value
        my_PP_quantiles_r[i,"upper"] <- quantile(x, .975, type=1)
        my_PP_quantiles_r[i,"lower"] <- quantile(x, .255, type=1)
        my_PP_quantiles_r[i,"mean"] <- mean(x)
      }
    
      # Reorder rows alphabetically so that each country's V1s are next to each other, etc.:
      my_PP_quantiles_r <- my_PP_quantiles_r[order(my_PP_quantiles_r$variable),]
      # Lock in the order using the 'factor' command, so that it is plotted accordingly:
      my_PP_quantiles_r$name <- factor(my_PP_quantiles_r$name, levels = my_PP_quantiles_r$name)
      
      # Now plot the caterpillar plot:
      library(scales)
      library(ggplot2)
      my_color_variable <- my_PP_quantiles_r$relatedness
      ggplot() +
        geom_segment(data = my_PP_quantiles_r, 
                     aes(x = my_PP_quantiles_r$upper, 
                         y = my_PP_quantiles_r$name, 
                         xend = my_PP_quantiles_r$lower,  
                         yend = my_PP_quantiles_r$name,
                         color = my_PP_quantiles_r$relatedness
                         ),
                     size = 0.5) +
        theme_classic() +
        geom_segment(data = my_PP_quantiles_r, 
                     aes(x = my_PP_quantiles_r$mean-0.002, # using this 'segment' to highlight the mean
                         y = my_PP_quantiles_r$name, 
                         xend = my_PP_quantiles_r$mean+0.002, # using this 'segment' to highlight the mean
                         yend = my_PP_quantiles_r$name), 
                     size = 2) +
        scale_x_continuous(expand = c(0,0)) +
        scale_color_manual(values=c("Low"="grey", "High"="black")) +
        theme_classic() + 
        theme(legend.position="none") + 
        theme(text = element_text(size=12)) +
        scale_y_discrete(labels = c('1','1',  '2','2',  '3','3',  '4','4')) +
        labs(y= "Game state", 
             x = "Posterior predictive probability")
 



























# ---------------------------------------------------
# MAKE A MARKOV TRANSITIONS DIAGRAM:

# Plotting circles (following https://finnstats.com/index.php/2022/04/20/how-to-add-circles-in-plots-in-r/):
library(plotrix)
df <- data.frame(x=c(0, 1, 0, 1),y=c(0, 0, 1, 1))
plot(df$x, df$y, xlim = c(-0.5,1.5), ylim = c(0, 1.6), col = "white", asp = 1)

# NOTE: FOR NOW, I WILL SCALE THE CIRCLES USING THE RADIUS. BUT WE SHOULD PROBABLY
# FIGURE OUT HOW TO SCALE THEM BY THE AREA.

my_constant = 0.4

# Add in the transition arrows:
library(shape)

# Arrow between states 1 and 2:
Arrows(x0 = 0.4,y0 = 1.1,
       x1 = 0.7,y1 = 1.1,
       lwd = 2, arr.type = "triangle", col = "lightblue")

# Add the state 1 posterior probability circle:
draw.circle(x=0, y=1, radius=my_constant*mean(SouthAfricaResults$V1), col = "lightblue", border = "black")

# Arrow between states 2 and 1:
Arrows(x0 = 0.8,y0 = 0.9,
       x1 = 0.5,y1 = 0.9,
       lwd = 2, arr.type = "triangle", col = "pink")

# Add the state 2 posterior probability:
draw.circle(x=1, y=1, radius=my_constant*mean(SouthAfricaResults$V2), col = "pink", border = "black")

# Arrow etween states 1 and 3:
Arrows(x0 = -0.1,y0 = 0.7,
       x1 = -0.1,y1 = 0.3,
       lwd = 0.1, arr.type = "triangle", arr.length = 0.3)
Arrows(x0 = 0.1,y0 = 0.2,
       x1 = 0.1,y1 = 0.5,
       lwd = 0.1, arr.type = "triangle",
       arr.length = 0.3)

# Add the state 3 posterior probability:
draw.circle(x=0, y=0, radius=my_constant*mean(SouthAfricaResults$V3), col = "orange", border = "black")

# Add the state 4 posterior probability:
draw.circle(x=1, y=0, radius=my_constant*mean(SouthAfricaResults$V4), col = "grey", border = "black")

text(0, 1.4, "Home")
text(1, 1.4, "Prize")

