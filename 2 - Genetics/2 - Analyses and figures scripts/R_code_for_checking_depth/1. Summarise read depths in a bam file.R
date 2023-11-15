# Patrick

# ----------------------------------
# VISUALISING DEPTH DATA FOLLOWING samtools depth
# (following https://github.com/nt246/lcwgs-guide-tutorial/blob/main/tutorial1_data_processing/markdowns/data_processing.md)

library(tidyverse)

# LOOP THROUGH ALL DEPTH_RECORD FILES IN A FOLDER (FOR MANY WASPS):

setwd("/Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments/Depth_records/Depth_records")

out.file <- 'means.txt'
for (i in list.files()){
    depth <- read_tsv(i, col_names = F)$X1
    write(paste0(i, ",", mean(depth)), out.file, append=TRUE)
}









# IF LOOKING AT JUST ONE FILE:
# Set working directory to the current wasp's FolderForAlignments folder:
setwd("/Volumes/Patricks_LaCie_Genomics_Harddrive/Completed_HPC_alignments/Depth_records/Depth_records")
  # Compute depth stats
  depth <- read_tsv("BCBIW92_S4_CKDL220030021-1A_HK7J7DSX5.no.overlaps.bam.depth.gz", col_names = F)$X1
  mean_depth <- mean(depth)
  sd_depth <- sd(depth)
  mean_depth_nonzero <- mean(depth[depth > 0])
  mean_depth_within2sd <- mean(depth[depth < mean_depth + 2 * sd_depth])
  median <- median(depth)
  presence <- as.logical(depth)
  proportion_of_reference_covered <- mean(presence)
  output_temp <- tibble(1, mean_depth, sd_depth, mean_depth_nonzero, mean_depth_within2sd, median, proportion_of_reference_covered)
  
# Plot the depth distribution (this may take a few minutes to run)
tibble(total_depth = depth, position = 1:length(depth))  %>%
  ggplot(aes(x = position, y = total_depth)) +
  geom_point(size = 0.1)

# That seems to crash RStudio, so you can look at a section of the genome instead:
start=100000
end=200000
tibble(total_depth = depth[start:end], position = start:end)  %>%
  ggplot(aes(x = position, y = total_depth)) +
  geom_point(size = 0.1)




