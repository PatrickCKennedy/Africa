# In the previous script ('1_Population_SFS_on_HPC.sh'), you ran the ANGSD step. It is convenient to conduct the next step (realSFS)
# on the local computer, so download the smallFolded file from BluePebble and run realSFS on the local computer using the steps below.

# ------------------------------------------------
# SITE FREQUENCY SPECTRUM TO STAIRWAY PLOT
 
    # EM-optimisation with 4 threads (I have added the '-fold 1' option because the description (http://www.popgen.dk/angsd/index.php/SFS_Estimation) suggests it should be there):
    realSFS smallFolded.saf.idx -maxIter 100 -P 4 -fold 1 > ${this_FOLDER_NAME}.smallFolded.sfs
    
    # Now run the following in R to plot the site frequency spectrum:
            # library(ggplot2)
            # sfs<-scan("smallFolded.sfs") # Import the data to R.
            # barplot(sfs[-1]) # The base-R barplot, following http://www.popgen.dk/angsd/index.php/SFS_Estimation
            ## P: My ggplot version:
            # new<-as.data.frame(sfs)
            # new <- as.data.frame(new[-1,])
            # my_y_variable <- new$`new[-1, ]`
            # myCameroonColour <- "#56ddc5"
            # mySouthAfricaColour <- "red"
            # ggplot(data = new, aes(x=as.numeric(row.names(new)), y=my_y_variable/sum(my_y_variable))) + geom_bar(stat="identity", fill = myCameroonColour) +  theme_classic(base_size = 12) +   theme(text = element_text(size=20)) +
            #   labs(y= "Proportion of SNPs",
            #        x = "Frequency in population") +
            #   theme(legend.position="none") +
            #   theme(aspect.ratio = 1.5) +
            #   theme(axis.line.x.bottom=element_line(size=0.5)) +
            #   theme(axis.line.y.left=element_line(size=0.5)) +
            #   theme(axis.text.x = element_text(color = "black", size = 12, angle = 0, hjust = .5, vjust = .5, face = "plain"),
            #         axis.text.y = element_text(color = "black", size = 12, angle = 0, hjust = 1, vjust = 0, face = "plain"),
            #         axis.title.x = element_text(color = "black", size = 12, angle = 0, hjust = .5, vjust = 0, face = "plain"),
            #         axis.title.y = element_text(color = "black", size = 12, angle = 90, hjust = .5, vjust = .5, face = "plain"))+ scale_x_continuous(breaks=c(1,5,10,15))
                
# ----------------------------------------------------------------------------------------------
# GENERATE A STAIRWAY PLOT FOR THIS POPULATION'S HISTORY:

# Having generated the folded SFS above, you can now use it to reconstruct population size history using the JAVA programme 'stairway_plot_v2.1.1'.

# To do so, you need to manually prepare the input file for 'stairway_plot_v2.1.1'. The input file is known as a 'blueprint'. It's a text file that lists all the parameters and details specific for this population, including the SFS.

# HAVING GENERATED THE SITE-FREQUENCY SPECTRUM, YOU CAN NOW USE IT TO RECONSTRUCT POPULATION SIZE HISTORY USING THE JAVA PROGRAMME stairway_plot_v2.1.1

# To do so, we first need to generate what 'stairway_plot_v2.1.1' calls a 'blueprint file' - a text file that lists all the parameters and details for this population, including the SFS. To run the programme, you then just run one command on this blueprint file. The guide is on the laptop here: /Users/pk14885/stairway_plot_v2.1.1/READMEv2.1.pdf

# To see what the blueprint file looks like, navigate to /Users/pk14885/stairway_plot_v2.1.1 and open their example file (two-epoch_fold.blueprint) using Xcode.

# ------------------------------------------------------------------------------
# BLUEPRINT FILE FOR STAIRWAYPLOT2:

# In the text file produced below, the variables are the following (as defined in the stairway_plot_v2.1.1 readme PDF):
# 'popid': the name of the population
# 'nseq': number of sequences or haploids with which you created your SFS. For n diploid individuals, nseq=2n
# 'L': total number of observed nucleic sites, including polymorphic and monomorphic. (P: I think this is just the sum of all the sites in the SFS file, including the first one, which is, I'm pretty sure, the zero column. Yes! That seems to be right! I've just tested it with Soa: I added up all the values in the output SFS file, and they equal 294337678, which is the same as the number of sites given in the SLURM output file for that population under 'Number of sites retained after filtering' [part of the ANGSD command output]. So, that means that to calculate 'L', we just need to find a way of adding up all the values in the ${this_FOLDER_NAME}.smallFolded.sfs file that is produced above. And that should give us 'L'! For the SFS, which we also need to pass to the blueprint file, I think it is everything in the SFS file apart from the first entry, which is for the 'zeroes' (i.e., alleles that are identical to the reference genome, which is stand-in you have to use for the 'ancestral' genome).)
    # P: Here's my attempt to calculate 'L' from the SFS output:
    numbers=$(cat ${this_FOLDER_NAME}.smallFolded.sfs)
    echo $numbers > test1
    myL_unrounded=$(sed 's/ /+/g' test1 | bc)
    # Hmm, when I do that I get a sum of 294337677.995793, which clearly rounds up to the true value of 294337678. So presumably I need to introduce a rounding-up step? So far, I've only managed to round down (https://unix.stackexchange.com/questions/89712/how-to-convert-floating-point-number-to-integer), but that might be fine, as it would only lose one of the 300 million or so sites:
    myL_rounded=${myL_unrounded%.*}
# 'whether_folded': whether the SFS is folded (true or false)
# 'pct_training': percentage of sites for training
# 'SFS': snp frequency spectrum: number of singleton, number of doubleton, etc. (separated by white space)
    # P: To extract the SFS, we need to get rid of the first number in the ${this_FOLDER_NAME}.smallFolded.sfs file (or its duplicate, 'test1'), which is for the zero-entry sites:
    mySFS=$(sed 's/[^ ]* //' test1)
# 'nrand': number of random break points for each try (separated by white space). We suggest to use 4 numbers, roughly (nseq-2)/4, (nseq-2)/2, (nseq-2)*3/4, nseq-2. The range of the numbers is between 1 and nseq-2. The smaller the number, the more likely the estimation may underfit the training data. The larger the number, the more likely the estimation may overfit the training data. Stairway plot will pick the best number (among the numbers specified here) to control overfitting based on the remaining 1-pct_training sites used as testing data.
# 'project_dir': project directory
# 'stairway_plot_dir': directory to the stairway plot files
# 'ninput': number of input files to be created for each estimation
# 'mu': assumed mutation rate per site per generation
# 'year_per_generation': assumed generation time (in years) (P: Change this depending on whether you are using South Africa (1) or Cameroon (I estimate as 0.583, i.e. 7/12)

# Now produce the 'blueprint' text file:
echo "
popid: ${this_FOLDER_NAME}
nseq: $(($file_count*2))
L: ${myL_rounded}
whether_folded: true
SFS:  ${mySFS}
pct_training: 0.67
nrand: $(($(($(($(($file_count*2))-2))/5)))) $(($(($(($(($file_count*2))-2))/2)))) $(($(($(($(($file_count*2))-2))*3/4)))) $(($(($file_count*2))-2))
project_dir: ${this_FOLDER_NAME}
stairway_plot_dir: stairway_plot_es
ninput: 200
mu: 3.6e-09
year_per_generation: 0.583
# Settings for the resulting plot:
plot_title: ${this_FOLDER_NAME} # title of the plot
xrange: 0,0 # Time (1k year) range; format: xmin,xmax; "0,0" for default
yrange: 0,0 # Ne (1k individual) range; format: xmin,xmax; "0,0" for default
xspacing: 2 # X axis spacing
yspacing: 2 # Y axis spacing
fontsize: 12 # Font size
" > ${this_FOLDER_NAME}.blueprint
                
# TO BE CONTINUED. KEEP WORKING THROUGH THAT PDF README FILE

# ------------------------------------------------------------------------------
# NOW RUN STAIRWAYPLOT2:

# To run StairwayPlot2: "The simplest way to run stairway plot is use Stairbuilder.class to create a batch file and then run the batch file. First, create a blueprint file and copy it to the folder which contains the stairway_plot_es (say the folder name is stairway_plot_v2.1). Then, in the commandline environment, change directory to stairway_plot_v2.1 and run this command: java -cp stairway_plot_es Stairbuilder blueprint_file"

mv ${this_FOLDER_NAME}.blueprint /user/work/pk14885/stairway_plot_v2.1.1/
cd /user/work/pk14885/stairway_plot_v2.1.1
java -cp stairway_plot_es Stairbuilder ${this_FOLDER_NAME}.blueprint




# The output plots produced by StairwayPlot2 are not great, but you can replot them in ggplot2, which is what this paper (https://onlinelibrary.wiley.com/doi/epdf/10.1111/mec.16951) does. Here's the code they used: https://github.com/sallycylau/ophionotus_ddRADcapture/blob/master/08.Analyse_stairwayplot.md That paper looks quite good.

# ---------------------------------------------------------------
# POPULATION GENETICS QUESTIONS

# This pipeline might be useful: https://github.com/clairemerot/angsd_pipeline

