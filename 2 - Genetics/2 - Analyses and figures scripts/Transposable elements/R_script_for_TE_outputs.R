# PK
# R SCRIPT FOR PROCESSING TE OUTPUTS
# This script is for processing and plotting the outputs of the TE script ('Array_job_Singularity_shell_for_dnaPipeTE_on_HPC.sh'), once the compressed output folder has been downloaded to the local computer and unzipped.

# The outputs should now be available on the local computer (/Users/pk14885/Downloads/Completed_TE_outputs).

# Load libraries:
library(stringr)
library(ggtern)

# Set R working directory to the downloaded 'Completed_TE_outputs' folder:
setwd("~/Downloads/Completed_TE_outputs")

# Obtain list of each wasp:
filenames = dir()

# Create a dataframe to store the results, where each row will be a separate wasp, and the columns are the proportions of the genome represented by each type of component:

mat = matrix(ncol = 9, nrow = length(filenames)); TE_results_table=data.frame(mat) 
  
# check for the dimensions of data  
# frame 
print("Dimensions of data frame") 
dim(TE_results_table)

# LOOP THROUGH EACH WASP'S OUTPUT, AND EXTRACT THE GENOMIC PROPORTIONS:

for (wasp in 1:length(filenames)){

              # Extract name of wasp from folder title:
              this_wasp_name <- str_sub(filenames[[wasp]], 8)

              # Extract this wasp's data from the 'dfg' output file:
              this_wasp_data <- read.delim(paste("~/Downloads/Completed_TE_outputs/", 
                                                 filenames[[wasp]], 
                                                 "/dnaPT_utils_outputs_", 
                                                 this_wasp_name, 
                                                 "_dfg.txt", 
                                                 sep=""), 
                                           header=FALSE)
              
              # If this is the first wasp, use it to set the column headings:
              if (wasp == 1){ 
                colnames(TE_results_table) <- c("Sequencing_machine_sample_name",this_wasp_data$V1)
                colnames(TE_results_table)[[9]] <- "Non-repetitive"}
              
              # The second column of this_wasp_data contains the relevant proportions. Extract and add to the master spreadsheet:
              TE_results_table[wasp,2:9] <- this_wasp_data$V2
              TE_results_table[wasp,1] <- this_wasp_name
  }

# View the resulting dataset:
View(TE_results_table)

# Export the resulting dataset as 'TE_results_table':
write.table(TE_results_table, file = "TE_results_table.csv", sep = ",", col.names = NA,
            qmethod = "double")

# (The outputted table can be found in the Supplementary Material, under 'SUPMAT - TE_results_table'.)

# ----------------------------------------------------------------------------
# PLOTTING TERNARY PLOT:

# Import the 'lcWGS_sequences_table' (available in the SUPMAT Excel file) and view it:
View(lcWGS_sequences_table)

# Since some wasps were sequenced twice, these individuals have a 'main sample' and a 'backup sample'. To avoid double-counting, we need to make sure there is only one row for each individual wasp. Therefore, we will focus only on the main samples in this analysis/plot:
main_samples_only <- subset(lcWGS_sequences_table,lcWGS_sequences_table$`Main sample or backup`=="Main sample")

# Add WaspIDs to the TE_results_table:
dataset_for_plotting <- merge(main_samples_only, TE_results_table,  by="Sequencing_machine_sample_name")

# LTR retrotransposons dominate the repetitive element of the Belonogaster genome. We will therefore use the following vertices for the ternary plot:
# (1) LTR retrotransposons
# (2) Non-LTR and unknown repetitive elements
# (3) Non-repetitive genome

# The values for (1) and (3) are already available in the dataset_for_plotting. 

cols_to_sum=c("DNA", "Low_complexity", "MITE", "repeats_under_0.001%", "Simple_repeat","Unknown")
dataset_for_plotting$"Non-LTR and unknown repetitive elements"<-rowSums(dataset_for_plotting[,cols_to_sum])

# To confirm that this has worked, the three vertices should sum to 100:
cols_to_sum_2=c("LTR", "Non-repetitive", "Non-LTR and unknown repetitive elements")
dataset_for_plotting$"Sum_up"<-rowSums(dataset_for_plotting[,cols_to_sum_2])

# Shuffle the order of the wasps in dataset_for_plotting, so that they don't come in overlapping blocks on the ternary plot:
shuffled_rows_dataset_for_plotting <- dataset_for_plotting[sample(1:nrow(dataset_for_plotting)), ]

x  <- data.frame(
  x1 = shuffled_rows_dataset_for_plotting$LTR,
  x2 = shuffled_rows_dataset_for_plotting$"Non-repetitive",
  x3 = shuffled_rows_dataset_for_plotting$"Non-LTR and unknown repetitive elements",
  x4 = shuffled_rows_dataset_for_plotting$"Climate"
)

ggtern(data=x,aes(x2,x1,x3)) + 
    geom_mask() +
    geom_point(aes(fill=x4),colour="black",shape=21,size=1.5,alpha=1,stroke =0.2) + 
    scale_fill_manual(values=c("#56ddc5","orange","red","grey")) +
    theme_void() +
    theme_clockwise() + Tlab("Non-LTR") + Llab("Single") + Rlab("LTR") +  
theme(legend.position="none", axis.text = element_text(size = 10),axis.title = element_text(size = 10))
